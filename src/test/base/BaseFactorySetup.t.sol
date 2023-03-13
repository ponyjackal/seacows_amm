// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "forge-std/Test.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { SeacowsPairCloner } from "../../lib/SeacowsPairCloner.sol";
import { SeacowsPairFactory } from "../../SeacowsPairFactory.sol";
import { ISeacowsPairFactoryLike } from "../../interfaces/ISeacowsPairFactoryLike.sol";
import { SeacowsPair } from "../../SeacowsPair.sol";
import { SeacowsPairERC721 } from "../../SeacowsPairERC721.sol";
import { SeacowsPairERC1155 } from "../../SeacowsPairERC1155.sol";
import { LinearCurve } from "../../bondingcurve/LinearCurve.sol";
import { TestWETH } from "../../TestCollectionToken/TestWETH.sol";

/// @dev See the "Writing Tests" section in the Foundry Book if this is your first time with Forge.
/// https://book.getfoundry.sh/forge/writing-tests
contract BaseFactorySetup is Test {
    using SeacowsPairCloner for SeacowsPairERC721;

    // string internal ownerPrivateKey;
    // string internal spenderPrivateKey;

    address internal weth;
    address payable internal protocolFeeRecipient;
    uint256 internal protocolFeeMultiplier;

    SeacowsPairFactory internal seacowsPairFactory;
    SeacowsPairERC721 internal SeacowsPairERC721;
    SeacowsPairERC1155 internal seacowsPairERC1155;

    function setUp() public virtual {
        string memory lpUri = "";
        address chainlinkToken = address(0);
        address chainlinkOracle = address(0);
        string memory chainlinkJobId = "";

        weth = address(new TestWETH());
        protocolFeeRecipient = payable(address(this));
        protocolFeeMultiplier = 5000000000000000;

        /** deploy SeacowsPairERC721 */
        seacowsPairERC721 = new SeacowsPairERC721(lpUri);

        /** deploy SeacowsPairERC1155 */
        seacowsPairERC1155 = new SeacowsPairERC1155(lpUri);

        /** deploy SeacowsPairFactory */
        seacowsPairFactory = new SeacowsPairFactory(weth, seacowsPairERC721, seacowsPairERC1155, protocolFeeRecipient, protocolFeeMultiplier);
    }
}
