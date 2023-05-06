// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import { Script } from "forge-std/Script.sol";

import { TestERC20 } from "../TestCollectionToken/TestERC20.sol";
import { TestERC721 } from "../TestCollectionToken/TestERC721.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract DeploySeacowsTestToken is Script {
    TestERC20 internal testERC20;
    TestERC721 internal testERC721;

    function run() public {
        vm.startBroadcast();

        // deploy test erc20 token
        testERC20 = new TestERC20();

        // deploy test erc721
        testERC721 = new TestERC721();

        vm.stopBroadcast();
    }
}
