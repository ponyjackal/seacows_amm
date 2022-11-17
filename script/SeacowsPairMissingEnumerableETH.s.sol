// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import { Script } from "forge-std/Script.sol";
import { SeacowsPairMissingEnumerableETH } from "../src/SeacowsPairMissingEnumerableETH.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract DeploySeacowsPairMissingEnumerableETH is Script {
    SeacowsPairMissingEnumerableETH internal seacowsPairMissingEnumerableETH;

    function run() public {
        vm.startBroadcast();
        seacowsPairMissingEnumerableETH = new SeacowsPairMissingEnumerableETH();
        vm.stopBroadcast();
    }
}
