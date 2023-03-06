// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import { Script } from "forge-std/Script.sol";
import { HelperConfig } from "./HelperConfig.sol";
import { SeacowsRouter } from "../src/SeacowsRouter.sol";
import { SeacowsPairFactory } from "../src/SeacowsPairFactory.sol";
import { ISeacowsPairFactoryLike } from "../src/interfaces/ISeacowsPairFactoryLike.sol";
import { SeacowsPairEnumerableERC20 } from "../src/SeacowsPairEnumerableERC20.sol";
import { SeacowsPairMissingEnumerableERC20 } from "../src/SeacowsPairMissingEnumerableERC20.sol";
import { SeacowsPairERC1155ERC20 } from "../src/SeacowsPairERC1155ERC20.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract DeploySeacowsPairFactory is Script {
    SeacowsRouter internal seacowsRouter;
    SeacowsPairFactory internal seacowsPairFactory;
    SeacowsPairEnumerableERC20 internal seacowsPairEnumerableERC20;
    SeacowsPairMissingEnumerableERC20 internal seacowsPairMissingEnumerableERC20;
    SeacowsPairERC1155ERC20 internal seacowsPairERC1155ERC20;

    function run() public {
        HelperConfig helperConfig = new HelperConfig();
        (string memory lpUri, address weth, address payable protocolFeeRecipient, uint256 protocolFeeMultiplier) = helperConfig.activeNetworkConfig();

        vm.startBroadcast();

        /** deploy SeacowsPairEnumerableERC20 */
        seacowsPairEnumerableERC20 = new SeacowsPairEnumerableERC20(lpUri);

        /** deploy SeacowsPairMissingEnumerableERC20 */
        seacowsPairMissingEnumerableERC20 = new SeacowsPairMissingEnumerableERC20(lpUri);

        /** deploy SeacowsPairERC1155ERC20 */
        seacowsPairERC1155ERC20 = new SeacowsPairERC1155ERC20(lpUri);

        /** deploy SeacowsPairFactory */
        seacowsPairFactory = new SeacowsPairFactory(
            weth,
            seacowsPairEnumerableERC20,
            seacowsPairMissingEnumerableERC20,
            // seacowsPairERC1155ETH,
            seacowsPairERC1155ERC20,
            protocolFeeRecipient,
            protocolFeeMultiplier
        );

        /** deploy SeacowsRouter */
        seacowsRouter = new SeacowsRouter(ISeacowsPairFactoryLike(seacowsPairFactory));

        vm.stopBroadcast();
    }
}
