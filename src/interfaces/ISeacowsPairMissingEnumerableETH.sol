// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import { ISeacowsPairMissingEnumerable } from "./ISeacowsPairMissingEnumerable.sol";
import { ISeacowsPairETH } from "./ISeacowsPairETH.sol";

interface ISeacowsPairMissingEnumerableETH is ISeacowsPairMissingEnumerable, ISeacowsPairETH {
    function getReserve() external view returns (uint256 nftReserve, uint256 tokenReserve);
}
