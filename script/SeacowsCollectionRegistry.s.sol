// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import { Script } from "forge-std/Script.sol";
import { SeacowsCollectionRegistry } from "../src/priceoracle/SeacowsCollectionRegistry.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract DeploySeacowsCollectionRegistry is Script {
    SeacowsCollectionRegistry internal seacowsCollectionRegistry;

    function run() public {
        vm.startBroadcast();
        seacowsCollectionRegistry = new SeacowsCollectionRegistry();
        vm.stopBroadcast();
    }
}
