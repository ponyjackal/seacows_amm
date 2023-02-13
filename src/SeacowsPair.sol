// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { ERC1155Receiver } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

import { OwnableWithTransferCallback } from "./lib/OwnableWithTransferCallback.sol";
import { ReentrancyGuard } from "./lib/ReentrancyGuard.sol";
import { ICurve } from "./bondingcurve/ICurve.sol";
import { SeacowsRouter } from "./SeacowsRouter.sol";
import { ISeacowsPairFactoryLike } from "./interfaces/ISeacowsPairFactoryLike.sol";
import { CurveErrorCodes } from "./bondingcurve/CurveErrorCodes.sol";
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import { SeacowsCollectionRegistry } from "./priceoracle/SeacowsCollectionRegistry.sol";

/// @title The base contract for an NFT/TOKEN AMM pair
/// Inspired by 0xmons; Modified from https://github.com/sudoswap/lssvm
/// @notice This implements the core swap logic from NFT to TOKEN
abstract contract SeacowsPair is OwnableWithTransferCallback, ReentrancyGuard, AccessControl, ERC1155, ERC1155Holder {
    enum PoolType {
        TOKEN,
        NFT,
        TRADE
    }

    // 90%, must <= 1 - MAX_PROTOCOL_FEE (set in PairFactory)
    uint256 internal constant MAX_FEE = 0.90e18;

    // LP Token IDs; only used in trade pair
    uint256 public constant LP_TOKEN = 1;

    // Create a new role identifier for the minter role
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

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

    // LP total supply; only used in trade pair
    mapping(uint256 => uint256) public totalSupply;

    // Events
    event SwapNFTInPair();
    event SwapNFTOutPair();
    event SpotPriceUpdate(uint128 newSpotPrice);
    event TokenDeposit(uint256 amount);
    event TokenWithdrawal(address recipient, uint256 amount);
    event NFTWithdrawal(address recipient, uint256 amount);
    event DeltaUpdate(uint128 newDelta);
    event FeeUpdate(uint96 newFee);
    event AssetRecipientChange(address a);

    // Parameterized Errors
    error BondingCurveError(CurveErrorCodes.Error error);

    constructor(string memory _uri) ERC1155(_uri) {}

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
            assetRecipient = _assetRecipient;
        } else if (_poolType == PoolType.TRADE) {
            require(_fee < MAX_FEE, "Trade fee must be less than 90%");
            require(_assetRecipient == address(0), "Trade pools can't set asset recipient");
            fee = _fee;
        }
        require(_bondingCurve.validateDelta(_delta), "Invalid delta for curve");
        require(_bondingCurve.validateSpotPrice(_spotPrice), "Invalid new spot price for curve");
        delta = _delta;
        spotPrice = _spotPrice;

        // // grant admin role to owner
        _grantRole(ADMIN_ROLE, owner());
    }

    // -----------------------------------------
    // SeacowsPair Modifiers
    // -----------------------------------------

    modifier onlyFactory() {
        require(msg.sender == address(factory()), "Caller is not a factory");
        _;
    }

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
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
        @notice Sends token to the pair in exchange for any `numNFTs` NFTs
        @dev To compute the amount of token to send, call bondingCurve.getBuyInfo.
        This swap function is meant for users who are ID agnostic
        @param numNFTs The number of NFTs to purchase
        @param maxExpectedTokenInput The maximum acceptable cost from the sender. If the actual
        amount is greater than this value, the transaction will be reverted.
        @param nftRecipient The recipient of the NFTs
        @param isRouter True if calling from Router, false otherwise. Not used for
        ETH pairs.
        @param routerCaller If isRouter is true, ERC20 tokens will be transferred from this address. Not used for
        ETH pairs.
        @return inputAmount The amount of token used for purchase
     */
    function swapTokenForAnyNFTs(uint256 numNFTs, uint256 maxExpectedTokenInput, address nftRecipient, bool isRouter, address routerCaller)
        external
        payable
        virtual
        nonReentrant
        returns (uint256 inputAmount)
    {
        // Store locally to remove extra calls
        ISeacowsPairFactoryLike _factory = factory();
        ICurve _bondingCurve = bondingCurve();
        address _nft = nft();

        // Input validation
        {
            PoolType _poolType = poolType();
            require(_poolType == PoolType.NFT || _poolType == PoolType.TRADE, "Wrong Pool type");
            require(numNFTs > 0, "Invalid nft amount");
        }
        // Call bonding curve for pricing information
        uint256 protocolFee;
        (protocolFee, inputAmount) = _calculateBuyInfoAndUpdatePoolParams(
            new uint256[](numNFTs),
            new SeacowsRouter.NFTDetail[](numNFTs),
            maxExpectedTokenInput,
            _bondingCurve,
            _factory
        );
        _pullTokenInputAndPayProtocolFee(inputAmount, isRouter, routerCaller, _factory, protocolFee);
        _sendAnyNFTsToRecipient(_nft, nftRecipient, numNFTs);
        _refundTokenToSender(inputAmount);

        emit SwapNFTOutPair();
    }

    /**
        @notice Sends token to the pair in exchange for a specific set of NFTs
        @dev To compute the amount of token to send, call bondingCurve.getBuyInfo
        This swap is meant for users who want specific IDs. Also higher chance of
        reverting if some of the specified IDs leave the pool before the swap goes through.
        @param nftIds The list of IDs of the NFTs to purchase
        @param maxExpectedTokenInput The maximum acceptable cost from the sender. If the actual
        amount is greater than this value, the transaction will be reverted.
        @param nftRecipient The recipient of the NFTs
        @param isRouter True if calling from SeacowsRouter, false otherwise. Not used for
        ETH pairs.
        @param routerCaller If isRouter is true, ERC20 tokens will be transferred from this address. Not used for
        ETH pairs.
        @return inputAmount The amount of token used for purchase
     */
    function swapTokenForSpecificNFTs(
        uint256[] calldata nftIds,
        SeacowsRouter.NFTDetail[] calldata details,
        uint256 maxExpectedTokenInput,
        address nftRecipient,
        bool isRouter,
        address routerCaller
    ) external payable virtual nonReentrant returns (uint256 inputAmount) {
        // Store locally to remove extra calls
        ISeacowsPairFactoryLike _factory = factory();
        ICurve _bondingCurve = bondingCurve();

        // Input validation
        {
            PoolType _poolType = poolType();
            require(_poolType == PoolType.NFT || _poolType == PoolType.TRADE, "Wrong Pool type");
            require((nftIds.length > 0), "Must ask for > 0 NFTs");
        }

        // Call bonding curve for pricing information
        uint256 protocolFee;
        (protocolFee, inputAmount) = _calculateBuyInfoAndUpdatePoolParams(nftIds, details, maxExpectedTokenInput, _bondingCurve, _factory);

        _pullTokenInputAndPayProtocolFee(inputAmount, isRouter, routerCaller, _factory, protocolFee);

        _sendSpecificNFTsToRecipient(nft(), nftRecipient, nftIds);

        _refundTokenToSender(inputAmount);

        emit SwapNFTOutPair();
    }

    /**
        @notice Sends a set of NFTs to the pair in exchange for token
        @dev To compute the amount of token to that will be received, call bondingCurve.getSellInfo.
        @param nftIds The list of IDs of the NFTs to sell to the pair
        @param minExpectedTokenOutput The minimum acceptable token received by the sender. If the actual
        amount is less than this value, the transaction will be reverted.
        @param tokenRecipient The recipient of the token output
        @param isRouter True if calling from SeacowsRouter, false otherwise. Not used for
        ETH pairs.
        @param routerCaller If isRouter is true, ERC20 tokens will be transferred from this address. Not used for
        ETH pairs.
        @return outputAmount The amount of token received
     */
    function swapNFTsForToken(
        uint256[] calldata nftIds,
        SeacowsRouter.NFTDetail[] calldata details,
        uint256 minExpectedTokenOutput,
        address payable tokenRecipient,
        bool isRouter,
        address routerCaller
    ) external virtual nonReentrant returns (uint256 outputAmount) {
        // Store locally to remove extra calls
        ISeacowsPairFactoryLike _factory = factory();
        ICurve _bondingCurve = bondingCurve();

        // Input validation
        {
            PoolType _poolType = poolType();
            require(_poolType == PoolType.TOKEN || _poolType == PoolType.TRADE, "Wrong Pool type");
            require(nftIds.length > 0, "Must ask for > 0 NFTs");
        }

        // Call bonding curve for pricing information
        uint256 protocolFee;
        (protocolFee, outputAmount) = _calculateSellInfoAndUpdatePoolParams(nftIds, details, minExpectedTokenOutput, _bondingCurve, _factory);

        _sendTokenOutput(tokenRecipient, outputAmount);

        _payProtocolFeeFromPair(_factory, protocolFee);

        _takeNFTsFromSender(nft(), nftIds, _factory, isRouter, routerCaller);

        emit SwapNFTInPair();
    }

    /**
     * View functions
     */

    /**
        @dev Used as read function to query the bonding curve for buy pricing info
        @param nftIds The nftIds to buy from the pair
     */
    function getBuyNFTQuote(uint256[] memory nftIds)
        external
        view
        returns (CurveErrorCodes.Error error, uint256 newSpotPrice, uint256 newDelta, uint256 inputAmount, uint256 protocolFee)
    {
        uint256 currentSpotPrice;
        (error, currentSpotPrice, newDelta, inputAmount, protocolFee) = bondingCurve().getBuyInfo(
            spotPrice,
            delta,
            nftIds.length,
            fee,
            factory().protocolFeeMultiplier()
        );
        newSpotPrice = currentSpotPrice;
    }

    /**
        @dev Used as read function to query the bonding curve for sell pricing info
        @param nftIds The nftIds to buy from the pair
     */
    function getSellNFTQuote(uint256[] memory nftIds)
        external
        view
        returns (CurveErrorCodes.Error error, uint256 newSpotPrice, uint256 newDelta, uint256 outputAmount, uint256 protocolFee)
    {
        uint256 currentSpotPrice;
        (error, currentSpotPrice, newDelta, outputAmount, protocolFee) = bondingCurve().getSellInfo(
            spotPrice,
            delta,
            nftIds.length,
            fee,
            factory().protocolFeeMultiplier()
        );
        newSpotPrice = currentSpotPrice;
    }

    /**
        @notice Returns all NFT IDs held by the pool
     */
    function getAllHeldIds() external view virtual returns (uint256[] memory);

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

    /**
        @notice Calculates the amount needed to be sent into the pair for a buy and adjusts spot price or delta if necessary
        @param nftIds The nftIds to buy from the pair
        @param details The details of NFTs to buy from the pair
        @param maxExpectedTokenInput The maximum acceptable cost from the sender. If the actual
        amount is greater than this value, the transaction will be reverted.
        @param protocolFee The percentage of protocol fee to be taken, as a percentage
        @return protocolFee The amount of tokens to send as protocol fee
        @return inputAmount The amount of tokens total tokens receive
     */
    function _calculateBuyInfoAndUpdatePoolParams(
        uint256[] memory nftIds,
        SeacowsRouter.NFTDetail[] memory details,
        uint256 maxExpectedTokenInput,
        ICurve _bondingCurve,
        ISeacowsPairFactoryLike _factory
    ) internal virtual returns (uint256 protocolFee, uint256 inputAmount) {
        CurveErrorCodes.Error error;
        // Save on 2 SLOADs by caching
        uint128 currentSpotPrice = spotPrice;
        uint128 newSpotPrice;
        // uint128 newSpotPriceOriginal;
        uint128 currentDelta = delta;
        uint128 newDelta = delta;

        uint256 numOfNFTs = nftIds.length;

        if (poolType() == PoolType.TRADE) {
            // For trade pair, we only accept CPMM
            // get reserve
            (uint256 nftReserve, uint256 tokenReserve) = _getReserve();
            (error, newSpotPrice, inputAmount, protocolFee) = _bondingCurve.getCPMMBuyInfo(
                currentSpotPrice,
                numOfNFTs,
                fee,
                _factory.protocolFeeMultiplier(),
                nftReserve,
                tokenReserve
            );
        } else {
            (error, newSpotPrice, newDelta, inputAmount, protocolFee) = _bondingCurve.getBuyInfo(
                currentSpotPrice,
                currentDelta,
                numOfNFTs,
                fee,
                _factory.protocolFeeMultiplier()
            );

            // newSpotPrice = uint128(_applyWithOraclePrice(nftIds, details, newSpotPrice));
        }

        // Revert if bonding curve had an error
        if (error != CurveErrorCodes.Error.OK) {
            revert BondingCurveError(error);
        }
        // Revert if input is more than expected
        require(inputAmount <= maxExpectedTokenInput, "In too many tokens");

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
        @notice Calculates the amount needed to be sent by the pair for a sell and adjusts spot price or delta if necessary
        @param nftIds The nftIds to buy from the pair
        @param details The details of NFTs to buy from the pair
        @param minExpectedTokenOutput The minimum acceptable token received by the sender. If the actual
        amount is less than this value, the transaction will be reverted.
        @param protocolFee The percentage of protocol fee to be taken, as a percentage
        @return protocolFee The amount of tokens to send as protocol fee
        @return outputAmount The amount of tokens total tokens receive
     */
    function _calculateSellInfoAndUpdatePoolParams(
        uint256[] memory nftIds,
        SeacowsRouter.NFTDetail[] memory details,
        uint256 minExpectedTokenOutput,
        ICurve _bondingCurve,
        ISeacowsPairFactoryLike _factory
    ) internal virtual returns (uint256 protocolFee, uint256 outputAmount) {
        CurveErrorCodes.Error error;
        // Save on 2 SLOADs by caching
        uint128 currentSpotPrice = spotPrice;
        uint128 newSpotPrice;
        // uint128 newSpotPriceOriginal;
        uint128 currentDelta = delta;
        uint128 newDelta = delta;
        uint256 numOfNFTs = nftIds.length;

        if (poolType() == PoolType.TRADE) {
            // For trade pair, we only accept CPMM
            // get reserve
            (uint256 nftReserve, uint256 tokenReserve) = _getReserve();
            (error, newSpotPrice, outputAmount, protocolFee) = _bondingCurve.getCPMMSellInfo(
                currentSpotPrice,
                numOfNFTs,
                fee,
                _factory.protocolFeeMultiplier(),
                nftReserve,
                tokenReserve
            );
        } else {
            (error, newSpotPrice, newDelta, outputAmount, protocolFee) = _bondingCurve.getSellInfo(
                currentSpotPrice,
                currentDelta,
                numOfNFTs,
                fee,
                _factory.protocolFeeMultiplier()
            );

            // newSpotPrice = uint128(_applyWithOraclePrice(nftIds, details, newSpotPrice));
        }

        _updateSpotPrice(error, outputAmount, minExpectedTokenOutput, currentDelta, newDelta, currentSpotPrice, newSpotPrice);
    }

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
    function _getReserve() internal view virtual returns (uint256 nftReserve, uint256 tokenReserve);

    /**
        @notice Pulls the token input of a trade from the trader and pays the protocol fee.
        @param inputAmount The amount of tokens to be sent
        @param isRouter Whether or not the caller is SeacowsRouter
        @param routerCaller If called from SeacowsRouter, store the original caller
        @param _factory The SeacowsPairFactory which stores SeacowsRouter allowlist info
        @param protocolFee The protocol fee to be paid
     */
    function _pullTokenInputAndPayProtocolFee(
        uint256 inputAmount,
        bool isRouter,
        address routerCaller,
        ISeacowsPairFactoryLike _factory,
        uint256 protocolFee
    ) internal virtual;

    /**
        @notice Sends excess tokens back to the caller (if applicable)
        @dev We send ETH back to the caller even when called from SeacowsRouter because we do an aggregate slippage check for certain bulk swaps. (Instead of sending directly back to the router caller) 
        Excess ETH sent for one swap can then be used to help pay for the next swap.
     */
    function _refundTokenToSender(uint256 inputAmount) internal virtual;

    /**
        @notice Sends protocol fee (if it exists) back to the SeacowsPairFactory from the pair
     */
    function _payProtocolFeeFromPair(ISeacowsPairFactoryLike _factory, uint256 protocolFee) internal virtual;

    /**
        @notice Sends tokens to a recipient
        @param tokenRecipient The address receiving the tokens
        @param outputAmount The amount of tokens to send
     */
    function _sendTokenOutput(address payable tokenRecipient, uint256 outputAmount) internal virtual;

    /**
        @notice Sends some number of NFTs to a recipient address, ID agnostic
        @dev Even though we specify the NFT address here, this internal function is only 
        used to send NFTs associated with this specific pool.
        @param _nft The address of the NFT to send
        @param nftRecipient The receiving address for the NFTs
        @param numNFTs The number of NFTs to send  
     */
    function _sendAnyNFTsToRecipient(address _nft, address nftRecipient, uint256 numNFTs) internal virtual;

    /**
        @notice Sends specific NFTs to a recipient address
        @dev Even though we specify the NFT address here, this internal function is only 
        used to send NFTs associated with this specific pool.
        @param _nft The address of the NFT to send
        @param nftRecipient The receiving address for the NFTs
        @param nftIds The specific IDs of NFTs to send  
     */
    function _sendSpecificNFTsToRecipient(address _nft, address nftRecipient, uint256[] calldata nftIds) internal virtual;

    /**
        @notice Takes NFTs from the caller and sends them into the pair's asset recipient
        @dev This is used by the SeacowsPair's swapNFTForToken function. 
        @param _nft The NFT collection to take from
        @param nftIds The specific NFT IDs to take
        @param isRouter True if calling from SeacowsRouter, false otherwise. Not used for
        ETH pairs.
        @param routerCaller If isRouter is true, ERC20 tokens will be transferred from this address. Not used for
        ETH pairs.
     */
    function _takeNFTsFromSender(address _nft, uint256[] calldata nftIds, ISeacowsPairFactoryLike _factory, bool isRouter, address routerCaller)
        internal
        virtual
    {
        {
            address _assetRecipient = getAssetRecipient();
            uint256 numNFTs = nftIds.length;

            if (isRouter) {
                // Verify if router is allowed
                SeacowsRouter router = SeacowsRouter(payable(msg.sender));
                (bool routerAllowed, ) = _factory.routerStatus(router);
                require(routerAllowed, "Not router");

                // Call router to pull NFTs
                // If more than 1 NFT is being transfered, we can do a balance check instead of an ownership check, as pools are indifferent between NFTs from the same collection
                if (numNFTs > 1) {
                    uint256 beforeBalance = IERC721(_nft).balanceOf(_assetRecipient);
                    for (uint256 i = 0; i < numNFTs; ) {
                        router.pairTransferNFTFrom(IERC721(_nft), routerCaller, _assetRecipient, nftIds[i], pairVariant());

                        unchecked {
                            ++i;
                        }
                    }
                    require((IERC721(_nft).balanceOf(_assetRecipient) - beforeBalance) == numNFTs, "NFTs not transferred");
                } else {
                    router.pairTransferNFTFrom(IERC721(_nft), routerCaller, _assetRecipient, nftIds[0], pairVariant());
                    require(IERC721(_nft).ownerOf(nftIds[0]) == _assetRecipient, "NFT not transferred");
                }
            } else {
                // Pull NFTs directly from sender
                for (uint256 i; i < numNFTs; ) {
                    IERC721(_nft).safeTransferFrom(msg.sender, _assetRecipient, nftIds[i]);

                    unchecked {
                        ++i;
                    }
                }
            }
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
    function changeSpotPrice(uint128 newSpotPrice) external onlyAdmin {
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
    function changeDelta(uint128 newDelta) external onlyAdmin {
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
    function changeFee(uint96 newFee) external onlyAdmin {
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
        if (assetRecipient != newRecipient) {
            assetRecipient = newRecipient;
            emit AssetRecipientChange(newRecipient);
        }
    }

    /**
        @notice Allows the pair to make arbitrary external calls to contracts
        whitelisted by the protocol. Only callable by the owner.
        @param target The contract to call
        @param data The calldata to pass to the contract
     */
    function call(address payable target, bytes calldata data) external onlyOwner {
        ISeacowsPairFactoryLike _factory = factory();
        require(_factory.callAllowed(target), "Target must be whitelisted");
        (bool result, ) = target.call{ value: 0 }(data);
        require(result, "Call failed");
    }

    /**
        @notice Allows owner to batch multiple calls, forked from: https://github.com/boringcrypto/BoringSolidity/blob/master/contracts/BoringBatchable.sol 
        @dev Intended for withdrawing/altering pool pricing in one tx, only callable by owner, cannot change owner
        @param calls The calldata for each call to make
        @param revertOnFail Whether or not to revert the entire tx if any of the calls fail
     */
    function multicall(bytes[] calldata calls, bool revertOnFail) external onlyOwner {
        for (uint256 i; i < calls.length; ) {
            (bool success, bytes memory result) = address(this).delegatecall(calls[i]);
            if (!success && revertOnFail) {
                revert(_getRevertMsg(result));
            }

            unchecked {
                ++i;
            }
        }

        // Prevent multicall from malicious frontend sneaking in ownership change
        require(owner() == msg.sender, "Ownership cannot be changed in multicall");
    }

    /**
      @param _returnData The data returned from a multicall result
      @dev Used to grab the revert string from the underlying call
     */
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC1155Receiver, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // -----------------------------------------
    // Liquidity Pool functions
    // -----------------------------------------

    /**
     * note only used trade pair
     * @dev mint LP token to LP provider
     * @param recipient LP token recipient address
     * @param amount LP token amount to mint
     */
    function mintLPToken(address recipient, uint256 amount) external onlyFactory {
        require(recipient != address(0), "Invalid recipient");
        require(amount > 0, "Invliad amount");
        // mint LP to the user
        _mint(recipient, LP_TOKEN, amount, "");
    }

    /**
     * note only used trade pair
     * @dev burn LP token from LP provider
     * @param recipient LP token recipient address
     * @param amount LP token amount to mint
     */
    function burnLPToken(address recipient, uint256 amount) external onlyFactory {
        require(recipient != address(0), "Invalid recipient");
        require(balanceOf(recipient, LP_TOKEN) >= amount, "Insufficient LP token");
        require(amount > 0, "Invalid amount");
        // burn LP from the user
        _burn(recipient, LP_TOKEN, amount);
    }

    // -----------------------------------------
    // Overriden functions
    // -----------------------------------------
    /**
     * note only used trade pair
     * @dev we override _mint function to track totalSupply
     */
    function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal virtual override onlyTrade {
        totalSupply[id] += amount;
        super._mint(to, id, amount, data);

        // TODO grant admin role if user provides a decent amount
        _grantRole(ADMIN_ROLE, to);
    }

    /**
     * note only used trade pair
     * @dev we override _mint function to track totalSupply
     */
    function _burn(address from, uint256 id, uint256 amount) internal virtual override onlyTrade {
        totalSupply[id] -= amount;
        super._burn(from, id, amount);

        // TODO revoke admin role if user's LP balance is not enough
        // _revokeRole(ADMIN_ROLE, from);
    }
}
