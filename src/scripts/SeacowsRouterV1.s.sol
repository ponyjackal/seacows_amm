// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import { Script } from "forge-std/Script.sol";
import { SeacowsRouterV1 } from "../routers/SeacowsRouterV1.sol";
import { SeacowsPairERC721Factory } from "../factories/SeacowsPairERC721Factory.sol";
import { ISeacowsPairFactoryLike } from "../interfaces/ISeacowsPairFactoryLike.sol";
import { SeacowsPairERC721 } from "../pairs/SeacowsPairERC721.sol";
import { TestWETH } from "../TestCollectionToken/TestWETH.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract DeploySeacowsRouterV1 is Script {
    SeacowsRouterV1 internal router;
    SeacowsPairERC721 internal pairTemplate;
    SeacowsPairERC721Factory internal factory;
    TestWETH internal weth;
    address payable internal protocolFeeRecipient = payable(0xE078c3BDEe620829135e1ab526bE860498B06339);

    function run() public {
        vm.startBroadcast();

        // deploy weth
        weth = new TestWETH();
        // deploy erc721 pair
        pairTemplate = new SeacowsPairERC721();
        // deploy erc721 factory
        factory = new SeacowsPairERC721Factory(address(weth), pairTemplate, protocolFeeRecipient, 0.050e18);
        // deploy router
        router = new SeacowsRouterV1(address(weth));

        vm.stopBroadcast();
    }
}
