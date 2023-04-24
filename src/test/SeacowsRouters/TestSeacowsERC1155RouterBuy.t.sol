// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "forge-std/Test.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { SeacowsPair } from "../../pairs/SeacowsPair.sol";
import { TestSeacowsSFT } from "../../TestCollectionToken/TestSeacowsSFT.sol";
import { TestERC20 } from "../../TestCollectionToken/TestERC20.sol";
import { SeacowsPairERC1155 } from "../../pairs/SeacowsPairERC1155.sol";
import { ISeacowsPairERC1155 } from "../../interfaces/ISeacowsPairERC1155.sol";
import { WhenCreatePair } from "../base/WhenCreatePair.t.sol";
import { ICurve } from "../../bondingcurve/ICurve.sol";
import { IWETH } from "../../interfaces/IWETH.sol";
import { SeacowsERC1155Router } from "../../routers/SeacowsERC1155Router.sol";

/// @dev See the "Writing Tests" section in the Foundry Book if this is your first time with Forge.
/// https://book.getfoundry.sh/forge/writing-tests
contract TestTestSeacowsERC1155RouterBuy is WhenCreatePair {
    TestSeacowsSFT internal testSeacowsSFT;
    ISeacowsPairERC1155 internal linearPair;
    ISeacowsPairERC1155 internal exponentialPair;
    TestERC20 internal token;

    function setUp() public override(WhenCreatePair) {
        WhenCreatePair.setUp();

        // deploy sft contract
        testSeacowsSFT = new TestSeacowsSFT();
        for (uint256 i; i < 10; i++) {
            testSeacowsSFT.safeMint(owner, i);
            testSeacowsSFT.safeMint(alice, i);
            testSeacowsSFT.safeMint(bob, i);
        }

        token = new TestERC20();
        token.mint(owner, 1000 ether);
        token.mint(alice, 1000 ether);
        token.mint(bob, 1000 ether);

        /** Approve Bonding Curve */
        seacowsPairERC1155Factory.setBondingCurveAllowed(linearCurve, true);
        seacowsPairERC1155Factory.setBondingCurveAllowed(exponentialCurve, true);

        vm.startPrank(owner);
        token.approve(address(seacowsPairERC1155Factory), 1000 ether);
        testSeacowsSFT.setApprovalForAll(address(seacowsPairERC1155Factory), true);
        vm.stopPrank();

        vm.startPrank(alice);
        token.approve(address(seacowsPairERC1155Factory), 1000 ether);
        testSeacowsSFT.setApprovalForAll(address(seacowsPairERC1155Factory), true);
        vm.stopPrank();

        vm.startPrank(bob);
        token.approve(address(seacowsPairERC1155Factory), 1000 ether);
        testSeacowsSFT.setApprovalForAll(address(seacowsPairERC1155Factory), true);
        vm.stopPrank();
    }

    function testSwapTokenForNFTsLinearPair() public {
        vm.startPrank(owner);
        // create a linear pair
        uint256[] memory nftIds = new uint256[](3);
        nftIds[0] = 1;
        nftIds[1] = 3;
        nftIds[2] = 6;

        uint256[] memory nftAmounts = new uint256[](3);
        nftAmounts[0] = 10;
        nftAmounts[1] = 0;
        nftAmounts[2] = 100;

        SeacowsPair _linearPair = createERC1155ERC20NFTPair(
            testSeacowsSFT,
            nftIds,
            nftAmounts,
            linearCurve,
            payable(owner),
            token,
            0,
            0.5 ether,
            5 ether
        );
        linearPair = ISeacowsPairERC1155(address(_linearPair));

        vm.stopPrank();

        vm.startPrank(alice);
        // approve erc20 tokens to the router
        token.approve(address(seacowsERC1155Router), 1000 ether);
        // nft and token balance before swap
        uint256 tokenBeforeBalance = token.balanceOf(alice);
        uint256 sftBeforeBalanceOne = testSeacowsSFT.balanceOf(alice, 1);
        uint256 sftBeforeBalanceThree = testSeacowsSFT.balanceOf(alice, 3);
        uint256 sftBeforeBalanceSix = testSeacowsSFT.balanceOf(alice, 6);
        // swap tokens for any nfts
        uint256[] memory buyNFTIds = new uint256[](2);
        buyNFTIds[0] = 1;
        buyNFTIds[1] = 6;
        uint256[] memory buyNFTAmounts = new uint256[](2);
        buyNFTAmounts[0] = 1;
        buyNFTAmounts[1] = 2;
        SeacowsERC1155Router.PairSwap[] memory params = new SeacowsERC1155Router.PairSwap[](1);
        params[0] = SeacowsERC1155Router.PairSwap(linearPair, buyNFTIds, buyNFTAmounts);
        seacowsERC1155Router.swapTokenForNFTs(params, 20 ether, alice);
        // check balances after swapd
        uint256 tokenAfterBalance = token.balanceOf(alice);
        uint256 sftAfterBalanceOne = testSeacowsSFT.balanceOf(alice, 1);
        uint256 sftAfterBalanceThree = testSeacowsSFT.balanceOf(alice, 3);
        uint256 sftAfterBalanceSix = testSeacowsSFT.balanceOf(alice, 6);

        assertEq(tokenAfterBalance, tokenBeforeBalance - 18 ether);
        assertEq(sftAfterBalanceOne, sftBeforeBalanceOne + 1);
        assertEq(sftAfterBalanceThree, sftBeforeBalanceThree);
        assertEq(sftAfterBalanceSix, sftBeforeBalanceSix + 2);
        // check spot price
        assertEq(linearPair.spotPrice(), 6.5 ether);

        // trying to swap with insufficient amount of tokens
        vm.expectRevert("In too many tokens");
        seacowsERC1155Router.swapTokenForNFTs(params, 10 ether, alice);

        // trying to swap with invalid ids
        vm.expectRevert("Invalid nft id");
        uint256[] memory invalidBuyNFTIds = new uint256[](2);
        invalidBuyNFTIds[0] = 5;
        invalidBuyNFTIds[1] = 8;
        SeacowsERC1155Router.PairSwap[] memory paramInvalidIds = new SeacowsERC1155Router.PairSwap[](1);
        paramInvalidIds[0] = SeacowsERC1155Router.PairSwap(linearPair, invalidBuyNFTIds, buyNFTAmounts);
        seacowsERC1155Router.swapTokenForNFTs(paramInvalidIds, 20 ether, alice);

        // trying to swap with invalid nft amount
        vm.expectRevert("Invalid nft amount");
        uint256[] memory invalidNftAmounts = new uint256[](2);
        invalidNftAmounts[0] = 0;
        invalidNftAmounts[1] = 0;
        SeacowsERC1155Router.PairSwap[] memory paramInvalidAmounts = new SeacowsERC1155Router.PairSwap[](1);
        paramInvalidAmounts[0] = SeacowsERC1155Router.PairSwap(linearPair, buyNFTIds, invalidNftAmounts);
        seacowsERC1155Router.swapTokenForNFTs(paramInvalidAmounts, 20 ether, alice);

        vm.stopPrank();
    }

    function testSwapTokenForNFTsExponentialPair() public {
        vm.startPrank(owner);
        // create a exponential pair
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = 9;
        uint256[] memory nftAmounts = new uint256[](1);
        nftAmounts[0] = 1000;

        SeacowsPair _exponentialPair = createERC1155ETHNFTPair(
            testSeacowsSFT,
            nftIds,
            nftAmounts,
            exponentialCurve,
            payable(owner),
            0,
            1.1 ether,
            5 ether
        );
        exponentialPair = ISeacowsPairERC1155(address(_exponentialPair));
        vm.stopPrank();

        // disable protocol fee
        seacowsPairERC1155Factory.disableProtocolFee(_exponentialPair, true);

        vm.startPrank(alice);
        // deposit eth for weth
        IWETH(weth).deposit{ value: 100 ether }();
        // approve erc20 tokens to the router
        IERC20(weth).approve(address(seacowsERC1155Router), 100 ether);
        // nft and token balance before swap
        uint256 tokenBeforeBalance = IERC20(weth).balanceOf(alice);
        uint256 sftBeforeBalanceNine = testSeacowsSFT.balanceOf(alice, 9);
        // swap tokens for any nfts
        uint256[] memory buyNFTIds = new uint256[](1);
        buyNFTIds[0] = 9;
        uint256[] memory buyNFTAmounts = new uint256[](1);
        buyNFTAmounts[0] = 5;

        // create param
        SeacowsERC1155Router.PairSwap[] memory params = new SeacowsERC1155Router.PairSwap[](1);
        params[0] = SeacowsERC1155Router.PairSwap(exponentialPair, buyNFTIds, buyNFTAmounts);
        seacowsERC1155Router.swapTokenForNFTs(params, 35 ether, alice);
        // check balances after swapd
        uint256 tokenAfterBalance = IERC20(weth).balanceOf(alice);
        uint256 sftAfterBalanceNine = testSeacowsSFT.balanceOf(alice, 9);

        assertEq(tokenAfterBalance, tokenBeforeBalance - 33.57805 ether);
        assertEq(sftAfterBalanceNine, sftBeforeBalanceNine + 5);
        // check spot price
        assertEq(exponentialPair.spotPrice(), 8.05255 ether);

        // trying to swap with insufficient amount of tokens
        vm.expectRevert("In too many tokens");
        // create param
        seacowsERC1155Router.swapTokenForNFTs(params, 10 ether, alice);

        // trying to swap with invalid ids
        vm.expectRevert("Invalid nft id");
        uint256[] memory invalidBuyNFTIds = new uint256[](1);
        invalidBuyNFTIds[0] = 5;
        SeacowsERC1155Router.PairSwap[] memory paramInvalidIds = new SeacowsERC1155Router.PairSwap[](1);
        paramInvalidIds[0] = SeacowsERC1155Router.PairSwap(exponentialPair, invalidBuyNFTIds, buyNFTAmounts);
        seacowsERC1155Router.swapTokenForNFTs(paramInvalidIds, 35 ether, alice);

        // trying to swap with invalid nft amount
        vm.expectRevert("Invalid nft amount");
        uint256[] memory invalidNftAmounts = new uint256[](1);
        invalidNftAmounts[0] = 0;
        SeacowsERC1155Router.PairSwap[] memory paramInvalidAmounts = new SeacowsERC1155Router.PairSwap[](1);
        paramInvalidAmounts[0] = SeacowsERC1155Router.PairSwap(exponentialPair, buyNFTIds, invalidNftAmounts);
        seacowsERC1155Router.swapTokenForNFTs(paramInvalidAmounts, 35 ether, alice);

        vm.stopPrank();
    }
}
