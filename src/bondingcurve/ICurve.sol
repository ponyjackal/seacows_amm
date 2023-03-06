// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { CurveErrorCodes } from "./CurveErrorCodes.sol";

interface ICurve {
    /**
        @notice Validates if a delta value is valid for the curve. The criteria for
        validity can be different for each type of curve, for instance ExponentialCurve
        requires delta to be greater than 1.
        @param delta The delta value to be validated
        @return valid True if delta is valid, false otherwise
     */
    function validateDelta(uint128 delta) external pure returns (bool valid);

    /**
        @notice Validates if a new spot price is valid for the curve. 
        Spot price is generally assumed to be the immediate sell price of 1 NFT to the pool, in units of the pool's paired token.
        @param newSpotPrice The new spot price to be set
        @return valid True if the new spot price is valid, false otherwise
     */
    function validateSpotPrice(uint128 newSpotPrice) external view returns (bool valid);

    /**
        @notice Given the current state of the pair and the trade, computes how much the user
        should pay to purchase an NFT from the pair, the new spot price, and other values.
        @param pair The pair address
        @param numItems The number of NFTs the user is buying from the pair
        @param protocolFeeMultiplier Determines how much fee the protocol takes from this trade, 18 decimals

        @return error Any math calculation errors, only Error.OK means the returned values are valid
        @return newSpotPrice The updated selling spot price, in tokens
        @return newDelta The updated delta, used to parameterize the bonding curve
        @return inputValue The amount that the user should pay, in tokens
        @return protocolFee The amount of fee to send to the protocol, in tokens
     */
    function getBuyInfo(address pair, uint256 numItems, uint256 protocolFeeMultiplier)
        external
        view
        returns (CurveErrorCodes.Error error, uint128 newSpotPrice, uint128 newDelta, uint256 inputValue, uint256 protocolFee);

    /**
        @notice Given the current state of the pair and the trade, computes how much the user
        should receive when selling NFTs to the pair, the new spot price, and other values.
        @param pair The pair address
        @param numItems The number of NFTs the user is buying from the pair
        @param protocolFeeMultiplier Determines how much fee the protocol takes from this trade, 18 decimals

        @return error Any math calculation errors, only Error.OK means the returned values are valid
        @return newSpotPrice The updated selling spot price, in tokens
        @return newDelta The updated delta, used to parameterize the bonding curve
        @return outputValue The amount that the user should receive, in tokens
        @return protocolFee The amount of fee to send to the protocol, in tokens
     */
    function getSellInfo(address pair, uint256 numItems, uint256 protocolFeeMultiplier)
        external
        view
        returns (CurveErrorCodes.Error error, uint128 newSpotPrice, uint128 newDelta, uint256 outputValue, uint256 protocolFee);
}
