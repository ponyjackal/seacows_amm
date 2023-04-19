// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "forge-std/Test.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ICurve } from "../../bondingcurve/ICurve.sol";
import { IWETH } from "../../interfaces/IWETH.sol";
import { ISeacowsPairERC721 } from "../../interfaces/ISeacowsPairERC721.sol";

import { SeacowsPair } from "../../pairs/SeacowsPair.sol";
import { TestWETH } from "../../TestCollectionToken/TestWETH.sol";
import { TestERC20 } from "../../TestCollectionToken/TestERC20.sol";
import { TestERC721 } from "../../TestCollectionToken/TestERC721.sol";
import { TestERC721Enumerable } from "../../TestCollectionToken/TestERC721Enumerable.sol";
import { WhenCreatePair } from "../base/WhenCreatePair.t.sol";
import { SeacowsERC721Router } from "../../routers/SeacowsERC721Router.sol";

/// @dev See the "Writing Tests" section in the Foundry Book if this is your first time with Forge.
/// https://book.getfoundry.sh/forge/writing-tests
contract WhenSellNFTs is WhenCreatePair {
    SeacowsPair internal linearPair;
    SeacowsPair internal linearPairS3;
    SeacowsPair internal exponentialPair;

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
            nft.safeMint(alice);
        }
        nft.safeMint(owner);
        nft.safeMint(owner);

        /** Approve Bonding Curve */
        seacowsPairERC721Factory.setBondingCurveAllowed(linearCurve, true);
        seacowsPairERC721Factory.setBondingCurveAllowed(exponentialCurve, true);

        /** Create Linear Token Pair */
        vm.startPrank(owner);
        token.approve(address(seacowsPairERC721Factory), 1000 ether);
        nft.setApprovalForAll(address(seacowsPairERC721Factory), true);

        linearPair = createTokenPair(token, nft, linearCurve, payable(owner), 0.5 ether, 5 ether, new uint256[](0), 15 ether);
        linearPairS3 = createTokenPair(token, nft, linearCurve, payable(owner), 0.5 ether, 1 ether, new uint256[](0), 100 ether);

        /** Create Exponential Token Pair */
        exponentialPair = createTokenPair(token, nft, exponentialCurve, payable(owner), 1.1 ether, 5 ether, new uint256[](0), 50 ether);
        vm.stopPrank();

        /** enable/disable protocol fees */
        seacowsPairERC721Factory.disableProtocolFee(linearPair, false);
        seacowsPairERC721Factory.disableProtocolFee(linearPairS3, false);
        seacowsPairERC721Factory.disableProtocolFee(exponentialPair, true);

        vm.startPrank(alice);
        nft.setApprovalForAll(address(seacowsERC721Router), true);
        vm.stopPrank();
    }

    function testSellNFTsToLinearPair() public {
        /** Alice is trying to sell NFTs to nft pair */
        vm.startPrank(alice);

        uint256[] memory nftIds = new uint256[](2);
        nftIds[0] = 1;
        nftIds[1] = 2;

        uint256 tokenBalanceAlice = token.balanceOf(alice);
        uint256 tokenBalancePair = token.balanceOf(address(linearPair));

        SeacowsERC721Router.PairSwapSpecific memory param = SeacowsERC721Router.PairSwapSpecific(ISeacowsPairERC721(address(linearPair)), nftIds);
        seacowsERC721Router.swapNFTsForToken(param, 9 ether, payable(alice));

        /** Check nft owners */
        assertEq(nft.ownerOf(1), owner);
        assertEq(nft.ownerOf(2), owner);
        /** Check pair configs */
        assertEq(linearPair.spotPrice(), 4 ether);
        assertEq(linearPair.delta(), 0.5 ether);
        /** Check token balance update */
        uint256 updatedTokenBalanceAlice = token.balanceOf(alice);
        assertEq(updatedTokenBalanceAlice, tokenBalanceAlice + 9.4525 ether);

        uint256 updatedTokenBalancePair = token.balanceOf(address(linearPair));
        assertEq(updatedTokenBalancePair, tokenBalancePair - 9.5 ether);

        vm.stopPrank();
    }

    function testSellNFTsToExponentialPair() public {
        /** Alice is trying to sell NFTs to nft pair */
        vm.startPrank(alice);

        uint256[] memory nftIds = new uint256[](2);
        nftIds[0] = 1;
        nftIds[1] = 2;

        uint256 tokenBalanceAlice = token.balanceOf(alice);
        uint256 tokenBalancePair = token.balanceOf(address(exponentialPair));

        SeacowsERC721Router.PairSwapSpecific memory param = SeacowsERC721Router.PairSwapSpecific(
            ISeacowsPairERC721(address(exponentialPair)),
            nftIds
        );
        seacowsERC721Router.swapNFTsForToken(param, 9 ether, payable(alice));

        /** Check nft owners */
        assertEq(nft.ownerOf(1), owner);
        assertEq(nft.ownerOf(2), owner);
        /** Check pair configs */
        assertEq(exponentialPair.spotPrice(), 4.13223140495867768 ether);
        assertEq(exponentialPair.delta(), 1.1 ether);
        /** Check token balance update */
        uint256 updatedTokenBalanceAlice = token.balanceOf(alice);
        assertEq(updatedTokenBalanceAlice, tokenBalanceAlice + 9.54545454545454542 ether);

        uint256 updatedTokenBalancePair = token.balanceOf(address(exponentialPair));
        assertEq(updatedTokenBalancePair, tokenBalancePair - 9.54545454545454542 ether);

        vm.stopPrank();
    }

    function testSellNFTsPairInsufficientTokens() public {
        /** Alice is trying to sell NFTs to nft pair */
        vm.startPrank(alice);

        uint256[] memory nftIds = new uint256[](10);
        for (uint256 i; i < 10; i++) {
            nftIds[i] = i;
        }

        uint256 tokenBalanceAlice = token.balanceOf(alice);
        uint256 tokenBalancePair = token.balanceOf(address(linearPair));

        SeacowsERC721Router.PairSwapSpecific memory linearParam = SeacowsERC721Router.PairSwapSpecific(
            ISeacowsPairERC721(address(linearPair)),
            nftIds
        );

        vm.expectRevert("ERC20: transfer amount exceeds balance");
        seacowsERC721Router.swapNFTsForToken(linearParam, 9 ether, payable(alice));

        SeacowsERC721Router.PairSwapSpecific memory exponentialParam = SeacowsERC721Router.PairSwapSpecific(
            ISeacowsPairERC721(address(exponentialPair)),
            nftIds
        );
        vm.expectRevert("Out too little tokens");
        seacowsERC721Router.swapNFTsForToken(exponentialParam, 100 ether, payable(alice));

        vm.stopPrank();
    }

    function testSellNFTsPairZeroSpotPrice() public {
        /** Alice is trying to sell NFTs to nft pair */
        vm.startPrank(alice);

        uint256[] memory nftIds = new uint256[](10);
        for (uint256 i; i < 10; i++) {
            nftIds[i] = i;
        }

        SeacowsERC721Router.PairSwapSpecific memory param = SeacowsERC721Router.PairSwapSpecific(ISeacowsPairERC721(address(linearPairS3)), nftIds);

        vm.expectRevert();
        seacowsERC721Router.swapNFTsForToken(param, 1 ether, payable(alice));
        vm.stopPrank();
    }

    function testSellInvalidNFTs() public {
        /** Alice is trying to sell NFTs to nft pair */
        vm.startPrank(alice);

        uint256[] memory nftIds = new uint256[](2);
        nftIds[0] = 11;
        nftIds[1] = 12;

        SeacowsERC721Router.PairSwapSpecific memory param = SeacowsERC721Router.PairSwapSpecific(
            ISeacowsPairERC721(address(exponentialPair)),
            nftIds
        );

        vm.expectRevert("ERC721: caller is not token owner or approved");
        seacowsERC721Router.swapNFTsForToken(param, 9 ether, payable(alice));

        vm.stopPrank();
    }
}
