// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "forge-std/Test.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ICurve } from "../../bondingcurve/ICurve.sol";
import { IWETH } from "../../interfaces/IWETH.sol";
import { ISeacowsPairERC721 } from "../../interfaces/ISeacowsPairERC721.sol";

import { SeacowsRouter } from "../../SeacowsRouter.sol";
import { SeacowsPairFactory } from "../../SeacowsPairFactory.sol";
import { SeacowsPair } from "../../SeacowsPair.sol";
import { TestWETH } from "../../TestCollectionToken/TestWETH.sol";
import { TestERC20 } from "../../TestCollectionToken/TestERC20.sol";
import { TestERC721 } from "../../TestCollectionToken/TestERC721.sol";
import { TestERC721Enumerable } from "../../TestCollectionToken/TestERC721Enumerable.sol";
import { WhenCreatePair } from "../base/WhenCreatePair.t.sol";

/// @dev See the "Writing Tests" section in the Foundry Book if this is your first time with Forge.
/// https://book.getfoundry.sh/forge/writing-tests
contract WhenBuyNFTs is WhenCreatePair {
    SeacowsPair internal erc721ERC20Pair;
    SeacowsPair internal erc721ETHPair;

    TestERC721 internal nft;
    TestERC20 internal token;

    function setUp() public virtual override(WhenCreatePair) {
        WhenCreatePair.setUp();

        token = new TestERC20();
        token.mint(owner, 1000 ether);
        token.mint(alice, 1000 ether);

        nft = new TestERC721();
        uint256 i;
        for (; i < 10; i++) {
            nft.safeMint(owner);
        }
        nft.safeMint(alice);
        nft.safeMint(alice);
        /** Approve Bonding Curve */
        seacowsPairFactory.setBondingCurveAllowed(linearCurve, true);
        seacowsPairFactory.setBondingCurveAllowed(exponentialCurve, true);

        /** Create ERC721Enumerable-ERC20 NFT Pair */
        vm.startPrank(owner);
        token.approve(address(seacowsPairFactory), 1 ether);
        nft.setApprovalForAll(address(seacowsPairFactory), true);

        uint256[] memory nftETHIds = new uint256[](5);
        nftETHIds[0] = 1;
        nftETHIds[1] = 2;
        nftETHIds[2] = 4;
        nftETHIds[3] = 5;
        nftETHIds[4] = 7;

        erc721ETHPair = createNFTPairETH(nft, linearCurve, payable(owner), 0.5 ether, 5 ether, nftETHIds);

        /** Create ERC721-ERC20 NFT Pair */
        uint256[] memory nftIds = new uint256[](2);
        nftIds[0] = 3;
        nftIds[1] = 9;

        erc721ERC20Pair = createNFTPair(token, nft, exponentialCurve, payable(owner), 1.1 ether, 5 ether, nftIds, 0 ether);
        vm.stopPrank();

        /** enable/disable protocol fees */
        seacowsPairFactory.disableProtocolFee(erc721ETHPair, false);
        seacowsPairFactory.disableProtocolFee(erc721ERC20Pair, true);

        vm.startPrank(alice);
        nft.setApprovalForAll(address(seacowsPairFactory), true);
        token.approve(address(erc721ERC20Pair), 100 ether);
        token.approve(address(erc721ETHPair), 100 ether);
        vm.stopPrank();
    }

    function testBuyNFTsWithProtocolFee() public {
        /** Alice is trying to buy NFTs from nft pair */
        vm.startPrank(alice);

        IWETH(weth).deposit{ value: 100 ether }();
        IWETH(weth).approve(address(erc721ETHPair), 100 ether);

        uint256[] memory nftIds = new uint256[](2);
        nftIds[0] = 1;
        nftIds[1] = 2;

        uint256 tokenBalanceAlice = IWETH(weth).balanceOf(alice);
        uint256 tokenBalanceOwner = IWETH(weth).balanceOf(owner);

        ISeacowsPairERC721(address(erc721ETHPair)).swapTokenForSpecificNFTs(
            nftIds,
            new SeacowsRouter.NFTDetail[](0),
            15 ether,
            address(alice),
            false,
            address(0)
        );
        /** Check nft owners */
        assertEq(nft.ownerOf(1), alice);
        assertEq(nft.ownerOf(2), alice);
        /** Check pair configs */
        assertEq(erc721ETHPair.spotPrice(), 6 ether);
        assertEq(erc721ETHPair.delta(), 0.5 ether);
        /** Check token balance update */
        uint256 updatedTokenBalanceAlice = IWETH(weth).balanceOf(alice);
        assertEq(updatedTokenBalanceAlice, tokenBalanceAlice - 11.5575 ether);

        uint256 updatedTokenBalanceOwner = IWETH(weth).balanceOf(owner);
        assertEq(updatedTokenBalanceOwner, tokenBalanceOwner + 11.5 ether);

        vm.stopPrank();
    }

    function testBuyNFTsWithOutProtocolFee() public {
        /** Alice is trying to buy NFTs from nft pair */
        vm.startPrank(alice);

        uint256[] memory nftIds = new uint256[](2);
        nftIds[0] = 3;
        nftIds[1] = 9;

        uint256 tokenBalanceAlice = token.balanceOf(alice);
        uint256 tokenBalanceOwner = token.balanceOf(owner);

        ISeacowsPairERC721(address(erc721ERC20Pair)).swapTokenForSpecificNFTs(
            nftIds,
            new SeacowsRouter.NFTDetail[](0),
            15 ether,
            address(alice),
            false,
            address(0)
        );
        /** Check nft owners */
        assertEq(nft.ownerOf(3), alice);
        assertEq(nft.ownerOf(9), alice);
        /** Check pair configs */
        assertEq(erc721ERC20Pair.spotPrice(), 6.05 ether);
        assertEq(erc721ERC20Pair.delta(), 1.1 ether);
        /** Check token balance update */
        uint256 updatedTokenBalanceAlice = token.balanceOf(alice);
        assertEq(updatedTokenBalanceAlice, tokenBalanceAlice - 11.55 ether);

        uint256 updatedTokenBalanceOwner = token.balanceOf(owner);
        assertEq(updatedTokenBalanceOwner, tokenBalanceOwner + 11.49225 ether);

        vm.stopPrank();
    }

    function testBuyWithInsufficientTokens() public {
        /** Alice is trying to buy NFTs from nft pair */
        vm.startPrank(alice);

        uint256[] memory nftETHIds = new uint256[](2);
        nftETHIds[0] = 1;
        nftETHIds[1] = 2;

        vm.expectRevert();
        ISeacowsPairERC721(address(erc721ETHPair)).swapTokenForSpecificNFTs(
            nftETHIds,
            new SeacowsRouter.NFTDetail[](0),
            15 ether,
            address(alice),
            false,
            address(0)
        );

        uint256[] memory nftIds = new uint256[](2);
        nftIds[0] = 1;
        nftIds[1] = 2;

        vm.expectRevert("In too many tokens");
        ISeacowsPairERC721(address(erc721ERC20Pair)).swapTokenForSpecificNFTs(
            nftIds,
            new SeacowsRouter.NFTDetail[](0),
            10 ether,
            address(alice),
            false,
            address(0)
        );

        vm.stopPrank();
    }
}
