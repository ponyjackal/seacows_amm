// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import { Script } from "forge-std/Script.sol";
import { ExponentialCurve } from "../src/bondingcurve/ExponentialCurve.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract DeployExponentialCurve is Script {
    ExponentialCurve internal exponentialCurve;

    function run() public {
        vm.startBroadcast();
        exponentialCurve = new ExponentialCurve();
        vm.stopBroadcast();
    }
}
