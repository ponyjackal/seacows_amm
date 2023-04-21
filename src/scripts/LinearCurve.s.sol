// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import { Script } from "forge-std/Script.sol";
import { LinearCurve } from "../bondingcurve/LinearCurve.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract DeployLinearCurve is Script {
    LinearCurve internal linearCurve;

    function run() public {
        vm.startBroadcast();

        // deploy linear curve
        linearCurve = new LinearCurve();

        vm.stopBroadcast();
    }
}
