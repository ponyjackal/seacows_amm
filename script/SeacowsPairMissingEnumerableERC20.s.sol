// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import { Script } from "forge-std/Script.sol";
import { SeacowsPairMissingEnumerableERC20 } from "../src/SeacowsPairMissingEnumerableERC20.sol";
import { HelperConfig } from "./HelperConfig.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract DeploySeacowsPairMissingEnumerableERC20 is Script {
    SeacowsPairMissingEnumerableERC20 internal seacowsPairMissingEnumerableERC20;

    function run() public {
        HelperConfig helperConfig = new HelperConfig();
        (string memory lpUri, , , , , , , , ) = helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        seacowsPairMissingEnumerableERC20 = new SeacowsPairMissingEnumerableERC20(lpUri);
        vm.stopBroadcast();
    }
}
