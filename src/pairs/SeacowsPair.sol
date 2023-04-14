// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { ERC1155Receiver } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { OwnableWithTransferCallback } from "../lib/OwnableWithTransferCallback.sol";
import { ReentrancyGuard } from "../lib/ReentrancyGuard.sol";
import { ICurve } from "../bondingcurve/ICurve.sol";
import { ISeacowsPairFactoryLike } from "../interfaces/ISeacowsPairFactoryLike.sol";
import { CurveErrorCodes } from "../bondingcurve/CurveErrorCodes.sol";
import { SeacowsCollectionRegistry } from "../priceoracle/SeacowsCollectionRegistry.sol";
import { IWETH } from "../interfaces/IWETH.sol";
import { ISeacowsRouter } from "../interfaces/ISeacowsRouter.sol";

/// @title The base contract for an NFT/TOKEN AMM pair
/// Inspired by 0xmons; Modified from https://github.com/sudoswap/lssvm
/// @notice This implements the core swap logic from NFT to TOKEN
abstract contract SeacowsPair is OwnableWithTransferCallback, ReentrancyGuard, ERC1155Holder {
    using SafeERC20 for ERC20;

    uint256 public constant MASK = type(uint112).min;

    enum PoolType {
        TOKEN,
        NFT
    }

    struct PairInitializeParams {
        ISeacowsPairFactoryLike factory;
        ICurve bondingCurve;
        address nft;
        PoolType poolType;
        IERC20 token;
        address owner;
        address payable assetRecipient;
        uint128 delta;
        uint96 fee;
        uint128 spotPrice;
        address weth;
    }

    ISeacowsPairFactoryLike public factory;

    ICurve public bondingCurve;

    address public nft;

    PoolType public poolType;

    IERC20 public token;

    // The current price of the NFT
    // @dev This is generally used to mean the immediate sell price for the next marginal NFT.
    // However, this should NOT be assumed, as future bonding curves may use spotPrice in different ways.
    // Use getBuyNFTQuote and getSellNFTQuote for accurate pricing info.
    uint128 public spotPrice;

    // The parameter for the pair's bonding curve.
    // Units and meaning are bonding curve dependent.
    uint128 public delta;

    // The spread between buy and sell prices, set to be a multiplier we apply to the buy price
    // Fee is only relevant for TRADE pools
    // Units are in base 1e18
    uint96 public fee;

    // If set to 0, NFTs/tokens sent by traders during trades will be sent to the pair.
    // Otherwise, assets will be sent to the set address. Not available for TRADE pools.
    address payable public assetRecipient;

    // If true, protocol fee is disabled. otherwise it's disabled
    bool public isProtocolFeeDisabled;

    address public weth;

    uint112 internal nftReserve; // uses single storage slot, accessible via getReserves, for nft
    uint112 internal tokenReserve; // uses single storage slot, accessible via getReserves for token
    uint32 internal blockTimestampLast; // uses single storage slot, accessible via getReserves

    // Events
    event SpotPriceUpdate(uint128 oldSpotPrice, uint128 newSpotPrice);
    event TokenWithdrawal(address indexed recipient, uint256 amount);
    event TokenDeposit(address indexed sender, uint256 amount);
    event DeltaUpdate(uint128 oldDelta, uint128 newDelta);
    event FeeUpdate(uint96 oldFee, uint96 newFee);
    event AssetRecipientChange(address oldRecipient, address newRecipient);
    event Sync(uint112 reserve0, uint112 reserve1);

    // Parameterized Errors
    error BondingCurveError(CurveErrorCodes.Error error);

    constructor() {}

    /**
      @notice Called during pair creation to set initial parameters
      @dev Only called once by factory to initialize.
      We verify this by making sure that the current owner is address(0). 
      The Ownable library we use disallows setting the owner to be address(0), so this condition
      should only be valid before the first initialize call. 
      @param param PairInitializeParams param
     */
    function initialize(PairInitializeParams calldata param) external payable {
        require(owner() == address(0), "Initialized");
        __Ownable_init(param.owner);
        __ReentrancyGuard_init();

        bondingCurve = param.bondingCurve;
        factory = param.factory;
        nft = param.nft;
        poolType = param.poolType;
        token = param.token;
        delta = param.delta;
        spotPrice = param.spotPrice;
        weth = param.weth;

        if ((param.poolType == PoolType.TOKEN) || (param.poolType == PoolType.NFT)) {
            require(param.fee == 0, "Only Trade Pools can have nonzero fee");
            if (param.assetRecipient != address(0)) {
                assetRecipient = param.assetRecipient;
            } else {
                assetRecipient = payable(param.owner);
            }
        }

        require(bondingCurve.validateDelta(param.delta), "Invalid delta for curve");
        require(bondingCurve.validateSpotPrice(param.spotPrice), "Invalid new spot price for curve");
    }

    // -----------------------------------------
    // SeacowsPair Modifiers
    // -----------------------------------------

    modifier onlyFactory() {
        require(msg.sender == address(factory), "Caller is not a factory");
        _;
    }

    modifier onlyWithdrawable() {
        // For NFT, TOKEN pairs, only owner can call this function
        require(msg.sender == owner(), "Caller should be an owner");
        _;
    }

    /**
     * External state-changing functions
     */

    /**
     * @dev withraw erc20 tokens from pair to recipient
     * @param _recipient The address for token withdarw
     * @param _amount The amount of token to withdraw
     */
    function withdrawERC20(address _recipient, uint256 _amount) external virtual onlyWithdrawable {
        require(_recipient != address(0), "Invalid address");
        require(_amount > 0, "Invalid amount");

        token.transfer(_recipient, _amount);

        // emit event since it is the pair token
        emit TokenWithdrawal(_recipient, _amount);
    }

    /**
     * View functions
     */

    /**
        @notice Returns the pair's variant (NFT is enumerable or not, pair uses ETH or ERC20)
     */
    function pairVariant() public pure virtual returns (ISeacowsPairFactoryLike.PairVariant);

    /**
        @notice Returns the address that assets that receives assets when a swap is done with this pair
        Can be set to another address by the owner, if set to address(0), defaults to the pair's own address
     */
    function getAssetRecipient() public view returns (address payable _assetRecipient) {
        // Otherwise, we return the recipient if it's been set
        // or replace it with address(this) if it's 0
        _assetRecipient = assetRecipient;
        if (_assetRecipient == address(0)) {
            // Tokens will be transferred to address(this)
            _assetRecipient = payable(address(this));
        }
    }

    function getReserves() public view returns (uint112 _nftReserve, uint112 _tokenReserve, uint32 _blockTimestampLast) {
        _nftReserve = nftReserve;
        _tokenReserve = tokenReserve;
        _blockTimestampLast = blockTimestampLast;
    }

    /**
     * Internal functions
     */

    function _updateSpotPrice(
        CurveErrorCodes.Error error,
        uint256 outputAmount,
        uint256 minExpectedTokenOutput,
        uint128 currentDelta,
        uint128 newDelta,
        uint128 currentSpotPrice,
        uint128 newSpotPrice
    ) internal {
        // Revert if bonding curve had an error
        if (error != CurveErrorCodes.Error.OK) {
            revert BondingCurveError(error);
        }

        // Revert if output is too little
        require(outputAmount >= minExpectedTokenOutput, "Out too little tokens");

        // Consolidate writes to save gas
        if (currentSpotPrice != newSpotPrice || currentDelta != newDelta) {
            spotPrice = newSpotPrice;
            delta = newDelta;
        }

        // Emit spot price update if it has been updated
        if (currentSpotPrice != newSpotPrice) {
            emit SpotPriceUpdate(currentSpotPrice, newSpotPrice);
        }

        // Emit delta update if it has been updated
        if (currentDelta != newDelta) {
            emit DeltaUpdate(currentDelta, newDelta);
        }
    }

    /**
        @notice Pulls the token input of a trade from the trader and pays the protocol fee.
        @param inputAmount The amount of tokens to be sent
        @param _factory The SeacowsPairFactory which stores SeacowsRouter allowlist info
        @param protocolFee The protocol fee to be paid
        @param isRouter Whether or not the caller is LSSVMRouter
     */
    function _pullTokenInputAndPayProtocolFee(uint256 inputAmount, ISeacowsPairFactoryLike _factory, uint256 protocolFee, bool isRouter) internal {
        require(msg.value == 0, "ERC20 pair");

        address _assetRecipient = getAssetRecipient();

        if (!isRouter) {
            // Transfer tokens directly
            token.transferFrom(msg.sender, _assetRecipient, inputAmount - protocolFee);

            // Take protocol fee (if it exists)
            if (protocolFee > 0) {
                token.transferFrom(msg.sender, address(_factory), protocolFee);
            }
        }

        // for the routers, we assume they already sent the assets to the pair
    }

    /**
        @notice Sends excess tokens back to the caller (if applicable)
        @dev We send ETH back to the caller even when called from SeacowsRouter because we do an aggregate slippage check for certain bulk swaps. (Instead of sending directly back to the router caller) 
        Excess ETH sent for one swap can then be used to help pay for the next swap.
     */
    function _refundTokenToSender(uint256 inputAmount) internal {
        // Do nothing since we transferred the exact input amount
    }

    /**
        @notice Sends protocol fee (if it exists) back to the SeacowsPairFactory from the pair
     */
    function _payProtocolFeeFromPair(ISeacowsPairFactoryLike _factory, uint256 protocolFee) internal {
        // Take protocol fee (if it exists)
        if (protocolFee > 0) {
            // Round down to the actual token balance if there are numerical stability issues with the bonding curve calculations
            uint256 pairTokenBalance = token.balanceOf(address(this));
            if (protocolFee > pairTokenBalance) {
                protocolFee = pairTokenBalance;
            }
            if (protocolFee > 0) {
                token.transfer(address(_factory), protocolFee);
            }
        }
    }

    /**
        @notice Sends tokens to a recipient
        @param tokenRecipient The address receiving the tokens
        @param outputAmount The amount of tokens to send
     */
    function _sendTokenOutput(address payable tokenRecipient, uint256 outputAmount) internal {
        // Send tokens to caller
        if (outputAmount > 0) {
            token.transfer(tokenRecipient, outputAmount);
        }
        // we update reserves accordingly
        _syncReserve();
    }

    // update reserves and, on the first call per block, price accumulators
    function _updateReserve(uint256 _nftReserve, uint256 _tokenReserve) private {
        require(_nftReserve <= MASK && _tokenReserve <= MASK, "OVERFLOW");

        nftReserve = uint112(_nftReserve);
        tokenReserve = uint112(_tokenReserve);
        blockTimestampLast = uint32(block.timestamp % 2**32);

        emit Sync(nftReserve, tokenReserve);
    }

    // update reserves and, on the first call per block, price accumulators
    function _syncReserve() private {
        // we update reserves accordingly
        uint256 _nftBalance = IERC721(nft).balanceOf(address(this));
        uint256 _tokenBalance = token.balanceOf(address(this));

        _updateReserve(_nftBalance, _tokenBalance);
    }

    /**
     * Admin functions
     */

    /**
        @notice Updates the selling spot price. Only callable by the owner.
        @param newSpotPrice The new selling spot price value, in Token
     */
    function changeSpotPrice(uint128 newSpotPrice) external onlyOwner {
        require(bondingCurve.validateSpotPrice(newSpotPrice), "Invalid new spot price for curve");
        if (spotPrice != newSpotPrice) {
            emit SpotPriceUpdate(spotPrice, newSpotPrice);
            spotPrice = newSpotPrice;
        }
    }

    /**
        @notice Updates the delta parameter. Only callable by the owner.
        @param newDelta The new delta parameter
     */
    function changeDelta(uint128 newDelta) external onlyOwner {
        require(bondingCurve.validateDelta(newDelta), "Invalid delta for curve");
        if (delta != newDelta) {
            emit DeltaUpdate(delta, newDelta);
            delta = newDelta;
        }
    }

    /**
        @notice Changes the address that will receive assets received from
        trades. Only callable by the owner.
        @param newRecipient The new asset recipient
     */
    function changeAssetRecipient(address payable newRecipient) external onlyOwner {
        require(newRecipient != address(0), "Invalid address");

        if (assetRecipient != newRecipient) {
            emit AssetRecipientChange(assetRecipient, newRecipient);
            assetRecipient = newRecipient;
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155Receiver) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // -----------------------------------------
    // OnlyFactory functions
    // -----------------------------------------
    /**
     * @dev enable or disable protocol fee for the pair
     * @param _isProtocolFeeDisabled The boolean value to represent whether enable or dsiable protocol fee
     */
    function disableProtocolFee(bool _isProtocolFeeDisabled) external onlyFactory {
        isProtocolFeeDisabled = _isProtocolFeeDisabled;
    }

    /**
     * Liquidity functions
     */

    /**
      @dev Used to deposit ERC20s into a pair after creation and emit an event for indexing 
      (if recipient is indeed an ERC20 pair and the token matches)
     */
    function depositERC20(uint256 amount) external {
        token.transferFrom(msg.sender, address(this), amount);

        require(poolType == PoolType.TOKEN, "Not a token pair");
        require(owner() == msg.sender, "Not a pair owner");

        // we update reserves accordingly
        _syncReserve();

        emit TokenDeposit(msg.sender, amount);
    }

    /**
      @dev Used to deposit ETH into a pair after creation and emit an event for indexing 
      (if recipient is indeed an ETH pair and the token matches)
     */
    function depositETH() external payable {
        IWETH(weth).deposit{ value: msg.value }();

        require(poolType == PoolType.TOKEN, "Not a token pair");
        require(owner() == msg.sender, "Not a pair owner");

        // we update reserves accordingly
        _syncReserve();

        emit TokenDeposit(msg.sender, msg.value);
    }
}
