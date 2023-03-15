// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import { Script } from "forge-std/Script.sol";
import { HelperConfig } from "./HelperConfig.sol";
import { SeacowsRouter } from "../src/SeacowsRouter.sol";
import { SeacowsPairFactory } from "../src/SeacowsPairFactory.sol";
import { ISeacowsPairFactoryLike } from "../src/interfaces/ISeacowsPairFactoryLike.sol";
import { SeacowsPairERC721 } from "../src/SeacowsPairERC721.sol";
import { SeacowsPairERC1155 } from "../src/SeacowsPairERC1155.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract DeploySeacowsPairFactory is Script {
    SeacowsRouter internal seacowsRouter;
    SeacowsPairFactory internal seacowsPairFactory;
    SeacowsPairERC721 internal seacowsPairERC721;
    SeacowsPairERC1155 internal seacowsPairERC1155;

    function run() public {
        HelperConfig helperConfig = new HelperConfig();
        (string memory lpUri, address weth, address payable protocolFeeRecipient, uint256 protocolFeeMultiplier) = helperConfig.activeNetworkConfig();

        vm.startBroadcast();

        /** deploy SeacowsPairERC721 */
        seacowsPairERC721 = new SeacowsPairERC721(lpUri);

        /** deploy SeacowsPairERC1155 */
        seacowsPairERC1155 = new SeacowsPairERC1155(lpUri);

        /** deploy SeacowsPairFactory */
        seacowsPairFactory = new SeacowsPairFactory(weth, seacowsPairERC721, seacowsPairERC1155, protocolFeeRecipient, protocolFeeMultiplier);

        /** deploy SeacowsRouter */
        seacowsRouter = new SeacowsRouter(ISeacowsPairFactoryLike(seacowsPairFactory));

        vm.stopBroadcast();
    }
}
