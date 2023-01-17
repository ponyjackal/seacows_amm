// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import { ISeacowsPairERC1155 } from "./ISeacowsPairERC1155.sol";
import { ISeacowsPairERC20 } from "./ISeacowsPairERC20.sol";

interface ISeacowsPairERC1155ERC20 is ISeacowsPairERC1155, ISeacowsPairERC20 {
    function getReserve() external view returns (uint256 nftReserve, uint256 tokenReserve);
}
