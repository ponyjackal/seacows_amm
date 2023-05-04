// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import { Script } from "forge-std/Script.sol";
import { SeacowsRouterV1 } from "../routers/SeacowsRouterV1.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { SeacowsPairERC721Factory } from "../factories/SeacowsPairERC721Factory.sol";
import { ISeacowsPairFactoryLike } from "../interfaces/ISeacowsPairFactoryLike.sol";
import { SeacowsPairERC721 } from "../pairs/SeacowsPairERC721.sol";
import { TestWETH } from "../TestCollectionToken/TestWETH.sol";
import { HelperConfig } from "./HelperConfig.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract DeploySeacowsRouterV1 is Script {
    HelperConfig internal helperConfig;
    SeacowsRouterV1 internal routerV1;
    SeacowsPairERC721 internal pairERC721Template;
    SeacowsPairERC721Factory internal erc721Factory;
    TestWETH internal weth;
    address payable internal protocolFeeRecipient = payable(0xE078c3BDEe620829135e1ab526bE860498B06339);

    function run() public {
        vm.startBroadcast();

        helperConfig = new HelperConfig();
        string memory chainName = helperConfig.chainNames(block.chainid);
        string memory env = vm.envString("ENVIRONMENT");

        // deploy weth
        weth = new TestWETH();

        vm.writeFile(
            string.concat("./deployed/", env, "/", chainName, "/weth.json"),
            string.concat('{ "address":"', Strings.toHexString(address(weth)), '" }')
        );

        // deploy erc721 pair
        pairERC721Template = new SeacowsPairERC721();

        vm.writeFile(
            string.concat("./deployed/", env, "/", chainName, "/pairERC721Template.json"),
            string.concat('{ "address":"', Strings.toHexString(address(pairERC721Template)), '" }')
        );

        // deploy erc721 factory
        erc721Factory = new SeacowsPairERC721Factory(address(weth), pairERC721Template, protocolFeeRecipient, 0.050e18);

        vm.writeFile(
            string.concat("./deployed/", env, "/", chainName, "/erc721Factory.json"),
            string.concat('{ "address":"', Strings.toHexString(address(erc721Factory)), '" }')
        );

        // deploy router
        routerV1 = new SeacowsRouterV1(address(weth));

        vm.writeFile(
            string.concat("./deployed/", env, "/", chainName, "/routerV1.json"),
            string.concat('{ "address":"', Strings.toHexString(address(routerV1)), '" }')
        );

        vm.stopBroadcast();
    }
}
