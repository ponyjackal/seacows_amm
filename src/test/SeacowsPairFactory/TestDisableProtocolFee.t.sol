// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "forge-std/Test.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ICurve } from "../../bondingcurve/ICurve.sol";
import { ISeacowsPairERC721 } from "../../interfaces/ISeacowsPairERC721.sol";

import { WhenCreatePair } from "../base/WhenCreatePair.t.sol";
import { SeacowsPair } from "../../pairs/SeacowsPair.sol";
import { TestWETH } from "../../TestCollectionToken/TestWETH.sol";
import { TestERC20 } from "../../TestCollectionToken/TestERC20.sol";
import { TestERC721 } from "../../TestCollectionToken/TestERC721.sol";
import { SeacowsRouterV1 } from "../../routers/SeacowsRouterV1.sol";

/// @dev See the "Writing Tests" section in the Foundry Book if this is your first time with Forge.
/// https://book.getfoundry.sh/forge/writing-tests
contract TestDisableProtocolFee is WhenCreatePair {
    SeacowsPair internal tradePair;
    SeacowsPair internal tokenPair;
    SeacowsPair internal nftPair;

    TestERC721 internal nft;
    TestERC20 internal token;

    function setUp() public virtual override(WhenCreatePair) {
        WhenCreatePair.setUp();

        token = new TestERC20();
        token.mint(owner, 1000 ether);
        token.mint(alice, 1000 ether);

        nft = new TestERC721();

        for (uint256 i; i < 10; i++) {
            nft.safeMint(owner);
        }
        for (uint256 i; i < 10; i++) {
            nft.safeMint(alice);
        }

        /** Approve Bonding Curve */
        seacowsPairERC721Factory.setBondingCurveAllowed(linearCurve, true);
        seacowsPairERC721Factory.setBondingCurveAllowed(exponentialCurve, true);
        seacowsPairERC721Factory.setBondingCurveAllowed(cpmmCurve, true);

        /** Create ERC721Enumerable-ERC20 NFT Pair */
        vm.startPrank(owner);
        token.approve(address(seacowsPairERC721Factory), 1000 ether);
        nft.setApprovalForAll(address(seacowsPairERC721Factory), true);

        uint256[] memory nftPairNFTIds = new uint256[](3);
        nftPairNFTIds[0] = 1;
        nftPairNFTIds[1] = 3;
        nftPairNFTIds[2] = 6;

        nftPair = createNFTPair(token, nft, exponentialCurve, payable(owner), 1.05 ether, 10 ether, nftPairNFTIds, 100 ether);

        /** Create ERC721Enumerable-ERC20 Trade Pair */
        // uint256[] memory tradePairNFTIds = new uint256[](5);
        // tradePairNFTIds[0] = 0;
        // tradePairNFTIds[1] = 5;
        // tradePairNFTIds[2] = 2;
        // tradePairNFTIds[3] = 4;
        // tradePairNFTIds[4] = 7;

        // tradePair = createTradePair(token, nft, cpmmCurve, 1 ether, 0.1 ether, 10 ether, tradePairNFTIds, 100 ether);

        /** Create ERC721Enumerable-ERC20 Token Pair */
        tokenPair = createTokenPair(token, nft, linearCurve, payable(owner), 1 ether, 10 ether, new uint256[](0), 100 ether);
        vm.stopPrank();

        vm.startPrank(alice);
        nft.setApprovalForAll(address(seacowsPairERC721Factory), true);
        nft.setApprovalForAll(address(seacowsRouterV1), true);
        // nft.setApprovalForAll(address(tradePair), true);

        token.approve(address(seacowsRouterV1), 1000 ether);
        // token.approve(address(tradePair), 1000 ether);
        vm.stopPrank();
    }

    function testEnableTokenPairProtocolFee() public {
        /** Enable protocol fee for the token pair */
        seacowsPairERC721Factory.disableProtocolFee(tokenPair, false);

        /** Check protocol fee */
        uint256 protocolFeeMultiplier = seacowsPairERC721Factory.protocolFeeMultiplier();
        assertEq(protocolFeeMultiplier, 5000000000000000);

        /** Alice sells NFTs to the token pair with protocol fee */
        vm.startPrank(alice);
        uint256[] memory nftIds = new uint256[](3);
        nftIds[0] = 12;
        nftIds[1] = 13;
        nftIds[2] = 14;

        uint256 aliceTokenBalance = token.balanceOf(alice);

        SeacowsRouterV1.PairSwapSpecific memory param = SeacowsRouterV1.PairSwapSpecific(ISeacowsPairERC721(address(tokenPair)), nftIds);
        seacowsRouterV1.swapNFTsForToken(param, 25 ether, payable(alice));
        /** Check alice token balance */
        uint256 aliceTokenBalanceUpdated = token.balanceOf(alice);
        assertEq(aliceTokenBalanceUpdated, aliceTokenBalance + 26.865 ether);

        /** Check if nfts are transferred to the recipeint */
        assertEq(nft.ownerOf(12), owner);
        assertEq(nft.ownerOf(13), owner);
        assertEq(nft.ownerOf(14), owner);

        vm.stopPrank();

        /** Non-owner is trying to update protocol recipient */
        vm.startPrank(alice);
        vm.expectRevert("Ownable: caller is not the owner");
        seacowsPairERC721Factory.disableProtocolFee(tokenPair, false);
        vm.stopPrank();
    }

    function testDisableTokenPairProtocolFee() public {
        /** Disable protocol fee for the token pair */
        seacowsPairERC721Factory.disableProtocolFee(tokenPair, true);

        /** Check protocol fee */
        uint256 protocolFeeMultiplier = seacowsPairERC721Factory.protocolFeeMultiplier();
        assertEq(protocolFeeMultiplier, 5000000000000000);

        /** Alice sells NFTs to the token pair without protocol fee */
        vm.startPrank(alice);
        uint256[] memory nftIds = new uint256[](3);
        nftIds[0] = 12;
        nftIds[1] = 13;
        nftIds[2] = 14;

        uint256 aliceTokenBalance = token.balanceOf(alice);

        SeacowsRouterV1.PairSwapSpecific memory param = SeacowsRouterV1.PairSwapSpecific(ISeacowsPairERC721(address(tokenPair)), nftIds);
        seacowsRouterV1.swapNFTsForToken(param, 9 ether, payable(alice));
        /** Check alice token balance */
        uint256 aliceTokenBalanceUpdated = token.balanceOf(alice);
        assertEq(aliceTokenBalanceUpdated, aliceTokenBalance + 27 ether);

        /** Check if nfts are transferred to the recipeint */
        assertEq(nft.ownerOf(12), owner);
        assertEq(nft.ownerOf(13), owner);
        assertEq(nft.ownerOf(14), owner);

        vm.stopPrank();

        /** Non-owner is trying to update protocol recipient */
        vm.startPrank(alice);
        vm.expectRevert("Ownable: caller is not the owner");
        seacowsPairERC721Factory.disableProtocolFee(tokenPair, true);
        vm.stopPrank();
    }

    function testEnableNFTPairProtocolFee() public {
        /** Enable protocol fee for the nft pair */
        seacowsPairERC721Factory.disableProtocolFee(nftPair, false);

        /** Check protocol fee */
        uint256 protocolFeeMultiplier = seacowsPairERC721Factory.protocolFeeMultiplier();
        assertEq(protocolFeeMultiplier, 5000000000000000);

        /** Alice buys NFTs from the nft pair with protocol fee */
        vm.startPrank(alice);
        uint256 aliceTokenBalance = token.balanceOf(alice);

        SeacowsRouterV1.PairSwapAny[] memory params = new SeacowsRouterV1.PairSwapAny[](1);
        params[0] = SeacowsRouterV1.PairSwapAny(ISeacowsPairERC721(address(nftPair)), 2);
        seacowsRouterV1.swapTokenForAnyNFTs(params, 25 ether, payable(alice));
        /** Check alice token balance */
        uint256 aliceTokenBalanceUpdated = token.balanceOf(alice);
        assertEq(aliceTokenBalanceUpdated, aliceTokenBalance - 21.525 ether);

        /** Check if nfts are transferred to the alice */
        assertEq(nft.balanceOf(alice), 12);

        vm.stopPrank();

        /** Non-owner is trying to update protocol recipient */
        vm.startPrank(alice);
        vm.expectRevert("Ownable: caller is not the owner");
        seacowsPairERC721Factory.disableProtocolFee(nftPair, false);
        vm.stopPrank();
    }

    function testDisableNFTPairProtocolFee() public {
        /** Disable protocol fee for the nft pair */
        seacowsPairERC721Factory.disableProtocolFee(nftPair, true);

        /** Check protocol fee */
        uint256 protocolFeeMultiplier = seacowsPairERC721Factory.protocolFeeMultiplier();
        assertEq(protocolFeeMultiplier, 5000000000000000);

        /** Alice buys NFTs from the nft pair without protocol fee */
        vm.startPrank(alice);
        uint256 aliceTokenBalance = token.balanceOf(alice);
        uint256 ownerTokenBalance = token.balanceOf(owner); // asset recipient

        uint256[] memory nftIds = new uint256[](2);
        nftIds[0] = 1;
        nftIds[1] = 3;

        SeacowsRouterV1.PairSwapSpecific[] memory params = new SeacowsRouterV1.PairSwapSpecific[](1);
        params[0] = SeacowsRouterV1.PairSwapSpecific(ISeacowsPairERC721(address(nftPair)), nftIds);
        seacowsRouterV1.swapTokenForSpecificNFTs(params, 25 ether, payable(alice));
        /** Check alice token balance */
        uint256 aliceTokenBalanceUpdated = token.balanceOf(alice);
        assertEq(aliceTokenBalanceUpdated, aliceTokenBalance - 21.525 ether);

        /** Check asset recipient token balance */
        uint256 ownerTokenBalanceUpdated = token.balanceOf(owner);
        assertEq(ownerTokenBalanceUpdated, ownerTokenBalance + 21.525 ether);

        /** Check if nfts are transferred to the alice */
        assertEq(nft.ownerOf(1), alice);
        assertEq(nft.ownerOf(3), alice);

        vm.stopPrank();

        /** Non-owner is trying to update protocol recipient */
        vm.startPrank(alice);
        vm.expectRevert("Ownable: caller is not the owner");
        seacowsPairERC721Factory.disableProtocolFee(nftPair, true);
        vm.stopPrank();
    }

    // function testEnableTradePairProtocolFeeBuy() public {
    //     /** Enable protocol fee for the trade pair */
    //     seacowsPairERC721Factory.disableProtocolFee(tradePair, false);

    //     /** Check protocol fee */
    //     uint256 protocolFeeMultiplier = seacowsPairERC721Factory.protocolFeeMultiplier();
    //     assertEq(protocolFeeMultiplier, 5000000000000000);

    //     /** Alice buys NFTs from the trade pair with protocol fee */
    //     vm.startPrank(alice);
    //     uint256 aliceTokenBalance = token.balanceOf(alice);

    //     ISeacowsPairERC721(address(tradePair)).swapTokenForAnyNFTs(2, 25 ether, payable(alice));
    //     /** Check alice token balance */
    //     uint256 aliceTokenBalanceUpdated = token.balanceOf(alice);
    //     assertEq(aliceTokenBalanceUpdated, aliceTokenBalance - 22.1 ether);

    //     /** Check if nfts are transferred to the alice */
    //     assertEq(nft.balanceOf(alice), 12);

    //     vm.stopPrank();

    //     /** Non-owner is trying to update protocol recipient */
    //     vm.startPrank(alice);
    //     vm.expectRevert("Ownable: caller is not the owner");
    //     seacowsPairERC721Factory.disableProtocolFee(tradePair, false);
    //     vm.stopPrank();
    // }

    // function testDisableTradePairProtocolFeeBuy() public {
    //     /** Disable protocol fee for the trade pair */
    //     seacowsPairERC721Factory.disableProtocolFee(tradePair, true);

    //     /** Check protocol fee */
    //     uint256 protocolFeeMultiplier = seacowsPairERC721Factory.protocolFeeMultiplier();
    //     assertEq(protocolFeeMultiplier, 5000000000000000);

    //     /** Alice buys NFTs from the trade pair without protocol fee */
    //     vm.startPrank(alice);
    //     uint256 aliceTokenBalance = token.balanceOf(alice);

    //     ISeacowsPairERC721(address(tradePair)).swapTokenForAnyNFTs(2, 25 ether, payable(alice));
    //     /** Check alice token balance */
    //     uint256 aliceTokenBalanceUpdated = token.balanceOf(alice);
    //     assertEq(aliceTokenBalanceUpdated, aliceTokenBalance - 22 ether);

    //     /** Check if nfts are transferred to the alice */
    //     assertEq(nft.balanceOf(alice), 12);

    //     vm.stopPrank();

    //     /** Non-owner is trying to update protocol recipient */
    //     vm.startPrank(alice);
    //     vm.expectRevert("Ownable: caller is not the owner");
    //     seacowsPairERC721Factory.disableProtocolFee(tradePair, true);
    //     vm.stopPrank();
    // }

    // function testEnableTradePairProtocolFeeSell() public {
    //     /** Enable protocol fee for the trade pair */
    //     seacowsPairERC721Factory.disableProtocolFee(tradePair, false);

    //     /** Check protocol fee */
    //     uint256 protocolFeeMultiplier = seacowsPairERC721Factory.protocolFeeMultiplier();
    //     assertEq(protocolFeeMultiplier, 5000000000000000);

    //     /** Alice sells NFTs to the trade pair with protocol fee */
    //     vm.startPrank(alice);
    //     uint256[] memory nftIds = new uint256[](3);
    //     nftIds[0] = 12;
    //     nftIds[1] = 13;
    //     nftIds[2] = 14;

    //     uint256 aliceTokenBalance = token.balanceOf(alice);

    //     ISeacowsPairERC721(address(tradePair)).swapNFTsForToken(nftIds, 25 ether, payable(alice));
    //     /** Check alice token balance */
    //     uint256 aliceTokenBalanceUpdated = token.balanceOf(alice);
    //     assertEq(aliceTokenBalanceUpdated, aliceTokenBalance + 26.85 ether);

    //     /** Check if nfts are transferred to the trade pair */
    //     assertEq(nft.ownerOf(12), address(tradePair));
    //     assertEq(nft.ownerOf(13), address(tradePair));
    //     assertEq(nft.ownerOf(14), address(tradePair));

    //     vm.stopPrank();

    //     /** Non-owner is trying to update protocol recipient */
    //     vm.startPrank(alice);
    //     vm.expectRevert("Ownable: caller is not the owner");
    //     seacowsPairERC721Factory.disableProtocolFee(tradePair, false);
    //     vm.stopPrank();
    // }

    // function testDisableTradePairProtocolFeeSell() public {
    //     /** Disable protocol fee for the trade pair */
    //     seacowsPairERC721Factory.disableProtocolFee(tradePair, true);

    //     /** Check protocol fee */
    //     uint256 protocolFeeMultiplier = seacowsPairERC721Factory.protocolFeeMultiplier();
    //     assertEq(protocolFeeMultiplier, 5000000000000000);

    //     /** Alice sells NFTs to the trade pair without protocol fee */
    //     vm.startPrank(alice);
    //     uint256[] memory nftIds = new uint256[](3);
    //     nftIds[0] = 12;
    //     nftIds[1] = 13;
    //     nftIds[2] = 14;

    //     uint256 aliceTokenBalance = token.balanceOf(alice);

    //     ISeacowsPairERC721(address(tradePair)).swapNFTsForToken(nftIds, 25 ether, payable(alice));
    //     /** Check alice token balance */
    //     uint256 aliceTokenBalanceUpdated = token.balanceOf(alice);
    //     assertEq(aliceTokenBalanceUpdated, aliceTokenBalance + 27 ether);

    //     /** Check if nfts are transferred to the trade pair */
    //     assertEq(nft.ownerOf(12), address(tradePair));
    //     assertEq(nft.ownerOf(13), address(tradePair));
    //     assertEq(nft.ownerOf(14), address(tradePair));

    //     vm.stopPrank();

    //     /** Non-owner is trying to update protocol recipient */
    //     vm.startPrank(alice);
    //     vm.expectRevert("Ownable: caller is not the owner");
    //     seacowsPairERC721Factory.disableProtocolFee(tradePair, true);
    //     vm.stopPrank();
    // }

    // function testChangeProtocolFeeMultiplier() public {
    //     /** Change Protocol Fee */
    //     seacowsPairERC721Factory.changeProtocolFeeMultiplier(3000000000000000);

    //     /** Check protocol fee */
    //     uint256 protocolFeeMultiplier = seacowsPairERC721Factory.protocolFeeMultiplier();
    //     assertEq(protocolFeeMultiplier, 3000000000000000);

    //     /** Alice buys NFTs from the trade pair with protocol fee */
    //     vm.startPrank(alice);
    //     uint256 aliceTokenBalance = token.balanceOf(alice);

    //     ISeacowsPairERC721(address(tradePair)).swapTokenForAnyNFTs(2, 25 ether, payable(alice));
    //     /** Check alice token balance */
    //     uint256 aliceTokenBalanceUpdated = token.balanceOf(alice);
    //     assertEq(aliceTokenBalanceUpdated, aliceTokenBalance - 22.06 ether);

    //     /** Check if nfts are transferred to the alice */
    //     assertEq(nft.balanceOf(alice), 12);

    //     /** Alice buys NFTs from the nft pair without protocol fee */
    //     aliceTokenBalance = token.balanceOf(alice);

    //     ISeacowsPairERC721(address(nftPair)).swapTokenForAnyNFTs(2, 25 ether, payable(alice));
    //     /** Check alice token balance */
    //     aliceTokenBalanceUpdated = token.balanceOf(alice);
    //     assertEq(aliceTokenBalanceUpdated, aliceTokenBalance - 21.589575 ether);

    //     vm.stopPrank();

    //     /** Non-owner is trying to change protocol fee */
    //     vm.startPrank(alice);
    //     vm.expectRevert("Ownable: caller is not the owner");
    //     seacowsPairERC721Factory.changeProtocolFeeMultiplier(3000000000000000);
    //     vm.stopPrank();

    //     /** Trying to set protocol fee greater than 10% */
    //     vm.expectRevert("Fee too large");
    //     seacowsPairERC721Factory.changeProtocolFeeMultiplier(0.12e18);
    // }

    function testProtocolFeeRecipient() public {
        /** Check protocol recipient */
        address protocolRecipient = seacowsPairERC721Factory.protocolFeeRecipient();
        assertEq(protocolRecipient, address(this));

        /** Factory owner updates protocol recipient */
        seacowsPairERC721Factory.changeProtocolFeeRecipient(payable(alice));
        /** Check if protocol recipient is updated*/
        address updatedProtocolRecipient = seacowsPairERC721Factory.protocolFeeRecipient();
        assertEq(updatedProtocolRecipient, alice);

        /** Non-owner is trying to update protocol recipient */
        vm.startPrank(alice);
        vm.expectRevert("Ownable: caller is not the owner");
        seacowsPairERC721Factory.changeProtocolFeeRecipient(payable(alice));
        vm.stopPrank();
    }
}
