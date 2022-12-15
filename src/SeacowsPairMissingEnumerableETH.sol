// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { SeacowsPairETH } from "./SeacowsPairETH.sol";
import { SeacowsPairMissingEnumerable } from "./SeacowsPairMissingEnumerable.sol";
import { ISeacowsPairFactoryLike } from "./interfaces/ISeacowsPairFactoryLike.sol";
import { SeacowsRouter } from "./SeacowsRouter.sol";
import { ICurve } from "./bondingcurve/ICurve.sol";
import { CurveErrorCodes } from "./bondingcurve/CurveErrorCodes.sol";

contract SeacowsPairMissingEnumerableETH is SeacowsPairMissingEnumerable, SeacowsPairETH {
    constructor(string memory _uri) SeacowsPairMissingEnumerable(_uri) {}

    function pairVariant() public pure override returns (ISeacowsPairFactoryLike.PairVariant) {
        return ISeacowsPairFactoryLike.PairVariant.MISSING_ENUMERABLE_ETH;
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
    ) internal override returns (uint256 protocolFee, uint256 inputAmount) {
        CurveErrorCodes.Error error;
        // Save on 2 SLOADs by caching
        uint128 currentSpotPrice = spotPrice;
        uint128 newSpotPrice;
        // uint128 newSpotPriceOriginal;
        uint128 currentDelta = delta;
        uint128 newDelta;

        uint256 numOfNFTs = nftIds.length;

        if (poolType() == PoolType.TRADE) {
            // For trade pair, we only accept CPMM
            // get reserve
            (uint256 nftReserve, uint256 tokenReserve) = getReserve();
            (error, newSpotPrice, inputAmount, protocolFee) = _bondingCurve.getCPMMBuyInfo(
                currentSpotPrice,
                numOfNFTs,
                fee,
                _factory.protocolFeeMultiplier(),
                nftReserve,
                tokenReserve
            );

            // Revert if bonding curve had an error
            if (error != CurveErrorCodes.Error.OK) {
                revert BondingCurveError(error);
            }

            // Revert if input is more than expected
            require(inputAmount <= maxExpectedTokenInput, "In too many tokens");

            spotPrice = newSpotPrice;

            emit SpotPriceUpdate(newSpotPrice);
        } else {
            (error, newSpotPrice, newDelta, inputAmount, protocolFee) = _bondingCurve.getBuyInfo(
                currentSpotPrice,
                currentDelta,
                numOfNFTs,
                fee,
                _factory.protocolFeeMultiplier()
            );

            newSpotPrice = uint128(_applyWithOraclePrice(nftIds, details, newSpotPrice));

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
    ) internal override returns (uint256 protocolFee, uint256 outputAmount) {
        CurveErrorCodes.Error error;
        // Save on 2 SLOADs by caching
        uint128 currentSpotPrice = spotPrice;
        uint128 newSpotPrice;
        // uint128 newSpotPriceOriginal;
        uint128 currentDelta = delta;
        uint128 newDelta;
        uint256 numOfNFTs = nftIds.length;

        if (poolType() == PoolType.TRADE) {
            // For trade pair, we only accept CPMM
            // get reserve
            (uint256 nftReserve, uint256 tokenReserve) = getReserve();
            (error, newSpotPrice, outputAmount, protocolFee) = _bondingCurve.getCPMMSellInfo(
                currentSpotPrice,
                numOfNFTs,
                fee,
                _factory.protocolFeeMultiplier(),
                nftReserve,
                tokenReserve
            );

            // Revert if bonding curve had an error
            if (error != CurveErrorCodes.Error.OK) {
                revert BondingCurveError(error);
            }

            // Revert if output is too little
            require(outputAmount >= minExpectedTokenOutput, "Out too little tokens");

            spotPrice = newSpotPrice;

            emit SpotPriceUpdate(newSpotPrice);
        } else {
            (error, newSpotPrice, newDelta, outputAmount, protocolFee) = _bondingCurve.getSellInfo(
                currentSpotPrice,
                currentDelta,
                numOfNFTs,
                fee,
                _factory.protocolFeeMultiplier()
            );

            newSpotPrice = uint128(_applyWithOraclePrice(nftIds, details, newSpotPrice));

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
    }

    /**
     * @notice get reserves in the pool, only available for trade pair
     */
    function getReserve() public view onlyTrade returns (uint256 nftReserve, uint256 tokenReserve) {
        // nft balance
        nftReserve = nft().balanceOf(address(this));
        // eth balance
        tokenReserve = address(this).balance;
    }
}
