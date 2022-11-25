// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import { Script } from "forge-std/Script.sol";
import { SeacowsPairMissingEnumerableETH } from "../src/SeacowsPairMissingEnumerableETH.sol";
import { HelperConfig } from "./HelperConfig.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract DeploySeacowsPairMissingEnumerableETH is Script {
    SeacowsPairMissingEnumerableETH internal seacowsPairMissingEnumerableETH;

    function run() public {
        HelperConfig helperConfig = new HelperConfig();
        (string memory lpUri, , , , , , , , ) = helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        seacowsPairMissingEnumerableETH = new SeacowsPairMissingEnumerableETH(lpUri);
        vm.stopBroadcast();
    }
}
