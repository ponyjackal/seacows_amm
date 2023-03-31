// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "forge-std/Test.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import { SeacowsPairFactory } from "../../factories/SeacowsPairFactory.sol";
import { SeacowsPairERC721Factory } from "../../factories/SeacowsPairERC721Factory.sol";
import { SeacowsPair } from "../../pairs/SeacowsPair.sol";
import { SeacowsPairERC721 } from "../../pairs/SeacowsPairERC721.sol";
import { SeacowsPairERC1155 } from "../../pairs/SeacowsPairERC1155.sol";
import { LinearCurve } from "../../bondingcurve/LinearCurve.sol";
import { TestWETH } from "../../TestCollectionToken/TestWETH.sol";

import { ISeacowsPairFactoryLike } from "../../interfaces/ISeacowsPairFactoryLike.sol";

/// @dev See the "Writing Tests" section in the Foundry Book if this is your first time with Forge.
/// https://book.getfoundry.sh/forge/writing-tests
contract BaseFactorySetup is Test {
    // string internal ownerPrivateKey;
    // string internal spenderPrivateKey;

    address internal weth;
    address payable internal protocolFeeRecipient;
    uint256 internal protocolFeeMultiplier;

    SeacowsPairFactory internal seacowsPairFactory;
    SeacowsPairERC721Factory internal seacowsPairERC721Factory;
    SeacowsPairERC721 internal seacowsPairERC721;
    SeacowsPairERC1155 internal seacowsPairERC1155;

    function setUp() public virtual {
        weth = address(new TestWETH());
        protocolFeeRecipient = payable(address(this));
        protocolFeeMultiplier = 5000000000000000;

        /** deploy SeacowsPairERC721 */
        seacowsPairERC721 = new SeacowsPairERC721();

        /** deploy SeacowsPairERC1155 */
        seacowsPairERC1155 = new SeacowsPairERC1155();

        /** deploy SeacowsPairFactory */
        seacowsPairFactory = new SeacowsPairFactory(weth, seacowsPairERC721, seacowsPairERC1155, protocolFeeRecipient, protocolFeeMultiplier);

        /** deploy SeacowsPairERC721Factory */
        seacowsPairERC721Factory = new SeacowsPairERC721Factory(weth, seacowsPairERC721, protocolFeeRecipient, protocolFeeMultiplier);
    }
}
