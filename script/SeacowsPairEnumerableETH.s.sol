// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import { Script } from "forge-std/Script.sol";
import { SeacowsPairEnumerableETH } from "../src/SeacowsPairEnumerableETH.sol";
import { HelperConfig } from "./HelperConfig.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract DeploySeacowsPairEnumerableETH is Script {
    SeacowsPairEnumerableETH internal seacowsPairEnumerableETH;

    function run() public {
        HelperConfig helperConfig = new HelperConfig();
        (string memory lpUri, , , , , , , , ) = helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        seacowsPairEnumerableETH = new SeacowsPairEnumerableETH(lpUri);
        vm.stopBroadcast();
    }
}
