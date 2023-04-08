// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface ISeacowsRouter {
    function pairTransferERC20From(ERC20 token, address from, address to, uint256 amount) external;
}
