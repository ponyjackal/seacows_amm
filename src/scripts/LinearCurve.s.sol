// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import { Script } from "forge-std/Script.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { LinearCurve } from "../bondingcurve/LinearCurve.sol";
import { HelperConfig } from "./HelperConfig.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract DeployLinearCurve is Script {
    LinearCurve internal linearCurve;
    HelperConfig internal helperConfig;

    function run() public {
        vm.startBroadcast();

        helperConfig = new HelperConfig();
        string memory chainName = helperConfig.chainNames(block.chainid);
        string memory env = vm.envString("ENVIRONMENT");

        // deploy linear curve
        linearCurve = new LinearCurve();

        vm.writeFile(
            string.concat("./deployed/", env, "/", chainName, "/linearCurve.json"),
            string.concat('{ "address":"', Strings.toHexString(address(linearCurve)), '" }')
        );

        vm.stopBroadcast();
    }
}
