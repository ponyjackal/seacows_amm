// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import { Script } from "forge-std/Script.sol";
import { MyToken } from "../src/TestCollectionToken/TestSeacowsToken.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract DeployTestSeacowsToken is Script {
    MyToken internal testSeacowsToken;

    function run() public {
        vm.startBroadcast();
        testSeacowsToken = new MyToken();
        vm.stopBroadcast();
    }
}
