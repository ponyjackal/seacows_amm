// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "forge-std/Test.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ICurve } from "../../bondingcurve/ICurve.sol";
import { SeacowsPair } from "../../pairs/SeacowsPair.sol";
import { TestWETH } from "../../TestCollectionToken/TestWETH.sol";
import { TestERC20 } from "../../TestCollectionToken/TestERC20.sol";
import { TestERC721 } from "../../TestCollectionToken/TestERC721.sol";
import { TestERC721Enumerable } from "../../TestCollectionToken/TestERC721Enumerable.sol";
import { ISeacowsPairERC721 } from "../../interfaces/ISeacowsPairERC721.sol";
import { WhenCreatePair } from "../base/WhenCreatePair.t.sol";

/// @dev See the "Writing Tests" section in the Foundry Book if this is your first time with Forge.
/// https://book.getfoundry.sh/forge/writing-tests
contract WhenWithdrawNFTs is WhenCreatePair {
    SeacowsPair internal erc721ERC20Pair;
    SeacowsPair internal erc721ETHPair;

    TestERC721 internal nft;
    TestERC721Enumerable internal nftEnumerable;
    TestERC20 internal token;

    function setUp() public virtual override(WhenCreatePair) {
        WhenCreatePair.setUp();

        token = new TestERC20();
        token.mint(owner, 1000 ether);

        nft = new TestERC721();
        nft.safeMint(owner, 10);
        nft.safeMint(alice, 2);

        nftEnumerable = new TestERC721Enumerable();
        for (uint256 i; i < 10; i++) {
            nftEnumerable.safeMint(owner);
        }
        nftEnumerable.safeMint(alice);
        nftEnumerable.safeMint(alice);
        /** Approve Bonding Curve */
        seacowsPairERC721Factory.setBondingCurveAllowed(linearCurve, true);
        seacowsPairERC721Factory.setBondingCurveAllowed(exponentialCurve, true);

        /** Create ERC721Enumerable-ERC20 NFT Pair */
        vm.startPrank(owner);
        token.approve(address(seacowsPairERC721Factory), 1 ether);
        nft.setApprovalForAll(address(seacowsPairERC721Factory), true);
        nftEnumerable.setApprovalForAll(address(seacowsPairERC721Factory), true);

        uint256[] memory nftETHIds = new uint256[](3);
        nftETHIds[0] = 1;
        nftETHIds[1] = 3;
        nftETHIds[2] = 6;

        erc721ETHPair = createNFTPairETH(nft, linearCurve, payable(owner), 1 ether, 5 ether, nftETHIds);

        /** Create ERC721-ERC20 NFT Pair */
        uint256[] memory nftIds = new uint256[](3);
        nftIds[0] = 1;
        nftIds[1] = 6;
        nftIds[2] = 7;

        erc721ERC20Pair = createNFTPair(token, nftEnumerable, exponentialCurve, payable(owner), 1.05 ether, 20 ether, nftIds, 1 ether);
        vm.stopPrank();

        vm.startPrank(alice);
        nft.setApprovalForAll(address(seacowsPairERC721Factory), true);
        nftEnumerable.setApprovalForAll(address(seacowsPairERC721Factory), true);
        vm.stopPrank();
    }

    function testWithdrawNFTsETH() public {
        vm.startPrank(owner);
        uint256[] memory nftIds = new uint256[](2);
        nftIds[0] = 1;
        nftIds[1] = 6;

        /** Withdraw NFTs */
        ISeacowsPairERC721(address(erc721ETHPair)).withdrawERC721(nftIds);
        /** Check nft balance */
        uint256 balance = nft.balanceOf(address(erc721ETHPair));
        assertEq(balance, 1);
        /** Check bonding curve */
        ICurve curve = erc721ETHPair.bondingCurve();
        assertEq(address(curve), address(linearCurve));
        /** Check delta */
        uint128 delta = erc721ETHPair.delta();
        assertEq(delta, 1 ether);
        /** Check spot price */
        uint128 spotPrice = erc721ETHPair.spotPrice();
        assertEq(spotPrice, 5 ether);

        /** Trying to withdraw non-existing NFTs */
        uint256[] memory nftMissingIds = new uint256[](2);
        nftMissingIds[0] = 5;
        nftMissingIds[1] = 8;
        vm.expectRevert();
        ISeacowsPairERC721(address(erc721ETHPair)).withdrawERC721(nftMissingIds);

        vm.stopPrank();

        vm.startPrank(alice);
        uint256[] memory nftIdsForAlice = new uint256[](2);
        nftIdsForAlice[0] = 10;
        nftIdsForAlice[1] = 11;
        vm.expectRevert("Caller should be an owner");
        ISeacowsPairERC721(address(erc721ETHPair)).withdrawERC721(nftIdsForAlice);
        vm.stopPrank();
    }

    function testWithdrawNFTsERC20() public {
        vm.startPrank(owner);
        uint256[] memory nftIds = new uint256[](2);
        nftIds[0] = 1;
        nftIds[1] = 7;

        /** Withdraw NFTs */
        ISeacowsPairERC721(address(erc721ERC20Pair)).withdrawERC721(nftIds);
        /** Check nft balance */
        uint256 balance = nftEnumerable.balanceOf(address(erc721ERC20Pair));
        assertEq(balance, 1);
        /** check bonding curve */
        ICurve curve = erc721ERC20Pair.bondingCurve();
        assertEq(address(curve), address(exponentialCurve));
        /** check delta */
        uint128 delta = erc721ERC20Pair.delta();
        assertEq(delta, 1.05 ether);
        /** check spot price */
        uint128 spotPrice = erc721ERC20Pair.spotPrice();
        assertEq(spotPrice, 20 ether);

        /** Trying to withdraw non-existing NFTs */
        uint256[] memory nftMissingIds = new uint256[](2);
        nftMissingIds[0] = 5;
        nftMissingIds[1] = 8;
        vm.expectRevert();
        ISeacowsPairERC721(address(erc721ERC20Pair)).withdrawERC721(nftMissingIds);

        vm.stopPrank();

        vm.startPrank(alice);
        uint256[] memory nftIdsForAlice = new uint256[](2);
        nftIdsForAlice[0] = 10;
        nftIdsForAlice[1] = 11;
        vm.expectRevert("Caller should be an owner");
        ISeacowsPairERC721(address(erc721ERC20Pair)).withdrawERC721(nftIdsForAlice);
        vm.stopPrank();
    }
}
