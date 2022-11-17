// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import { Script } from "forge-std/Script.sol";
import { MyNFT } from "../src/TestCollectionToken/TestSeacowsNFT.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract DeployTestSeacowsNFT is Script {
    MyNFT internal testSeacowsNFT;

    function run() public {
        vm.startBroadcast();
        testSeacowsNFT = new MyNFT();
        vm.stopBroadcast();
    }
}
