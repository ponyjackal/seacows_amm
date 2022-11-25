// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import { Script } from "forge-std/Script.sol";
import { SeacowsPairFactory } from "../src/SeacowsPairFactory.sol";
import { HelperConfig } from "./HelperConfig.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract DeploySeacowsPairFactory is Script {
    SeacowsPairFactory internal seacowsPairFactory;

    function run() public {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            address seacowsPairEnumerableETH,
            address seacowsPairMissingEnumerableETH,
            address seacowsPairEnumerableERC20,
            address seacowsPairMissingEnumerableERC20,
            address payable protocolFeeRecipient,
            uint256 protocol_feemultiplier,
            address seacowscollectionRegistry,

        ) = helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        // seacowsPairFactory = new SeacowsPairFactory(
        //     seacowsPairEnumerableETH,
        //     seacowsPairMissingEnumerableETH,
        //     seacowsPairEnumerableERC20,
        //     seacowsPairMissingEnumerableERC20,
        //     protocolFeeRecipient,
        //     protocol_feemultiplier,
        //     seacowscollectionRegistry
        // );
        vm.stopBroadcast();
    }
}
