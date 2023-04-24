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
contract TestTestSeacowsERC1155RouterSell is WhenCreatePair {
    TestSeacowsSFT internal testSeacowsSFT;
    ISeacowsPairERC1155 internal linearPair;
    ISeacowsPairERC1155 internal exponentialPair;
    TestERC20 internal token;

    function setUp() public override(WhenCreatePair) {
        WhenCreatePair.setUp();

        // deploy sft contract
        testSeacowsSFT = new TestSeacowsSFT();
        testSeacowsSFT.safeMint(owner, 1);

        testSeacowsSFT.safeMint(alice, 1);
        testSeacowsSFT.safeMint(alice, 2);
        testSeacowsSFT.safeMint(alice, 3);
        testSeacowsSFT.safeMint(alice, 6);
        testSeacowsSFT.safeMint(alice, 9);

        testSeacowsSFT.safeMint(bob, 1);

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

    function testSwapNFTsForTokenLinearPair() public {
        vm.startPrank(owner);
        uint256[] memory nftIds = new uint256[](3);
        nftIds[0] = 1;
        nftIds[1] = 3;
        nftIds[2] = 6;
        uint256[] memory nftAmounts = new uint256[](3);
        // create a linear pair
        SeacowsPair _linearPair = createERC1155ERC20TokenPair(
            testSeacowsSFT,
            nftIds,
            nftAmounts,
            linearCurve,
            payable(owner),
            token,
            100 ether,
            0.5 ether,
            2 ether
        );
        linearPair = ISeacowsPairERC1155(address(_linearPair));

        vm.stopPrank();

        vm.startPrank(alice);
        // approve erc1155 tokens to the router
        testSeacowsSFT.setApprovalForAll(address(seacowsERC1155Router), true);
        // nft and token balance before swap
        uint256 tokenBeforeBalance = token.balanceOf(alice);
        uint256 sftBeforeBalanceOne = testSeacowsSFT.balanceOf(alice, 1);
        uint256 sftBeforeBalanceSix = testSeacowsSFT.balanceOf(alice, 6);
        // swap tokens for any nfts
        uint256[] memory swapNFTIds = new uint256[](2);
        swapNFTIds[0] = 1;
        swapNFTIds[1] = 6;
        uint256[] memory swapNFTAmounts = new uint256[](2);
        swapNFTAmounts[0] = 2;
        swapNFTAmounts[1] = 1;

        // create param
        SeacowsERC1155Router.PairSwap memory param = SeacowsERC1155Router.PairSwap(linearPair, swapNFTIds, swapNFTAmounts);

        uint256 outputAmount = seacowsERC1155Router.swapNFTsForToken(param, 4 ether, payable(alice));
        // check balances after swap
        uint256 tokenAfterBalance = token.balanceOf(alice);
        uint256 sftAfterBalanceOne = testSeacowsSFT.balanceOf(alice, 1);
        uint256 sftAfterBalanceSix = testSeacowsSFT.balanceOf(alice, 6);

        assertEq(tokenAfterBalance, tokenBeforeBalance + 4.4775 ether);
        assertEq(sftAfterBalanceOne, sftBeforeBalanceOne - 2);
        assertEq(sftAfterBalanceSix, sftBeforeBalanceSix - 1);

        // expect too much output tokens
        uint256[] memory swapLittleNFTIds = new uint256[](1);
        swapLittleNFTIds[0] = 1;
        uint256[] memory swapLittleNFTAmounts = new uint256[](1);
        swapLittleNFTAmounts[0] = 1;

        vm.expectRevert("Out too little tokens");
        // create param
        SeacowsERC1155Router.PairSwap memory paramLittleAmounts = SeacowsERC1155Router.PairSwap(linearPair, swapLittleNFTIds, swapLittleNFTAmounts);
        seacowsERC1155Router.swapNFTsForToken(paramLittleAmounts, 5 ether, payable(alice));

        // expect SPOT_PRICE_OVERFLOW
        swapLittleNFTAmounts[0] = 10;

        vm.expectRevert();
        // create param
        SeacowsERC1155Router.PairSwap memory paramLittleNFTAmounts = SeacowsERC1155Router.PairSwap(
            linearPair,
            swapLittleNFTIds,
            swapLittleNFTAmounts
        );
        seacowsERC1155Router.swapNFTsForToken(paramLittleNFTAmounts, 5 ether, payable(alice));

        // trying to swap with invalid nft amount
        vm.expectRevert("Must ask for > 0 NFTs");
        uint256[] memory invalidNFTAmounts = new uint256[](2);
        invalidNFTAmounts[0] = 0;
        invalidNFTAmounts[1] = 0;

        // create param
        SeacowsERC1155Router.PairSwap memory paramInvalidNFTAmounts = SeacowsERC1155Router.PairSwap(linearPair, swapNFTIds, invalidNFTAmounts);
        seacowsERC1155Router.swapNFTsForToken(paramInvalidNFTAmounts, 1 ether, payable(alice));

        // trying to swap with invalid nft ids
        vm.expectRevert("Invalid nft id");
        uint256[] memory invalidNFTIds = new uint256[](2);
        invalidNFTIds[0] = 2;
        invalidNFTIds[1] = 9;

        invalidNFTAmounts[0] = 10;
        invalidNFTAmounts[1] = 10;

        // create param
        SeacowsERC1155Router.PairSwap memory paramInvalidNFTIds = SeacowsERC1155Router.PairSwap(linearPair, invalidNFTIds, invalidNFTAmounts);
        seacowsERC1155Router.swapNFTsForToken(paramInvalidNFTIds, 1 ether, payable(alice));

        vm.stopPrank();
    }

    function testSwapNFTsForTokenExponentialPair() public {
        vm.startPrank(owner);

        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = 9;
        uint256[] memory nftAmounts = new uint256[](1);

        // create a exponential pair
        SeacowsPair _exponentialPair = createERC1155ETHTokenPair(
            testSeacowsSFT,
            nftIds,
            nftAmounts,
            exponentialCurve,
            payable(owner),
            100 ether,
            1.1 ether,
            5 ether
        );
        exponentialPair = ISeacowsPairERC1155(address(_exponentialPair));

        vm.stopPrank();

        // disable protocol fee
        seacowsPairERC1155Factory.disableProtocolFee(_exponentialPair, true);

        vm.startPrank(alice);
        // approve erc1155 tokens to the router
        testSeacowsSFT.setApprovalForAll(address(seacowsERC1155Router), true);
        // nft and token balance before swap
        uint256 tokenBeforeBalance = IERC20(weth).balanceOf(alice);
        uint256 sftBeforeBalanceNine = testSeacowsSFT.balanceOf(alice, 9);
        // swap tokens for any nfts
        uint256[] memory swapNFTIds = new uint256[](1);
        swapNFTIds[0] = 9;
        uint256[] memory swapNFTAmounts = new uint256[](1);
        swapNFTAmounts[0] = 10;

        // create param
        SeacowsERC1155Router.PairSwap memory param = SeacowsERC1155Router.PairSwap(exponentialPair, swapNFTIds, swapNFTAmounts);

        uint256 outputAmount = seacowsERC1155Router.swapNFTsForToken(param, 4 ether, payable(alice));
        // check balances after swap
        uint256 tokenAfterBalance = IERC20(weth).balanceOf(alice);
        uint256 sftAfterBalanceNine = testSeacowsSFT.balanceOf(alice, 9);

        assertEq(tokenAfterBalance, tokenBeforeBalance + 33.795119081375753685 ether);
        assertEq(sftAfterBalanceNine, sftBeforeBalanceNine - 10);

        // expect too much output tokens
        uint256[] memory swapLittleNFTIds = new uint256[](1);
        swapLittleNFTIds[0] = 9;
        uint256[] memory swapLittleNFTAmounts = new uint256[](1);
        swapLittleNFTAmounts[0] = 1;

        vm.expectRevert("Out too little tokens");
        SeacowsERC1155Router.PairSwap memory paramLittleNFTIds = SeacowsERC1155Router.PairSwap(
            exponentialPair,
            swapLittleNFTIds,
            swapLittleNFTAmounts
        );
        seacowsERC1155Router.swapNFTsForToken(paramLittleNFTIds, 5 ether, payable(alice));

        // trying to swap with invalid nft amount
        vm.expectRevert("Must ask for > 0 NFTs");
        uint256[] memory invalidNFTAmounts = new uint256[](1);
        invalidNFTAmounts[0] = 0;
        SeacowsERC1155Router.PairSwap memory paramInvalidNFTAmounts = SeacowsERC1155Router.PairSwap(exponentialPair, swapNFTIds, invalidNFTAmounts);
        seacowsERC1155Router.swapNFTsForToken(paramInvalidNFTAmounts, 1 ether, payable(alice));

        // trying to swap with invalid nft ids
        vm.expectRevert("Invalid nft id");
        uint256[] memory invalidNFTIds = new uint256[](1);
        invalidNFTIds[0] = 3;

        invalidNFTAmounts[0] = 10;

        SeacowsERC1155Router.PairSwap memory paramInvalidNFTIds = SeacowsERC1155Router.PairSwap(exponentialPair, invalidNFTIds, invalidNFTAmounts);
        seacowsERC1155Router.swapNFTsForToken(paramInvalidNFTIds, 1 ether, payable(alice));

        vm.stopPrank();
    }
}
