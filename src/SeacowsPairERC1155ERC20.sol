// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { ISeacowsPairFactoryLike } from "./interfaces/ISeacowsPairFactoryLike.sol";
import { SeacowsPair } from "./SeacowsPair.sol";
import { SeacowsRouter } from "./SeacowsRouter.sol";
import { ICurve } from "./bondingcurve/ICurve.sol";
import { CurveErrorCodes } from "./bondingcurve/CurveErrorCodes.sol";

/**
    @title An NFT/Token pair for an NFT that implements ERC721Enumerable
    Inspired by 0xmons; Modified from https://github.com/sudoswap/lssvm
 */
contract SeacowsPairERC1155ERC20 is SeacowsPair {
    using SafeERC20 for ERC20;

    constructor(string memory _uri) SeacowsPair(_uri) {}

    uint256 internal constant IMMUTABLE_PARAMS_LENGTH = 113;

    /** View Functions */

    /**
        @notice Returns the ERC1155 token id associated with the pair
        @dev See SeacowsPairCloner for an explanation on how this works
     */
    function tokenId() public pure returns (uint256 _tokenId) {
        uint256 paramsLength = _immutableParamsLength();
        assembly {
            _tokenId := shr(0x60, calldataload(add(sub(calldatasize(), paramsLength), 81)))
        }
    }

    /**
        @notice Returns the SeacowsPair type
     */
    function pairVariant() public pure override returns (ISeacowsPairFactoryLike.PairVariant) {
        return ISeacowsPairFactoryLike.PairVariant.ERC1155_ERC20;
    }

    // @dev see SeacowsPairCloner for params length calculation
    function _immutableParamsLength() internal pure override returns (uint256) {
        return IMMUTABLE_PARAMS_LENGTH;
    }

    /**
     * @notice get reserves in the pool, only available for trade pair
     */
    function _getReserve() internal view override returns (uint256 nftReserve, uint256 tokenReserve) {
        // nft balance
        nftReserve = IERC1155(nft()).balanceOf(address(this), tokenId());
        // token balance
        tokenReserve = token().balanceOf(address(this));
    }

    /** Internal Functions */

    function _sendAnyNFTsToRecipient(address _nft, address nftRecipient, uint256 numNFTs) internal {
        // Send NFTs to recipient
        IERC1155(_nft).safeTransferFrom(address(this), nftRecipient, tokenId(), numNFTs, "");
    }

    /**
        @notice Takes NFTs from the caller and sends them into the pair's asset recipient
        @dev This is used by the SeacowsPair's swapNFTForToken function.
        @param _nft The NFT collection to take from
        @param nftIds The specific NFT IDs to take, we just need the length of IDs, no need the values in it
        @param isRouter True if calling from SeacowsRouter, false otherwise. Not used for
        ETH pairs.
        @param routerCaller If isRouter is true, ERC20 tokens will be transferred from this address. Not used for
        ETH pairs.
     */
    function _takeNFTsFromSender(address _nft, uint256[] calldata nftIds, ISeacowsPairFactoryLike _factory, bool isRouter, address routerCaller)
        internal
        override
    {
        {
            address _assetRecipient = getAssetRecipient();
            uint256 _tokenId = tokenId();
            uint256 numNFTs = nftIds.length;

            if (isRouter) {
                // Verify if router is allowed
                SeacowsRouter router = SeacowsRouter(payable(msg.sender));
                (bool routerAllowed, ) = _factory.routerStatus(router);
                require(routerAllowed, "Not router");

                // Call router to pull NFTs
                uint256 beforeBalance = IERC1155(_nft).balanceOf(_assetRecipient, _tokenId);
                IERC1155(_nft).safeTransferFrom(msg.sender, _assetRecipient, _tokenId, numNFTs, "");
                router.pairTransferNFTFromERC1155(IERC1155(_nft), _tokenId, routerCaller, _assetRecipient, numNFTs, pairVariant());

                require((IERC1155(_nft).balanceOf(_assetRecipient, _tokenId) - beforeBalance) == numNFTs, "NFTs not transferred");
            } else {
                // Pull NFTs directly from sender
                IERC1155(_nft).safeTransferFrom(msg.sender, _assetRecipient, _tokenId, numNFTs, "");
            }
        }
    }

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

    /** Mutative Functions */

    function withdrawERC1155(address _recipient, uint256 _amount) external onlyWithdrawable {
        require(poolType() == PoolType.TRADE, "Invalid pool type");
        IERC1155(nft()).safeTransferFrom(address(this), _recipient, tokenId(), _amount, "");

        emit NFTWithdrawal(_recipient, _amount);
    }

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
}
