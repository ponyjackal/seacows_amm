// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ISeacowsPair } from "./ISeacowsPair.sol";

interface ISeacowsPairERC20 is ISeacowsPair {
    function token() external returns (ERC20 _token);
}