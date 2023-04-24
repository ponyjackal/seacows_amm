// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import { ISeacowsPair } from "./ISeacowsPair.sol";

interface ISeacowsTradePair is ISeacowsPair {
    function getReserve() external view returns (uint256, uint256);
}
