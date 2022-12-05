// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ISeacowsPair } from "./ISeacowsPair.sol";

interface ISeacowsPairETH is ISeacowsPair {
    function withdrawAllETH() external;

    function withdrawERC20(ERC20 a, uint256 amount) external;

    function withdrawETH(uint256 amount) external;
}
