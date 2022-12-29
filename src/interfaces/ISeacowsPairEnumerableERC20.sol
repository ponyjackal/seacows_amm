// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import { ISeacowsPairEnumerable } from "./ISeacowsPairEnumerable.sol";
import { ISeacowsPairERC20 } from "./ISeacowsPairERC20.sol";

interface ISeacowsPairEnumerableERC20 is ISeacowsPairEnumerable, ISeacowsPairERC20 {
    function getReserve() external view returns (uint256 nftReserve, uint256 tokenReserve);
}
