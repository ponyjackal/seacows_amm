// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISeacowsRouter {
    function pairTransferERC20From(IERC20 token, address from, address to, uint256 amount) external;

    function pairTransferETHFrom(address to, uint256 amount) external;
}
