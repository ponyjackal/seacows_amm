// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import { Script } from "forge-std/Script.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { ExponentialCurve } from "../bondingcurve/ExponentialCurve.sol";
import { HelperConfig } from "./HelperConfig.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract DeployExponentialCurve is Script {
    ExponentialCurve internal exponentialCurve;
    HelperConfig internal helperConfig;

    function run() public {
        vm.startBroadcast();

        helperConfig = new HelperConfig();
        string memory chainName = helperConfig.chainNames(block.chainid);
        string memory env = vm.envString("ENVIRONMENT");

        // deploy exponential curve
        exponentialCurve = new ExponentialCurve();

        vm.writeFile(
            string.concat("./deployed/", env, "/", chainName, "/exponentialCurve.json"),
            string.concat('{ "address":"', Strings.toHexString(address(exponentialCurve)), '" }')
        );

        vm.stopBroadcast();
    }
}
