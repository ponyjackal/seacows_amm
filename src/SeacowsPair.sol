// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { ERC1155Receiver } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import { OwnableWithTransferCallback } from "./lib/OwnableWithTransferCallback.sol";
import { ReentrancyGuard } from "./lib/ReentrancyGuard.sol";
import { ICurve } from "./bondingcurve/ICurve.sol";
import { ISeacowsPairFactoryLike } from "./interfaces/ISeacowsPairFactoryLike.sol";
import { CurveErrorCodes } from "./bondingcurve/CurveErrorCodes.sol";
import { SeacowsCollectionRegistry } from "./priceoracle/SeacowsCollectionRegistry.sol";

/// @title The base contract for an NFT/TOKEN AMM pair
/// Inspired by 0xmons; Modified from https://github.com/sudoswap/lssvm
/// @notice This implements the core swap logic from NFT to TOKEN
abstract contract SeacowsPair is OwnableWithTransferCallback, ReentrancyGuard, ERC1155Holder {
    using SafeERC20 for ERC20;

    enum PoolType {
        TOKEN,
        NFT,
        TRADE
    }

    // 90%, must <= 1 - MAX_PROTOCOL_FEE (set in PairFactory)
    uint256 internal constant MAX_FEE = 0.90e18;

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

    // Events
    event SwapNFTInPair();
    event SwapNFTOutPair();
    event SpotPriceUpdate(uint128 newSpotPrice);
    event TokenWithdrawal(address indexed recipient, uint256 amount);
    event DeltaUpdate(uint128 newDelta);
    event FeeUpdate(uint96 newFee);
    event AssetRecipientChange(address a);

    // Parameterized Errors
    error BondingCurveError(CurveErrorCodes.Error error);

    constructor() {}

    /**
      @notice Called during pair creation to set initial parameters
      @dev Only called once by factory to initialize.
      We verify this by making sure that the current owner is address(0). 
      The Ownable library we use disallows setting the owner to be address(0), so this condition
      should only be valid before the first initialize call. 
      @param _owner The owner of the pair
      @param _assetRecipient The address that will receive the TOKEN or NFT sent to this pair during swaps. NOTE: If set to address(0), they will go to the pair itself.
      @param _delta The initial delta of the bonding curve
      @param _fee The initial % fee taken, if this is a trade pair 
      @param _spotPrice The initial price to sell an asset into the pair
     */
    function initialize(address _owner, address payable _assetRecipient, uint128 _delta, uint96 _fee, uint128 _spotPrice) external payable {
        require(owner() == address(0), "Initialized");
        __Ownable_init(_owner);
        __ReentrancyGuard_init();

        ICurve _bondingCurve = bondingCurve();
        PoolType _poolType = poolType();

        if ((_poolType == PoolType.TOKEN) || (_poolType == PoolType.NFT)) {
            require(_fee == 0, "Only Trade Pools can have nonzero fee");
            if (_assetRecipient != address(0)) {
                assetRecipient = _assetRecipient;
            } else {
                assetRecipient = payable(_owner);
            }
        } else if (_poolType == PoolType.TRADE) {
            require(_fee < MAX_FEE, "Trade fee must be less than 90%");
            require(_assetRecipient == address(0), "Trade pools can't set asset recipient");
            fee = _fee;
        }
        require(_bondingCurve.validateDelta(_delta), "Invalid delta for curve");
        require(_bondingCurve.validateSpotPrice(_spotPrice), "Invalid new spot price for curve");
        delta = _delta;
        spotPrice = _spotPrice;
    }

    // -----------------------------------------
    // SeacowsPair Modifiers
    // -----------------------------------------

    modifier onlyFactory() {
        require(msg.sender == address(factory()), "Caller is not a factory");
        _;
    }

    modifier onlyTrade() {
        PoolType _poolType = poolType();
        require(_poolType == PoolType.TRADE, "Not trade pair");
        _;
    }

    modifier onlyWithdrawable() {
        // For NFT, TOKEN pairs, only owner can call this function
        // For TRADE pairs, only factory can call this function
        if (poolType() == PoolType.TRADE) {
            //TODO; if we move liquidity functions to router, this should be updated to router
            require(msg.sender == address(factory()), "Caller should be a factory");
        } else {
            require(msg.sender == owner(), "Caller should be an owner");
        }
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

        token().safeTransfer(_recipient, _amount);

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

    function factory() public pure returns (ISeacowsPairFactoryLike _factory) {
        uint256 paramsLength = _immutableParamsLength();
        assembly {
            _factory := shr(0x60, calldataload(sub(calldatasize(), paramsLength)))
        }
    }

    /**
        @notice Returns the type of bonding curve that parameterizes the pair
     */
    function bondingCurve() public pure returns (ICurve _bondingCurve) {
        uint256 paramsLength = _immutableParamsLength();
        assembly {
            _bondingCurve := shr(0x60, calldataload(add(sub(calldatasize(), paramsLength), 20)))
        }
    }

    /**
        @notice Returns the NFT collection that parameterizes the pair
     */
    function nft() public pure returns (address _nft) {
        uint256 paramsLength = _immutableParamsLength();
        assembly {
            _nft := shr(0x60, calldataload(add(sub(calldatasize(), paramsLength), 40)))
        }
    }

    /**
        @notice Returns the pair's type (TOKEN/NFT/TRADE)
     */
    function poolType() public pure returns (PoolType _poolType) {
        uint256 paramsLength = _immutableParamsLength();
        assembly {
            _poolType := shr(0xf8, calldataload(add(sub(calldatasize(), paramsLength), 60)))
        }
    }

    /**
        @notice Returns the ERC20 token associated with the pair
        @dev See SeacowsPairCloner for an explanation on how this works
     */
    function token() public pure returns (ERC20 _token) {
        uint256 paramsLength = _immutableParamsLength();
        assembly {
            _token := shr(0x60, calldataload(add(sub(calldatasize(), paramsLength), 61)))
        }
    }

    /**
        @notice Returns the address that assets that receives assets when a swap is done with this pair
        Can be set to another address by the owner, if set to address(0), defaults to the pair's own address
     */
    function getAssetRecipient() public view returns (address payable _assetRecipient) {
        // If it's a TRADE pool, we know the recipient is 0 (TRADE pools can't set asset recipients)
        // so just return address(this)
        if (poolType() == PoolType.TRADE) {
            return payable(address(this));
        }

        // Otherwise, we return the recipient if it's been set
        // or replace it with address(this) if it's 0
        _assetRecipient = assetRecipient;
        if (_assetRecipient == address(0)) {
            // Tokens will be transferred to address(this)
            _assetRecipient = payable(address(this));
        }
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
            emit SpotPriceUpdate(newSpotPrice);
        }

        // Emit delta update if it has been updated
        if (currentDelta != newDelta) {
            emit DeltaUpdate(newDelta);
        }
    }

    /**
     * @notice get reserves in the pool, only available for trade pair
     */
    function getReserve() external view virtual returns (uint256 nftReserve, uint256 tokenReserve);

    /**
        @notice Pulls the token input of a trade from the trader and pays the protocol fee.
        @param inputAmount The amount of tokens to be sent
        @param _factory The SeacowsPairFactory which stores SeacowsRouter allowlist info
        @param protocolFee The protocol fee to be paid
     */
    function _pullTokenInputAndPayProtocolFee(uint256 inputAmount, ISeacowsPairFactoryLike _factory, uint256 protocolFee) internal {
        require(msg.value == 0, "ERC20 pair");

        ERC20 _token = token();
        address _assetRecipient = getAssetRecipient();

        // Transfer tokens directly
        _token.transferFrom(msg.sender, _assetRecipient, inputAmount - protocolFee);

        // Take protocol fee (if it exists)
        if (protocolFee > 0) {
            _token.transferFrom(msg.sender, address(_factory), protocolFee);
        }
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
            ERC20 _token = token();

            // Round down to the actual token balance if there are numerical stability issues with the bonding curve calculations
            uint256 pairTokenBalance = _token.balanceOf(address(this));
            if (protocolFee > pairTokenBalance) {
                protocolFee = pairTokenBalance;
            }
            if (protocolFee > 0) {
                _token.safeTransfer(address(_factory), protocolFee);
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
            token().safeTransfer(tokenRecipient, outputAmount);
        }
    }

    /**
        @dev Used internally to grab pair parameters from calldata, see SeacowsPairCloner for technical details
     */
    function _immutableParamsLength() internal pure virtual returns (uint256);

    /**
     * Admin functions
     */

    /**
        @notice Updates the selling spot price. Only callable by the owner.
        @param newSpotPrice The new selling spot price value, in Token
     */
    function changeSpotPrice(uint128 newSpotPrice) external onlyOwner {
        ICurve _bondingCurve = bondingCurve();
        require(_bondingCurve.validateSpotPrice(newSpotPrice), "Invalid new spot price for curve");
        if (spotPrice != newSpotPrice) {
            spotPrice = newSpotPrice;
            emit SpotPriceUpdate(newSpotPrice);
        }
    }

    /**
        @notice Updates the delta parameter. Only callable by the owner.
        @param newDelta The new delta parameter
     */
    function changeDelta(uint128 newDelta) external onlyOwner {
        ICurve _bondingCurve = bondingCurve();
        require(_bondingCurve.validateDelta(newDelta), "Invalid delta for curve");
        if (delta != newDelta) {
            delta = newDelta;
            emit DeltaUpdate(newDelta);
        }
    }

    /**
        @notice Updates the fee taken by the LP. Only callable by the owner.
        Only callable if the pool is a Trade pool. Reverts if the fee is >=
        MAX_FEE.
        @param newFee The new LP fee percentage, 18 decimals
     */
    function changeFee(uint96 newFee) external onlyOwner {
        PoolType _poolType = poolType();
        require(_poolType == PoolType.TRADE, "Only for Trade pools");
        require(newFee < MAX_FEE, "Trade fee must be less than 90%");
        if (fee != newFee) {
            fee = newFee;
            emit FeeUpdate(newFee);
        }
    }

    /**
        @notice Changes the address that will receive assets received from
        trades. Only callable by the owner.
        @param newRecipient The new asset recipient
     */
    function changeAssetRecipient(address payable newRecipient) external onlyOwner {
        PoolType _poolType = poolType();
        require(_poolType != PoolType.TRADE, "Not for Trade pools");
        require(newRecipient != address(0), "Invalid address");

        if (assetRecipient != newRecipient) {
            assetRecipient = newRecipient;
            emit AssetRecipientChange(newRecipient);
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
}
