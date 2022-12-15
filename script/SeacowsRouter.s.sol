// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import { Script } from "forge-std/Script.sol";
import { HelperConfig } from "./HelperConfig.sol";
import { SeacowsRouter } from "../src/SeacowsRouter.sol";
import { ISeacowsPairFactoryLike } from "../src/interfaces/ISeacowsPairFactoryLike.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract DeploySeacowsRouter is Script {
    SeacowsRouter internal seacowsRouter;

    function run() public {
        HelperConfig helperConfig = new HelperConfig();
        (, , , , , , , , address seacowsPairFactory) = helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        seacowsRouter = new SeacowsRouter(ISeacowsPairFactoryLike(seacowsPairFactory));
        vm.stopBroadcast();
    }
}
