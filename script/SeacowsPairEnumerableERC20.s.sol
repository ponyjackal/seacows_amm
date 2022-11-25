// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import { Script } from "forge-std/Script.sol";
import { SeacowsPairEnumerableERC20 } from "../src/SeacowsPairEnumerableERC20.sol";
import { HelperConfig } from "./HelperConfig.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract DeploySeacowsPairEnumerableERC20 is Script {
    SeacowsPairEnumerableERC20 internal seacowsPairEnumerableERC20;

    function run() public {
        HelperConfig helperConfig = new HelperConfig();
        (string memory lpUri, , , , , , , , ) = helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        seacowsPairEnumerableERC20 = new SeacowsPairEnumerableERC20(lpUri);
        vm.stopBroadcast();
    }
}
