// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import { Script } from "forge-std/Script.sol";
import { SeacowsGroupFeed } from "../src/priceoracle/SeacowsGroupFeed.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract DeploySeacowsGroupFeed is Script {
    SeacowsGroupFeed internal seacowsGroupFeed;

    function run() public {
        vm.startBroadcast();
        seacowsGroupFeed = new SeacowsGroupFeed();
        vm.stopBroadcast();
    }
}
