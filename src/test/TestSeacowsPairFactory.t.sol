// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "forge-std/Test.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { WhenCreatePair } from "./base/WhenCreatePair.t.sol";

import { ICurve } from "../bondingcurve/ICurve.sol";
import { ISeacowsPairEnumerableERC20 } from "../interfaces/ISeacowsPairEnumerableERC20.sol";

import { SeacowsRouter } from "../SeacowsRouter.sol";
import { SeacowsPairFactory } from "../SeacowsPairFactory.sol";
import { SeacowsPair } from "../SeacowsPair.sol";
import { TestWETH } from "../TestCollectionToken/TestWETH.sol";
import { TestERC20 } from "../TestCollectionToken/TestERC20.sol";
import { TestERC721 } from "../TestCollectionToken/TestERC721.sol";

/// @dev See the "Writing Tests" section in the Foundry Book if this is your first time with Forge.
/// https://book.getfoundry.sh/forge/writing-tests
contract TestSeacowsPairFactory is WhenCreatePair {
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
        seacowsPairFactory.setBondingCurveAllowed(linearCurve, true);
        seacowsPairFactory.setBondingCurveAllowed(exponentialCurve, true);
        seacowsPairFactory.setBondingCurveAllowed(cpmmCurve, true);

        /** Create ERC721Enumerable-ERC20 NFT Pair */
        vm.startPrank(owner);
        token.approve(address(seacowsPairFactory), 1000 ether);
        nft.setApprovalForAll(address(seacowsPairFactory), true);

        uint256[] memory nftPairNFTIds = new uint256[](3);
        nftPairNFTIds[0] = 1;
        nftPairNFTIds[1] = 3;
        nftPairNFTIds[2] = 6;

        nftPair = createNFTPair(token, nft, exponentialCurve, payable(owner), 1.05 ether, 10 ether, nftPairNFTIds, 100 ether);

        /** Create ERC721Enumerable-ERC20 Trade Pair */
        uint256[] memory tradePairNFTIds = new uint256[](2);
        tradePairNFTIds[0] = 0;
        tradePairNFTIds[1] = 5;

        tradePair = createTradePair(token, nft, cpmmCurve, 1 ether, 0.1 ether, 10 ether, tradePairNFTIds, 100 ether);

        /** Create ERC721Enumerable-ERC20 Token Pair */
        tokenPair = createTokenPair(token, nft, linearCurve, payable(owner), 1 ether, 10 ether, new uint256[](0), 100 ether);
        vm.stopPrank();

        vm.startPrank(alice);
        nft.setApprovalForAll(address(seacowsPairFactory), true);
        nft.setApprovalForAll(address(tokenPair), true);
        nft.setApprovalForAll(address(tradePair), true);

        token.approve(address(nftPair), 1000 ether);
        token.approve(address(tradePair), 1000 ether);
        vm.stopPrank();
    }

    function testEnableTokenPairProtocolFee() public {
        /** Enable protocol fee for the token pair */
        seacowsPairFactory.disableProtocolFee(tokenPair, false);

        /** Check protocol fee */
        uint256 protocolFeeMultiplier = seacowsPairFactory.protocolFeeMultiplier();
        assertEq(protocolFeeMultiplier, 5000000000000000);

        /** Alice sells NFTs to the token pair with protocol fee */
        vm.startPrank(alice);
        uint256[] memory nftIds = new uint256[](3);
        nftIds[0] = 12;
        nftIds[1] = 13;
        nftIds[2] = 14;

        uint256 aliceTokenBalance = token.balanceOf(alice);

        ISeacowsPairEnumerableERC20(address(tokenPair)).swapNFTsForToken(
            nftIds,
            new SeacowsRouter.NFTDetail[](0),
            25 ether,
            payable(alice),
            false,
            address(0)
        );
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
        seacowsPairFactory.disableProtocolFee(tokenPair, false);
        vm.stopPrank();
    }

    function testDisableTokenPairProtocolFee() public {
        /** Enable protocol fee for the token pair */
        seacowsPairFactory.disableProtocolFee(tokenPair, true);

        /** Check protocol fee */
        uint256 protocolFeeMultiplier = seacowsPairFactory.protocolFeeMultiplier();
        assertEq(protocolFeeMultiplier, 5000000000000000);

        /** Alice sells NFTs to the token pair without protocol fee */
        vm.startPrank(alice);
        uint256[] memory nftIds = new uint256[](3);
        nftIds[0] = 12;
        nftIds[1] = 13;
        nftIds[2] = 14;

        uint256 aliceTokenBalance = token.balanceOf(alice);

        ISeacowsPairEnumerableERC20(address(tokenPair)).swapNFTsForToken(
            nftIds,
            new SeacowsRouter.NFTDetail[](0),
            25 ether,
            payable(alice),
            false,
            address(0)
        );
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
        seacowsPairFactory.disableProtocolFee(tokenPair, true);
        vm.stopPrank();
    }

    function testEnableNFTPairProtocolFee() public {
        /** Enable protocol fee for the nft pair */
        seacowsPairFactory.disableProtocolFee(nftPair, false);

        /** Check protocol fee */
        uint256 protocolFeeMultiplier = seacowsPairFactory.protocolFeeMultiplier();
        assertEq(protocolFeeMultiplier, 5000000000000000);

        /** Alice buys NFTs to the nft pair with protocol fee */
        vm.startPrank(alice);
        uint256 aliceTokenBalance = token.balanceOf(alice);

        ISeacowsPairEnumerableERC20(address(nftPair)).swapTokenForAnyNFTs(2, 25 ether, payable(alice), false, address(0));
        /** Check alice token balance */
        uint256 aliceTokenBalanceUpdated = token.balanceOf(alice);
        assertEq(aliceTokenBalanceUpdated, aliceTokenBalance - 21.632625 ether);

        /** Check if nfts are transferred to the alice */
        assertEq(nft.balanceOf(alice), 12);

        vm.stopPrank();

        /** Non-owner is trying to update protocol recipient */
        vm.startPrank(alice);
        vm.expectRevert("Ownable: caller is not the owner");
        seacowsPairFactory.disableProtocolFee(nftPair, false);
        vm.stopPrank();
    }
}
