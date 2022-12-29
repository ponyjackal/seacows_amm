// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import { ISeacowsPairEnumerable } from "./ISeacowsPairEnumerable.sol";
import { ISeacowsPairETH } from "./ISeacowsPairETH.sol";

interface ISeacowsPairEnumerableETH is ISeacowsPairEnumerable, ISeacowsPairETH {
    function getReserve() external view returns (uint256 nftReserve, uint256 tokenReserve);
}
