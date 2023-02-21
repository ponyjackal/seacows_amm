// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "forge-std/Test.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ICurve } from "../bondingcurve/ICurve.sol";

import { SeacowsPairFactory } from "../SeacowsPairFactory.sol";
import { SeacowsPair } from "../SeacowsPair.sol";
import { TestWETH } from "../TestCollectionToken/TestWETH.sol";
import { TestERC20 } from "../TestCollectionToken/TestERC20.sol";
import { TestERC721 } from "../TestCollectionToken/TestERC721.sol";
import { TestERC721Enumerable } from "../TestCollectionToken/TestERC721Enumerable.sol";
import { WhenCreatePair } from "./base/WhenCreatePair.t.sol";

/// @dev See the "Writing Tests" section in the Foundry Book if this is your first time with Forge.
/// https://book.getfoundry.sh/forge/writing-tests
contract TestSeacowsPairFactory is WhenCreatePair {
    SeacowsPair internal erc721ERC20TradePair;
    SeacowsPair internal erc721EnumerableERC20TradePair;

    TestERC721 internal nft;
    TestERC721Enumerable internal nftEnumerable;
    TestERC20 internal token;

    function setUp() public virtual override(WhenCreatePair) {
        WhenCreatePair.setUp();

        token = new TestERC20();
        token.mint(owner, 1000 ether);

        nft = new TestERC721();
        nft.safeMint(owner);

        nftEnumerable = new TestERC721Enumerable();
        nftEnumerable.safeMint(owner);

        /** deploy Bonding Curve */
        seacowsPairFactory.setBondingCurveAllowed(linearCurve, true);

        /** create ERC721Enumerable-ERC20 Trade Pair */
        vm.startPrank(owner);
        token.approve(address(seacowsPairFactory), 1000 ether);
        nftEnumerable.setApprovalForAll(address(seacowsPairFactory), true);
        nft.setApprovalForAll(address(seacowsPairFactory), true);

        uint256[] memory nftEnumerableIds = new uint256[](1);
        nftEnumerableIds[0] = 0;
        erc721EnumerableERC20TradePair = createTradePair(token, nftEnumerable, linearCurve, 0.2 ether, 0.2 ether, 2 ether, nftEnumerableIds, 1 ether);

        /** create ERC721-ERC20 Trade Pair */
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = 0;
        erc721ERC20TradePair = createTradePair(token, nft, linearCurve, 0.2 ether, 0.2 ether, 2 ether, nftIds, 1 ether);

        vm.stopPrank();
    }

    function testProtocolFeeRecipient() public {
        /** Check protocol recipient */
        address protocolRecipient = seacowsPairFactory.protocolFeeRecipient();
        assertEq(protocolRecipient, address(0));

        /** Factory owner updates protocol recipient */
        seacowsPairFactory.changeProtocolFeeRecipient(payable(alice));
        /** Check if protocol recipient is updated*/
        address updatedProtocolRecipient = seacowsPairFactory.protocolFeeRecipient();
        assertEq(updatedProtocolRecipient, alice);

        /** Non-owner is trying to update protocol recipient */
        vm.startPrank(alice);
        vm.expectRevert("Ownable: caller is not the owner");
        seacowsPairFactory.changeProtocolFeeRecipient(payable(alice));
        vm.stopPrank();
    }
}
