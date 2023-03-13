// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

// @dev Solmate's ERC20 is used instead of OZ's ERC20 so we can use safeTransferLib for cheaper safeTransfers for
// ETH and ERC20 tokens
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { SeacowsPair } from "./SeacowsPair.sol";
import { SeacowsRouter } from "./SeacowsRouter.sol";
import { ICurve } from "./bondingcurve/ICurve.sol";
import { SeacowsPairCloner } from "./lib/SeacowsPairCloner.sol";
import { SeacowsPairERC721 } from "./SeacowsPairERC721.sol";
import { SeacowsPairERC1155 } from "./SeacowsPairERC1155.sol";

import { IWETH } from "./interfaces/IWETH.sol";
import { ISeacowsPairFactoryLike } from "./interfaces/ISeacowsPairFactoryLike.sol";
import { ISeacowsPair } from "./interfaces/ISeacowsPair.sol";
import { ISeacowsPairERC1155 } from "./interfaces/ISeacowsPairERC1155.sol";

///Inspired by 0xmons; Modified from https://github.com/sudoswap/lssvm
contract SeacowsPairFactory is Ownable, ISeacowsPairFactoryLike {
    using SeacowsPairCloner for address;
    using SafeTransferLib for address payable;
    using SafeERC20 for ERC20;

    bytes4 private constant INTERFACE_ID_ERC721_ENUMERABLE = type(IERC721Enumerable).interfaceId;

    uint256 internal constant MAX_PROTOCOL_FEE = 0.10e18; // 10%, must <= 1 - MAX_FEE

    SeacowsPairERC721 public immutable erc721Template;
    SeacowsPairERC1155 public immutable erc1155Template;
    address payable public override protocolFeeRecipient;
    address public weth;

    // Units are in base 1e18
    uint256 public override protocolFeeMultiplier;

    mapping(ICurve => bool) public bondingCurveAllowed;
    mapping(address => bool) public override callAllowed;
    struct RouterStatus {
        bool allowed;
        bool wasEverAllowed;
    }
    mapping(SeacowsRouter => RouterStatus) public override routerStatus;

    struct CreateERC721ERC20PairParams {
        IERC20 token;
        IERC721 nft;
        ICurve bondingCurve;
        address payable assetRecipient;
        SeacowsPair.PoolType poolType;
        uint128 delta;
        uint96 fee;
        uint128 spotPrice;
        uint256[] initialNFTIDs;
        uint256 initialTokenBalance;
    }

    struct CreateERC1155ERC20PairParams {
        IERC20 token;
        IERC1155 nft;
        ICurve bondingCurve;
        address payable assetRecipient;
        SeacowsPair.PoolType poolType;
        uint128 delta;
        uint96 fee;
        uint128 spotPrice;
        uint256 tokenAmount;
        uint256[] nftIds;
        uint256[] nftAmounts;
    }

    struct CreateERC1155ETHPairParams {
        IERC1155 nft;
        ICurve bondingCurve;
        address payable assetRecipient;
        SeacowsPair.PoolType poolType;
        uint128 delta;
        uint96 fee;
        uint128 spotPrice;
        uint256[] nftIds;
        uint256[] nftAmounts;
    }

    event NewPair(address poolAddress);
    event TokenDeposit(address poolAddress);
    event NFTDeposit(address poolAddress);
    event ProtocolFeeRecipientUpdate(address recipientAddress);
    event ProtocolFeeMultiplierUpdate(uint256 newMultiplier);
    event BondingCurveStatusUpdate(ICurve bondingCurve, bool isAllowed);
    event CallTargetStatusUpdate(address target, bool isAllowed);
    event RouterStatusUpdate(SeacowsRouter router, bool isAllowed);
    event ProtocolFeeDisabled(address pair, bool isDisabled);

    constructor(
        address _weth,
        SeacowsPairERC721 _erc721Template,
        SeacowsPairERC1155 _erc1155Template,
        address payable _protocolFeeRecipient,
        uint256 _protocolFeeMultiplier
    ) {
        weth = _weth;
        erc721Template = _erc721Template;
        erc1155Template = _erc1155Template;
        protocolFeeRecipient = _protocolFeeRecipient;

        require(_protocolFeeMultiplier <= MAX_PROTOCOL_FEE, "Fee too large");
        protocolFeeMultiplier = _protocolFeeMultiplier;
    }

    /**
     * External functions
     */

    /**
        @notice Creates a pair contract using EIP-1167.
        @param _nft The NFT contract of the collection the pair trades
        @param _bondingCurve The bonding curve for the pair to price NFTs, must be whitelisted
        @param _assetRecipient The address that will receive the assets traders give during trades.
                              If set to address(0), assets will be sent to the pool address.
                              Not available to TRADE pools. 
        @param _poolType TOKEN, NFT, or TRADE
        @param _delta The delta value used by the bonding curve. The meaning of delta depends
        on the specific curve.
        @param _fee The fee taken by the LP in each trade. Can only be non-zero if _poolType is Trade.
        @param _spotPrice The initial selling spot price
        @param _initialNFTIDs The list of IDs of NFTs to transfer from the sender to the pair
        @return pair The new pair
     */
    function createPairETH(
        IERC721 _nft,
        ICurve _bondingCurve,
        address payable _assetRecipient,
        SeacowsPair.PoolType _poolType,
        uint128 _delta,
        uint96 _fee,
        uint128 _spotPrice,
        uint256[] calldata _initialNFTIDs
    ) external payable returns (SeacowsPair pair) {
        IWETH(weth).deposit{ value: msg.value }();
        CreateERC721ERC20PairParams memory params = CreateERC721ERC20PairParams(
            IERC20(weth),
            _nft,
            _bondingCurve,
            _assetRecipient,
            _poolType,
            _delta,
            _fee,
            _spotPrice,
            _initialNFTIDs,
            uint256(msg.value)
        );
        pair = _createPairERC721ERC20(params);
        pair.initialize(msg.sender, params.assetRecipient, params.delta, params.fee, params.spotPrice);

        // transfer WETH from this contract to pair
        params.token.transferFrom(address(this), address(pair), params.initialTokenBalance);

        // transfer initial NFTs from sender to pair
        uint256 numNFTs = params.initialNFTIDs.length;
        for (uint256 i; i < numNFTs; ) {
            params.nft.safeTransferFrom(msg.sender, address(pair), params.initialNFTIDs[i]);

            unchecked {
                ++i;
            }
        }
        emit NewPair(address(pair));
    }

    /**
        @notice Creates an erc1155 pair contract using EIP-1167.
        @param params CreateERC1155ETHPairParams params
        @return pair The new pair
     */
    function createPairERC1155ETH(CreateERC1155ETHPairParams calldata params) external payable returns (SeacowsPair pair) {
        IWETH(weth).deposit{ value: msg.value }();
        pair = _createPairERC1155ERC20(IERC20(weth), params.nft, params.bondingCurve, params.poolType, params.nftIds, params.nftAmounts);

        if (params.poolType == SeacowsPair.PoolType.TRADE) {
            // For trade pairs, spot price should be based on the token and nft reserves
            uint128 initSpotPrice = (uint128)(msg.value / ISeacowsPairERC1155(address(pair)).nftAmount());
            _initializePairERC1155ERC20(pair, params.assetRecipient, params.delta, params.fee, initSpotPrice);
        } else {
            _initializePairERC1155ERC20(pair, params.assetRecipient, params.delta, params.fee, params.spotPrice);
        }

        // transfer WETH from this contract to pair
        IERC20(weth).transferFrom(address(this), address(pair), msg.value);

        emit NewPair(address(pair));
    }

    /**
        @notice Creates a pair contract using EIP-1167.
        @param params CreateERC721ERC20PairParams params
        @return pair The new pair
     */
    function createPairERC20(CreateERC721ERC20PairParams calldata params) external returns (SeacowsPair pair) {
        require(bondingCurveAllowed[params.bondingCurve], "Bonding curve not whitelisted");

        pair = _createPairERC721ERC20(params);
        pair.initialize(msg.sender, params.assetRecipient, params.delta, params.fee, params.spotPrice);

        // transfer initial tokens to pair
        params.token.transferFrom(msg.sender, address(pair), params.initialTokenBalance);

        // transfer initial NFTs from sender to pair
        uint256 numNFTs = params.initialNFTIDs.length;
        for (uint256 i; i < numNFTs; ) {
            params.nft.safeTransferFrom(msg.sender, address(pair), params.initialNFTIDs[i]);

            unchecked {
                ++i;
            }
        }
        emit NewPair(address(pair));
    }

    /**
        @notice Creates an erc1155 pair contract using EIP-1167.
        @param params CreateERC1155ERC20PairParams params
        @return pair The new pair
     */
    function createPairERC1155ERC20(CreateERC1155ERC20PairParams calldata params) external payable returns (SeacowsPair pair) {
        pair = _createPairERC1155ERC20(params.token, params.nft, params.bondingCurve, params.poolType, params.nftIds, params.nftAmounts);

        if (params.poolType == SeacowsPair.PoolType.TRADE) {
            // For trade pairs, spot price should be based on the token and nft reserves
            uint128 initSpotPrice = (uint128)(params.tokenAmount / params.nftAmount);
            _initializePairERC1155ERC20(pair, params.assetRecipient, params.delta, params.fee, initSpotPrice);
        } else {
            _initializePairERC1155ERC20(pair, params.assetRecipient, params.delta, params.fee, params.spotPrice);
        }

        // transfer initial tokens to pair
        params.token.transferFrom(msg.sender, address(pair), params.tokenAmount);
        emit NewPair(address(pair));
    }

    /**
        @notice Checks if an address is a SeacowsPair. Uses the fact that the pairs are EIP-1167 minimal proxies.
        @param potentialPair The address to check
        @param variant The pair variant (NFT is enumerable or not, pair uses ETH or ERC20)
        @return True if the address is the specified pair variant, false otherwise
     */
    function isPair(address potentialPair, PairVariant variant) public view override returns (bool) {
        if (variant == PairVariant.MISSING_ENUMERABLE_ERC20) {
            return SeacowsPairCloner.isPairClone(address(this), address(erc721Template), potentialPair);
        } else {
            // invalid input
            return false;
        }
    }

    /**
        @notice Allows receiving ETH in order to receive protocol fees
     */
    receive() external payable {}

    /**
     * Admin functions
     */

    /**
        @notice Withdraws the ETH balance to the protocol fee recipient.
        Only callable by the owner.
     */
    function withdrawETHProtocolFees() external onlyOwner {
        protocolFeeRecipient.safeTransferETH(address(this).balance);
    }

    /**
        @notice Withdraws ERC20 tokens to the protocol fee recipient. Only callable by the owner.
        @param token The token to transfer
        @param amount The amount of tokens to transfer
     */
    function withdrawERC20ProtocolFees(ERC20 token, uint256 amount) external onlyOwner {
        token.safeTransfer(protocolFeeRecipient, amount);
    }

    /**
        @notice Changes the protocol fee recipient address. Only callable by the owner.
        @param _protocolFeeRecipient The new fee recipient
     */
    function changeProtocolFeeRecipient(address payable _protocolFeeRecipient) external onlyOwner {
        require(_protocolFeeRecipient != address(0), "0 address");
        protocolFeeRecipient = _protocolFeeRecipient;
        emit ProtocolFeeRecipientUpdate(_protocolFeeRecipient);
    }

    /**
        @notice Changes the protocol fee multiplier. Only callable by the owner.
        @param _protocolFeeMultiplier The new fee multiplier, 18 decimals
     */
    function changeProtocolFeeMultiplier(uint256 _protocolFeeMultiplier) external onlyOwner {
        require(_protocolFeeMultiplier <= MAX_PROTOCOL_FEE, "Fee too large");
        protocolFeeMultiplier = _protocolFeeMultiplier;
        emit ProtocolFeeMultiplierUpdate(_protocolFeeMultiplier);
    }

    /**
        @notice Sets the whitelist status of a bonding curve contract. Only callable by the owner.
        @param bondingCurve The bonding curve contract
        @param isAllowed True to whitelist, false to remove from whitelist
     */
    function setBondingCurveAllowed(ICurve bondingCurve, bool isAllowed) external onlyOwner {
        bondingCurveAllowed[bondingCurve] = isAllowed;
        emit BondingCurveStatusUpdate(bondingCurve, isAllowed);
    }

    /**
        @notice Sets the whitelist status of a contract to be called arbitrarily by a pair.
        Only callable by the owner.
        @param target The target contract
        @param isAllowed True to whitelist, false to remove from whitelist
     */
    function setCallAllowed(address payable target, bool isAllowed) external onlyOwner {
        // ensure target is not / was not ever a router
        if (isAllowed) {
            require(!routerStatus[SeacowsRouter(target)].wasEverAllowed, "Can't call router");
        }

        callAllowed[target] = isAllowed;
        emit CallTargetStatusUpdate(target, isAllowed);
    }

    /**
        @notice Updates the router whitelist. Only callable by the owner.
        @param _router The router
        @param isAllowed True to whitelist, false to remove from whitelist
     */
    function setRouterAllowed(SeacowsRouter _router, bool isAllowed) external onlyOwner {
        // ensure target is not arbitrarily callable by pairs
        if (isAllowed) {
            require(!callAllowed[address(_router)], "Can't call router");
        }
        routerStatus[_router] = RouterStatus({ allowed: isAllowed, wasEverAllowed: true });

        emit RouterStatusUpdate(_router, isAllowed);
    }

    /**
        @notice Enable/disable a protocol fee in the pair
        @param _pair The pair contract
        @param _isProtocolFeeDisabled True to disable, false to enable protocol fee
     */
    function disableProtocolFee(SeacowsPair _pair, bool _isProtocolFeeDisabled) external onlyOwner {
        _pair.disableProtocolFee(_isProtocolFeeDisabled);

        emit ProtocolFeeDisabled(address(_pair), _isProtocolFeeDisabled);
    }

    /**
     * Internal functions
     */
    function _createPairERC721ERC20(CreateERC721ERC20PairParams memory params) internal returns (SeacowsPair pair) {
        require(params.poolType != SeacowsPair.PoolType.TOKEN || params.initialTokenBalance > params.spotPrice, "Insufficient initial token amount");

        address template = address(erc721Template);

        pair = SeacowsPair(payable(template.clonePair(this, params.bondingCurve, address(params.nft), uint8(params.poolType), params.token)));

        // mint LP tokens if trade pair
        if (params.poolType == SeacowsPair.PoolType.TRADE) {
            pair.mintLPToken(msg.sender, params.initialNFTIDs.length);
        }
    }

    function _createPairERC1155ERC20(
        IERC20 token,
        IERC1155 nft,
        ICurve bondingCurve,
        SeacowsPair.PoolType poolType,
        uint256[] memory nftIds,
        uint256[] memory nftAmounts
    ) internal returns (SeacowsPair pair) {
        require(nftIds.length == nftAmounts.length, "Invalid nft ids and amounts");

        address template = address(erc1155Template);
        // create a pair
        pair = SeacowsPair(payable(template.clonePair(this, bondingCurve, address(nft), uint8(poolType), token)));

        uint256 totalAmount;
        for (uint256 i; i < nftAmounts.length; ) {
            totalAmount += nftAmounts[i];
            // transfer nfts to the pair
            nft.safeTransferFrom(msg.sender, address(pair), nftIds[i], nftAmounts[i], "");

            unchecked {
                ++i;
            }
        }

        // mint LP tokens if trade pair
        if (poolType == SeacowsPair.PoolType.TRADE) {
            // mint LP tokens
            pair.mintLPToken(msg.sender, totalAmount);
        }

        ISeacowsPairERC1155(address(pair)).setNFTIds(nftIds, totalAmount);
    }

    function _initializePairERC1155ERC20(SeacowsPair _pair, address payable _assetRecipient, uint128 _delta, uint96 _fee, uint128 _spotPrice)
        internal
    {
        // initialize pair,
        _pair.initialize(msg.sender, _assetRecipient, _delta, _fee, _spotPrice);
    }

    /** 
      @dev Used to deposit NFTs into a pair after creation and emit an event for indexing 
      (if recipient is indeed a pair)
    */
    function depositNFTs(IERC721 _nft, uint256[] calldata ids, address recipient) external {
        // transfer NFTs from caller to recipient
        uint256 numNFTs = ids.length;
        for (uint256 i; i < numNFTs; ) {
            _nft.safeTransferFrom(msg.sender, recipient, ids[i]);

            unchecked {
                ++i;
            }
        }
        if (isPair(recipient, PairVariant.ENUMERABLE_ERC20) || isPair(recipient, PairVariant.MISSING_ENUMERABLE_ERC20)) {
            require(address(ISeacowsPair(recipient).owner()) == msg.sender, "Not a pair owner");
            emit NFTDeposit(recipient);
        }
    }

    /**
      @dev Used to deposit ERC20s into a pair after creation and emit an event for indexing 
      (if recipient is indeed an ERC20 pair and the token matches)
     */
    function depositERC20(ERC20 token, address recipient, uint256 amount) external {
        token.safeTransferFrom(msg.sender, recipient, amount);
        if (isPair(recipient, PairVariant.ENUMERABLE_ERC20) || isPair(recipient, PairVariant.MISSING_ENUMERABLE_ERC20)) {
            require(ISeacowsPair(recipient).owner() == msg.sender, "Not a pair owner");
            if (token == SeacowsPair(recipient).token()) {
                emit TokenDeposit(recipient);
            }
        }
    }

    /**
      @dev Used to deposit ETH into a pair after creation and emit an event for indexing 
      (if recipient is indeed an ETH pair and the token matches)
     */
    function depositETH(address recipient) external payable {
        IWETH(weth).deposit{ value: msg.value }();
        IWETH(weth).transfer(recipient, msg.value);
        if (isPair(recipient, PairVariant.ENUMERABLE_ERC20) || isPair(recipient, PairVariant.MISSING_ENUMERABLE_ERC20)) {
            require(ISeacowsPair(recipient).owner() == msg.sender, "Not a pair owner");
            if (address(weth) == address(SeacowsPair(recipient).token())) {
                emit TokenDeposit(recipient);
            }
        }
    }

    /** Liquidity functions */

    /**
     * @dev add ERC20 liquidity into trading pair
     * @param _nftIDs NFT ids
     * @param _amount ERC20 token amount
     */
    function addLiquidityERC20(SeacowsPair _pair, uint256[] calldata _nftIDs, uint256 _amount) public {
        uint256 numNFTs = _nftIDs.length;

        require(_pair.poolType() == SeacowsPair.PoolType.TRADE, "Not a trade pair");
        require(numNFTs > 0, "Invalid NFT amount");
        require(numNFTs * _pair.spotPrice() <= _amount, "Insufficient token amount");

        // transfer tokens to pair
        _pair.token().safeTransferFrom(msg.sender, address(_pair), _amount);

        // transfer NFTs from sender to pair
        for (uint256 i; i < numNFTs; ) {
            IERC721(_pair.nft()).safeTransferFrom(msg.sender, address(_pair), _nftIDs[i]);

            unchecked {
                ++i;
            }
        }

        // mint LP tokens
        _pair.mintLPToken(msg.sender, numNFTs);
    }

    /**
     * @dev add ERC20 liquidity into ERC1155 trading pair
     * @param _amount ERC20 token amount
     * @param _tokenAmount ERC20 token amount
     */
    function addLiquidityERC1155ERC20(ISeacowsPairERC1155 _pair, uint256 _amount, uint256 _tokenAmount) external {
        require(_pair.poolType() == SeacowsPair.PoolType.TRADE, "Not a trade pair");
        require(_pair.pairVariant() == ISeacowsPairFactoryLike.PairVariant.ERC1155_ERC20, "Not a ERC1155/ERC20 trade pair");
        require(_amount > 0, "Invalid NFT amount");
        require(_amount * _pair.spotPrice() == _tokenAmount, "Invalid token amount based on spot price");

        // transfer tokens to pair
        _pair.token().transferFrom(msg.sender, address(_pair), _tokenAmount);

        // transfer NFTs from sender to pair
        IERC1155(_pair.nft()).safeTransferFrom(msg.sender, address(_pair), _pair.nftId(), _amount, "");

        // mint LP tokens
        _pair.mintLPToken(msg.sender, _amount);
    }

    /**
     * @dev add ETH liquidity into trading pair
     * @param _nftIDs NFT ids
     */
    function addLiquidityETH(SeacowsPair _pair, uint256[] calldata _nftIDs) external payable {
        uint256 numNFTs = _nftIDs.length;

        require(_pair.poolType() == SeacowsPair.PoolType.TRADE, "Not a trade pair");
        require(numNFTs > 0, "Invalid NFT amount");
        require(numNFTs * _pair.spotPrice() <= msg.value, "Insufficient eth amount");

        IWETH(weth).deposit{ value: msg.value }();
        // transfer eth to pair
        IWETH(weth).transfer(address(_pair), msg.value);

        // transfer NFTs from sender to pair
        for (uint256 i; i < numNFTs; ) {
            IERC721(_pair.nft()).safeTransferFrom(msg.sender, address(_pair), _nftIDs[i]);

            unchecked {
                ++i;
            }
        }

        // mint LP tokens
        _pair.mintLPToken(msg.sender, numNFTs);
    }

    /**
     * @dev add ETH liquidity into ERC1155 trading pair
     * @param _amount NFT amount
     */
    function addLiquidityETHERC1155(ISeacowsPairERC1155 _pair, uint256 _amount) external payable {
        require(_pair.poolType() == SeacowsPair.PoolType.TRADE, "Not a trade pair");
        require(_pair.pairVariant() == ISeacowsPairFactoryLike.PairVariant.ERC1155_ERC20, "Not a ERC1155/ERC20 trade pair");
        require(_amount > 0, "Invalid NFT amount");
        require(_amount * _pair.spotPrice() == msg.value, "Invalid eth amount based on spot price");

        IWETH(weth).deposit{ value: msg.value }();
        // transfer weth to pair
        IWETH(weth).transfer(address(_pair), msg.value);

        // transfer NFTs from sender to pair
        IERC1155(_pair.nft()).safeTransferFrom(msg.sender, address(_pair), _pair.nftId(), _amount, "");

        // mint LP tokens
        _pair.mintLPToken(msg.sender, _amount);
    }

    /**
     * @dev remove ERC20 liquidity from trading pair
     * @param _amount lp token amount to remove
     * @param _nftIDs NFT ids to withdraw
     */
    function removeLiquidityERC20(SeacowsPair _pair, uint256 _amount, uint256[] calldata _nftIDs, bool _toEth) public {
        uint256 numNFTs = _nftIDs.length;

        require(_pair.poolType() == SeacowsPair.PoolType.TRADE, "Not a trade pair");
        require(_amount > 0, "Invalid amount");
        require(_amount == numNFTs, "Invalid NFT amount");

        // burn LP token; we check if the user has engouh LP token in the function below
        _pair.burnLPToken(msg.sender, _amount);

        // transfer tokens to the recipient
        uint256 tokenAmount = _amount * _pair.spotPrice();
        if (address(_pair.token()) == weth && _toEth) {
            _pair.token().safeTransferFrom(address(_pair), address(this), tokenAmount);
            IWETH(weth).withdraw(tokenAmount);
            payable(msg.sender).transfer(tokenAmount);
        } else {
            _pair.token().safeTransferFrom(address(_pair), msg.sender, tokenAmount);
        }

        // transfer NFTs to the recipient
        for (uint256 i; i < numNFTs; ) {
            IERC721(_pair.nft()).safeTransferFrom(address(_pair), msg.sender, _nftIDs[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev remove ERC20 liquidity from ERC1155 trading pair
     * @param _amount lp token amount to remove
     */
    function removeLiquidityERC1155ERC20(ISeacowsPairERC1155 _pair, uint256 _amount, bool _toEth) public {
        require(_pair.poolType() == SeacowsPair.PoolType.TRADE, "Not a trade pair");
        require(_pair.pairVariant() == ISeacowsPairFactoryLike.PairVariant.ERC1155_ERC20, "Not a ERC1155/ERC20 trade pair");
        require(_amount > 0, "Invalid amount");

        // burn LP token; we check if the user has engouh LP token in the function below
        _pair.burnLPToken(msg.sender, _amount);

        // transfer tokens to the user
        uint256 tokenAmount = _amount * _pair.spotPrice();
        if (address(_pair.token()) == weth && _toEth) {
            _pair.withdrawERC20(address(this), tokenAmount);
            IWETH(weth).withdraw(tokenAmount);
            payable(msg.sender).transfer(tokenAmount);
        } else {
            _pair.withdrawERC20(msg.sender, tokenAmount);
        }

        // transfer NFTs from sender to pair
        _pair.withdrawERC1155(msg.sender, _amount);
    }

    /**
     * @dev remove ETH liquidity from trading pair
     * @param _amount lp token amount to remove
     * @param _nftIDs NFT ids to withdraw
     */
    function removeLiquidityETH(SeacowsPair _pair, uint256 _amount, uint256[] calldata _nftIDs) external {
        removeLiquidityERC20(_pair, _amount, _nftIDs, true);
    }

    /**
     * @dev remove ETH liquidity from ERC1155 trading pair
     * @param _amount lp token amount to remove
     */
    function removeLiquidityETHERC1155(ISeacowsPairERC1155 _pair, uint256 _amount) external {
        removeLiquidityERC1155ERC20(_pair, _amount, true);
    }
}
