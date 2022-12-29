// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { ICurve } from "./ICurve.sol";
import { CurveErrorCodes } from "./CurveErrorCodes.sol";
import { FixedPointMathLib } from "./FixedPointMathLib.sol";

/*
    Inspired by 0xmons; Modified from https://github.com/sudoswap/lssvm
    Bonding curve logic for a CPMM curve, where each buy/sell changes spot price by adding/substracting delta
*/
abstract contract CPMMCurve is ICurve, CurveErrorCodes {
    using FixedPointMathLib for uint256;

    /**
        @dev See {ICurve-validateDelta}, we don't use this function in CPMM curve
     */
    function validateDelta(uint128 /*delta*/) external pure override returns (bool valid) {
        // For a CPMM curve, we don't call this function
        return true;
    }

    /**
        @dev See {ICurve-validateSpotPrice}
     */
    function validateSpotPrice(uint128 /* newSpotPrice */) external pure override returns (bool) {
        // For a CPMM curve, all values of spot price are valid
        return true;
    }

    /**
        @dev See {ICurve-getBuyInfo}
     */
    function getCPMMBuyInfo(
        uint128 spotPrice,
        uint256 numItems,
        uint256 feeMultiplier,
        uint256 protocolFeeMultiplier,
        uint256 nftReserve,
        uint256 tokenReserve
    )
        external
        pure
        override
        returns (CurveErrorCodes.Error error, uint128 newSpotPrice, uint256 inputValue, uint256 protocolFee)
    {
        // We only calculate changes for buying 1 or more NFTs
        if (numItems == 0) {
            return (Error.INVALID_NUMITEMS, 0, 0, 0);
        }

        // If we buy n items, then the total cost is equal to:
        // (spot price) * numOfNFTs
        inputValue = numItems * spotPrice;

        // Account for the protocol fee, a flat percentage of the buy amount
        protocolFee = inputValue.fmul(protocolFeeMultiplier, FixedPointMathLib.WAD);

        // Account for the trade fee, only for Trade pools
        inputValue += inputValue.fmul(feeMultiplier, FixedPointMathLib.WAD);

        // Add the protocol fee to the required input amount
        inputValue += protocolFee;

        // For a CPMM curve, the spot price is updated based on x * y = k
        newSpotPrice = uint128((tokenReserve + inputValue) / (nftReserve - numItems));

        // If we got all the way here, no math error happened
        error = Error.OK;
    }

    /**
        @dev See {ICurve-getSellInfo}
     */
    function getCPMMSellInfo(
        uint128 spotPrice,
        uint256 numItems,
        uint256 feeMultiplier,
        uint256 protocolFeeMultiplier,
        uint256 nftReserve,
        uint256 tokenReserve
    ) external pure override returns (Error error, uint128 newSpotPrice, uint256 outputValue, uint256 protocolFee) {
        // We only calculate changes for selling 1 or more NFTs
        if (numItems == 0) {
            return (Error.INVALID_NUMITEMS, 0, 0, 0);
        }

        // If we sell n items, then the total sale amount is:
        // (spot price) * numOfNFTs
        outputValue = numItems * spotPrice;

        // Account for the protocol fee, a flat percentage of the sell amount
        protocolFee = outputValue.fmul(protocolFeeMultiplier, FixedPointMathLib.WAD);

        // Account for the trade fee, only for Trade pools
        outputValue -= outputValue.fmul(feeMultiplier, FixedPointMathLib.WAD);

        // Subtract the protocol fee from the output amount to the seller
        outputValue -= protocolFee;

        // For a CPMM curve, the spot price is updated based on x * y = k
        newSpotPrice = uint128((tokenReserve - outputValue) / (nftReserve + numItems));

        // If we reached here, no math errors
        error = Error.OK;
    }
}
