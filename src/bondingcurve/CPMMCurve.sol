// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { ICurve } from "./ICurve.sol";
import { CurveErrorCodes } from "./CurveErrorCodes.sol";
import { FixedPointMathLib } from "./FixedPointMathLib.sol";
import { ISeacowsTradePair } from "../interfaces/ISeacowsTradePair.sol";
import { ISeacowsPairFactoryLike } from "../interfaces/ISeacowsPairFactoryLike.sol";

/*
    Inspired by 0xmons; Modified from https://github.com/sudoswap/lssvm
    Bonding curve logic for a CPMM curve, where each buy/sell changes spot price by adding/substracting delta
*/
contract CPMMCurve is ICurve, CurveErrorCodes {
    using FixedPointMathLib for uint256;

    function _isPair(address _pair) internal pure {
        require(
            ISeacowsTradePair(_pair).pairVariant() == ISeacowsPairFactoryLike.PairVariant.ERC721_ERC20 ||
                ISeacowsTradePair(_pair).pairVariant() == ISeacowsPairFactoryLike.PairVariant.ERC1155_ERC20,
            "Not a seacows pair"
        );
    }

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
    function getBuyInfo(address pair, uint256 numItems, uint256 protocolFeeMultiplier)
        external
        view
        override
        returns (Error error, uint128 newSpotPrice, uint128 newDelta, uint256 inputValue, uint256 protocolFee)
    {
        _isPair(pair);
        // get pair properties
        uint128 spotPrice = ISeacowsTradePair(pair).spotPrice();
        uint128 delta = ISeacowsTradePair(pair).delta();
        uint96 feeMultiplier = ISeacowsTradePair(pair).fee();
        bool isProtocolFeeDisabled = ISeacowsTradePair(pair).isProtocolFeeDisabled();
        (uint256 nftReserve, uint256 tokenReserve) = ISeacowsTradePair(pair).getReserve();

        // We only calculate changes for buying 1 or more NFTs
        if (numItems == 0) {
            return (Error.INVALID_NUMITEMS, 0, 0, 0, 0);
        }

        // If we buy n items, then the total cost is equal to:
        // (spot price) * numOfNFTs
        inputValue = numItems * spotPrice;
        // Account for the protocol fee, a flat percentage of the buy amount
        protocolFee = inputValue.fmul(protocolFeeMultiplier, FixedPointMathLib.WAD);
        // Account for the trade fee, only for Trade pools
        inputValue += inputValue.fmul(feeMultiplier, FixedPointMathLib.WAD);

        // if protocol fee is enabled
        if (isProtocolFeeDisabled) {
            protocolFee = 0;
        }

        // Keep delta the same
        newDelta = delta;

        // For a CPMM curve, the spot price is updated based on x * y = k
        newSpotPrice = uint128((tokenReserve + inputValue) / (nftReserve - numItems));
        // If we got all the way here, no math error happened
        error = Error.OK;
    }

    /**
        @dev See {ICurve-getSellInfo}
     */
    function getSellInfo(address pair, uint256 numItems, uint256 protocolFeeMultiplier)
        external
        view
        override
        returns (Error error, uint128 newSpotPrice, uint128 newDelta, uint256 outputValue, uint256 protocolFee)
    {
        _isPair(pair);
        // get pair properties
        uint128 spotPrice = ISeacowsTradePair(pair).spotPrice();
        uint128 delta = ISeacowsTradePair(pair).delta();
        uint96 feeMultiplier = ISeacowsTradePair(pair).fee();
        bool isProtocolFeeDisabled = ISeacowsTradePair(pair).isProtocolFeeDisabled();
        (uint256 nftReserve, uint256 tokenReserve) = ISeacowsTradePair(pair).getReserve();

        // We only calculate changes for selling 1 or more NFTs
        if (numItems == 0) {
            return (Error.INVALID_NUMITEMS, 0, 0, 0, 0);
        }

        // If we sell n items, then the total sale amount is:
        // (spot price) * numOfNFTs
        outputValue = numItems * spotPrice;

        // Account for the protocol fee, a flat percentage of the sell amount
        protocolFee = outputValue.fmul(protocolFeeMultiplier, FixedPointMathLib.WAD);

        // Account for the trade fee, only for Trade pools
        outputValue -= outputValue.fmul(feeMultiplier, FixedPointMathLib.WAD);

        // if protocol fee is enabled
        if (isProtocolFeeDisabled) {
            protocolFee = 0;
        }

        // Subtract the protocol fee from the output amount to the seller
        outputValue -= protocolFee;

        // For a CPMM curve, the spot price is updated based on x * y = k
        newSpotPrice = uint128((tokenReserve - outputValue) / (nftReserve + numItems));

        // Keep delta the same
        newDelta = delta;

        // If we reached here, no math errors
        error = Error.OK;
    }
}
