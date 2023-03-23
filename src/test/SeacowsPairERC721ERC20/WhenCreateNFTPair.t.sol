// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "forge-std/Test.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ICurve } from "../../bondingcurve/ICurve.sol";
import { SeacowsPair } from "../../SeacowsPair.sol";
import { SeacowsPairFactory } from "../../SeacowsPairFactory.sol";
import { SeacowsPair } from "../../SeacowsPair.sol";
import { TestWETH } from "../../TestCollectionToken/TestWETH.sol";
import { TestERC20 } from "../../TestCollectionToken/TestERC20.sol";
import { TestERC721 } from "../../TestCollectionToken/TestERC721.sol";
import { TestERC721Enumerable } from "../../TestCollectionToken/TestERC721Enumerable.sol";
import { WhenCreatePair } from "../base/WhenCreatePair.t.sol";

/// @dev See the "Writing Tests" section in the Foundry Book if this is your first time with Forge.
/// https://book.getfoundry.sh/forge/writing-tests
contract WhenCreateNFTPair is WhenCreatePair {
    SeacowsPair internal erc721ERC20Pair;
    SeacowsPair internal erc721EnumerableERC20Pair;

    TestERC721Enumerable internal nftEnumerable;
    TestERC721 internal nft;
    TestERC20 internal token;

    function setUp() public virtual override(WhenCreatePair) {
        WhenCreatePair.setUp();

        token = new TestERC20();
        token.mint(owner, 1000 ether);

        nftEnumerable = new TestERC721Enumerable();
        nftEnumerable.safeMint(owner);

        nft = new TestERC721();
        nft.safeMint(owner);

        /** Approve Bonding Curve */
        seacowsPairFactory.setBondingCurveAllowed(linearCurve, true);
        seacowsPairFactory.setBondingCurveAllowed(exponentialCurve, true);

        vm.startPrank(owner);
        token.approve(address(seacowsPairFactory), 1 ether);
        nftEnumerable.setApprovalForAll(address(seacowsPairFactory), true);
        nft.setApprovalForAll(address(seacowsPairFactory), true);
        vm.stopPrank();
    }

    function testERC721EnumerableERC20NFTPair() public {
        /** Create ERC721Enumerable-ERC20 NFT Pair */
        vm.startPrank(owner);
        uint256[] memory nftEnumerableIds = new uint256[](1);
        nftEnumerableIds[0] = 0;
        erc721EnumerableERC20Pair = createNFTPair(token, nftEnumerable, linearCurve, payable(alice), 2.2 ether, 2 ether, nftEnumerableIds, 1 ether);

        assertEq(erc721EnumerableERC20Pair.nft(), address(nftEnumerable));
        assertEq(address(erc721EnumerableERC20Pair.token()), address(token));
        assertEq(address(erc721EnumerableERC20Pair.bondingCurve()), address(linearCurve));
        assertEq(erc721EnumerableERC20Pair.spotPrice(), 2 ether);
        assertEq(erc721EnumerableERC20Pair.delta(), 2.2 ether);
        assertEq(erc721EnumerableERC20Pair.fee(), 0);
        assertEq(erc721EnumerableERC20Pair.owner(), owner);
        assertEq(erc721EnumerableERC20Pair.getAssetRecipient(), alice);

        assertEq(token.balanceOf(address(erc721EnumerableERC20Pair)), 1 ether);
        assertEq(nftEnumerable.ownerOf(0), address(erc721EnumerableERC20Pair));

        vm.stopPrank();
    }

    function testERC721ERC20NFTPair() public {
        /** Create ERC721-ERC20 NFT Pair */
        vm.startPrank(owner);
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = 0;
        token.approve(address(seacowsPairFactory), 1 ether);
        nft.setApprovalForAll(address(seacowsPairFactory), true);
        erc721ERC20Pair = createNFTPair(token, nft, exponentialCurve, payable(alice), 2.2 ether, 2 ether, nftIds, 1 ether);

        assertEq(erc721ERC20Pair.nft(), address(nft));
        assertEq(address(erc721ERC20Pair.token()), address(token));
        assertEq(address(erc721ERC20Pair.bondingCurve()), address(exponentialCurve));
        assertEq(erc721ERC20Pair.spotPrice(), 2 ether);
        assertEq(erc721ERC20Pair.delta(), 2.2 ether);
        assertEq(erc721ERC20Pair.fee(), 0);
        assertEq(erc721ERC20Pair.owner(), owner);
        assertEq(erc721ERC20Pair.getAssetRecipient(), alice);

        assertEq(token.balanceOf(address(erc721ERC20Pair)), 1 ether);
        assertEq(nft.ownerOf(0), address(erc721ERC20Pair));

        vm.stopPrank();
    }

    function testWithNoAssetRecipient() public {
        /** Create ERC721-ERC20 NFT Pair */
        vm.startPrank(owner);
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = 0;
        token.approve(address(seacowsPairFactory), 1 ether);
        nft.setApprovalForAll(address(seacowsPairFactory), true);
        erc721ERC20Pair = createNFTPair(token, nft, exponentialCurve, payable(0), 2.2 ether, 2 ether, nftIds, 1 ether);

        assertEq(erc721ERC20Pair.nft(), address(nft));
        assertEq(address(erc721ERC20Pair.token()), address(token));
        assertEq(address(erc721ERC20Pair.bondingCurve()), address(exponentialCurve));
        assertEq(erc721ERC20Pair.spotPrice(), 2 ether);
        assertEq(erc721ERC20Pair.delta(), 2.2 ether);
        assertEq(erc721ERC20Pair.fee(), 0);
        assertEq(erc721ERC20Pair.owner(), owner);
        assertEq(erc721ERC20Pair.getAssetRecipient(), owner);

        assertEq(token.balanceOf(address(erc721ERC20Pair)), 1 ether);
        assertEq(nft.ownerOf(0), address(erc721ERC20Pair));

        vm.stopPrank();
    }

    function testWithInvalidParams() public {
        vm.startPrank(owner);
        /** Create ERC721-ERC20 NFT Pair with exponential curve*/
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = 0;

        vm.expectRevert("Invalid delta for curve");
        createNFTPair(token, nft, exponentialCurve, payable(owner), 0, 2 ether, nftIds, 1 ether);

        vm.expectRevert("Invalid new spot price for curve");
        createNFTPair(token, nft, exponentialCurve, payable(owner), 2.2 ether, 0, nftIds, 1 ether);

        vm.stopPrank();
    }

    function testChangeSpotPriceAndDelta() public {
        /** Create ERC721Enumerable-ERC20 NFT Pair */
        vm.startPrank(owner);
        uint256[] memory nftEnumerableIds = new uint256[](1);
        nftEnumerableIds[0] = 0;
        erc721EnumerableERC20Pair = createNFTPair(token, nftEnumerable, linearCurve, payable(alice), 2.2 ether, 2 ether, nftEnumerableIds, 1 ether);

        /** Create ERC721-ERC20 NFT Pair */
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = 0;
        token.approve(address(seacowsPairFactory), 1 ether);
        nft.setApprovalForAll(address(seacowsPairFactory), true);
        erc721ERC20Pair = createNFTPair(token, nft, exponentialCurve, payable(alice), 2.2 ether, 2 ether, nftIds, 1 ether);

        /** Change delta */
        erc721EnumerableERC20Pair.changeDelta(0.1e18);
        erc721ERC20Pair.changeDelta(1.1e18);

        /** Change spot price */
        erc721EnumerableERC20Pair.changeSpotPrice(0.1e18);
        erc721ERC20Pair.changeSpotPrice(1.1e18);

        /** Revert with invalid delta */
        vm.expectRevert("Invalid delta for curve");
        erc721EnumerableERC20Pair.changeDelta(0);
        vm.expectRevert("Invalid delta for curve");
        erc721ERC20Pair.changeDelta(0.1e18);

        /** Revert with invalid spot price */
        vm.expectRevert("Invalid new spot price for curve");
        erc721EnumerableERC20Pair.changeSpotPrice(0);
        vm.expectRevert("Invalid new spot price for curve");
        erc721ERC20Pair.changeSpotPrice(0);
        vm.stopPrank();

        /** Non pair owner is tryig to change delta and spot price */
        vm.startPrank(alice);
        /** Change delta */
        vm.expectRevert("Caller is not the owner");
        erc721EnumerableERC20Pair.changeDelta(0.1e18);
        vm.expectRevert("Caller is not the owner");
        erc721ERC20Pair.changeDelta(1.1e18);

        /** Change spot price */
        vm.expectRevert("Caller is not the owner");
        erc721EnumerableERC20Pair.changeSpotPrice(0.1e18);
        vm.expectRevert("Caller is not the owner");
        erc721ERC20Pair.changeSpotPrice(1.1e18);
        vm.stopPrank();
    }
}
