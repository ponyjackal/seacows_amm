// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "forge-std/Test.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import { SeacowsPairERC1155Factory } from "../../factories/SeacowsPairERC1155Factory.sol";
import { SeacowsPairERC721Factory } from "../../factories/SeacowsPairERC721Factory.sol";
import { SeacowsPair } from "../../pairs/SeacowsPair.sol";
import { SeacowsPairERC721 } from "../../pairs/SeacowsPairERC721.sol";
import { SeacowsPairERC1155 } from "../../pairs/SeacowsPairERC1155.sol";
import { LinearCurve } from "../../bondingcurve/LinearCurve.sol";
import { TestWETH } from "../../TestCollectionToken/TestWETH.sol";
import { ISeacowsPairFactoryLike } from "../../interfaces/ISeacowsPairFactoryLike.sol";
import { SeacowsRouterV1 } from "../../routers/SeacowsRouterV1.sol";
import { SeacowsERC1155Router } from "../../routers/SeacowsERC1155Router.sol";

/// @dev See the "Writing Tests" section in the Foundry Book if this is your first time with Forge.
/// https://book.getfoundry.sh/forge/writing-tests
contract BaseFactorySetup is Test {
    address internal weth;
    address payable internal protocolFeeRecipient;
    uint256 internal protocolFeeMultiplier;

    SeacowsPairERC1155Factory internal seacowsPairERC1155Factory;
    SeacowsPairERC721Factory internal seacowsPairERC721Factory;
    SeacowsPairERC721 internal seacowsPairERC721;
    SeacowsPairERC1155 internal seacowsPairERC1155;

    SeacowsRouterV1 internal seacowsRouterV1;
    SeacowsERC1155Router internal seacowsERC1155Router;

    function setUp() public virtual {
        weth = address(new TestWETH());
        protocolFeeRecipient = payable(address(this));
        protocolFeeMultiplier = 5000000000000000;

        /** deploy SeacowsPairERC721 */
        seacowsPairERC721 = new SeacowsPairERC721();

        /** deploy SeacowsPairERC1155 */
        seacowsPairERC1155 = new SeacowsPairERC1155();

        /** deploy SeacowsPairERC721Factory */
        seacowsPairERC721Factory = new SeacowsPairERC721Factory(weth, seacowsPairERC721, protocolFeeRecipient, protocolFeeMultiplier);

        /** deploy SeacowsPairERC1155Factory */
        seacowsPairERC1155Factory = new SeacowsPairERC1155Factory(weth, seacowsPairERC1155, protocolFeeRecipient, protocolFeeMultiplier);

        /** deploy SeacowsRouterV1 */
        seacowsRouterV1 = new SeacowsRouterV1(weth);

        /** deploy SeacowsERC1155Router */
        seacowsERC1155Router = new SeacowsERC1155Router(weth);
    }
}
