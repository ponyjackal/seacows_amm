// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import { Script } from "forge-std/Script.sol";
import { TestERC20 } from "../src/TestCollectionToken/TestERC20.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract DeployTestERC20 is Script {
    TestERC20 internal token;

    function run() public {
        vm.startBroadcast();
        token = new TestERC20();
        vm.stopBroadcast();
    }
}
