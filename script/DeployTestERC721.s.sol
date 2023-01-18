// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import { Script } from "forge-std/Script.sol";
import { TestERC721 } from "../src/TestCollectionToken/TestERC721.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract DeployTestERC721 is Script {
    TestERC721 internal testSeacowsNFT;

    function run() public {
        vm.startBroadcast();
        testSeacowsNFT = new TestERC721();
        vm.stopBroadcast();
    }
}
