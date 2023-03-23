// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "forge-std/Test.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { SeacowsPair } from "../../SeacowsPair.sol";
import { TestSeacowsSFT } from "../../TestCollectionToken/TestSeacowsSFT.sol";
import { TestERC20 } from "../../TestCollectionToken/TestERC20.sol";
import { SeacowsPairERC1155 } from "../../SeacowsPairERC1155.sol";
import { ISeacowsPairERC1155 } from "../../interfaces/ISeacowsPairERC1155.sol";
import { WhenCreatePair } from "../base/WhenCreatePair.t.sol";
import { ICurve } from "../../bondingcurve/ICurve.sol";
import { IWETH } from "../../interfaces/IWETH.sol";

/// @dev See the "Writing Tests" section in the Foundry Book if this is your first time with Forge.
/// https://book.getfoundry.sh/forge/writing-tests
contract TestERC1155TokenPair is WhenCreatePair {
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
        testSeacowsSFT.safeMint(alice, 3);
        testSeacowsSFT.safeMint(alice, 6);
        testSeacowsSFT.safeMint(alice, 9);

        testSeacowsSFT.safeMint(bob, 1);

        token = new TestERC20();
        token.mint(owner, 1000 ether);
        token.mint(alice, 1000 ether);
        token.mint(bob, 1000 ether);

        /** Approve Bonding Curve */
        seacowsPairFactory.setBondingCurveAllowed(linearCurve, true);
        seacowsPairFactory.setBondingCurveAllowed(exponentialCurve, true);

        vm.startPrank(owner);
        token.approve(address(seacowsPairFactory), 1000 ether);
        testSeacowsSFT.setApprovalForAll(address(seacowsPairFactory), true);
        vm.stopPrank();

        vm.startPrank(alice);
        token.approve(address(seacowsPairFactory), 1000 ether);
        testSeacowsSFT.setApprovalForAll(address(seacowsPairFactory), true);
        vm.stopPrank();

        vm.startPrank(bob);
        token.approve(address(seacowsPairFactory), 1000 ether);
        testSeacowsSFT.setApprovalForAll(address(seacowsPairFactory), true);
        vm.stopPrank();
    }

    function testLinearPair() public {
        vm.startPrank(owner);
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = 1;
        uint256[] memory nftAmounts = new uint256[](1);
        // create a linear pair
        SeacowsPair _linearPair = createERC1155ERC20TokenPair(
            testSeacowsSFT,
            nftIds,
            nftAmounts,
            linearCurve,
            payable(owner),
            token,
            100,
            0.1 ether,
            1 ether
        );
        linearPair = ISeacowsPairERC1155(address(_linearPair));

        address nft = linearPair.nft();
        assertEq(nft, address(testSeacowsSFT));

        uint256[] memory _nftIds = linearPair.getNFTIds();
        assertEq(_nftIds[0], 1);

        uint256 spotPrice = linearPair.spotPrice();
        assertEq(spotPrice, 1 ether);

        ERC20 _token = linearPair.token();
        assertEq(address(_token), address(token));

        SeacowsPair.PoolType poolType = linearPair.poolType();
        assertEq(uint256(poolType), uint256(SeacowsPair.PoolType.TOKEN));

        uint256 lpBalance = seacowsPairFactory.balanceOf(owner, seacowsPairFactory.pairTokenIds(address(linearPair)));
        assertEq(lpBalance, 0);

        assertEq(linearPair.delta(), 0.1 ether);
        assertEq(linearPair.fee(), 0);

        vm.stopPrank();
    }

    function testExponentialPair() public {
        vm.startPrank(owner);
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = 1;
        uint256[] memory nftAmounts = new uint256[](1);
        // create a exponential pair
        SeacowsPair _exponentialPair = createERC1155ETHTokenPair(
            testSeacowsSFT,
            nftIds,
            nftAmounts,
            exponentialCurve,
            payable(owner),
            100,
            1.1 ether,
            1 ether
        );
        exponentialPair = ISeacowsPairERC1155(address(_exponentialPair));

        address nft = exponentialPair.nft();
        assertEq(nft, address(testSeacowsSFT));

        uint256[] memory _nftIds = exponentialPair.getNFTIds();
        assertEq(_nftIds[0], 1);

        uint256 spotPrice = exponentialPair.spotPrice();
        assertEq(spotPrice, 1 ether);

        ERC20 _token = exponentialPair.token();
        assertEq(address(_token), address(weth));

        SeacowsPair.PoolType poolType = exponentialPair.poolType();
        assertEq(uint256(poolType), uint256(SeacowsPair.PoolType.TOKEN));

        uint256 lpBalance = seacowsPairFactory.balanceOf(owner, seacowsPairFactory.pairTokenIds(address(exponentialPair)));
        assertEq(lpBalance, 0);

        assertEq(exponentialPair.delta(), 1.1 ether);
        assertEq(exponentialPair.fee(), 0);
        vm.stopPrank();
    }

    function testLinearPairWithInvalidParams() public {
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = 1;
        uint256[] memory nftAmounts = new uint256[](1);

        vm.startPrank(owner);

        vm.expectRevert("Invalid delta for curve");
        createERC1155ERC20NFTPair(testSeacowsSFT, nftIds, nftAmounts, linearCurve, payable(owner), token, 100, 0 ether, 1 ether);

        vm.expectRevert("Invalid new spot price for curve");
        createERC1155ERC20NFTPair(testSeacowsSFT, nftIds, nftAmounts, linearCurve, payable(owner), token, 100, 0.1 ether, 0 ether);

        vm.stopPrank();
    }

    function testExponentialPairWithInvalidParams() public {
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = 1;
        uint256[] memory nftAmounts = new uint256[](1);

        vm.startPrank(owner);
        vm.expectRevert("Invalid delta for curve");
        createERC1155ETHTokenPair(testSeacowsSFT, nftIds, nftAmounts, exponentialCurve, payable(owner), 100, 0.1 ether, 1 ether);

        vm.expectRevert("Invalid new spot price for curve");
        createERC1155ETHTokenPair(testSeacowsSFT, nftIds, nftAmounts, exponentialCurve, payable(owner), 100, 1.1 ether, 1 * 10**8);

        vm.stopPrank();
    }

    function testConfigLinearPair() public {
        vm.startPrank(owner);
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = 1;
        uint256[] memory nftAmounts = new uint256[](1);
        // create a linear pair
        SeacowsPair _linearPair = createERC1155ERC20TokenPair(
            testSeacowsSFT,
            nftIds,
            nftAmounts,
            linearCurve,
            payable(owner),
            token,
            100,
            0.1 ether,
            1 ether
        );
        linearPair = ISeacowsPairERC1155(address(_linearPair));

        // Change spot price
        _linearPair.changeSpotPrice(0.5 ether);
        assertEq(_linearPair.spotPrice(), 0.5 ether);
        // Change delta
        _linearPair.changeDelta(0.1 ether);
        assertEq(_linearPair.delta(), 0.1 ether);

        // Revert with invalid params
        vm.expectRevert("Invalid new spot price for curve");
        _linearPair.changeSpotPrice(0);

        vm.expectRevert("Invalid delta for curve");
        _linearPair.changeDelta(0);

        vm.stopPrank();
        /** Non pair owner is tryig to spot price */
        vm.startPrank(alice);

        vm.expectRevert("Caller is not the owner");
        _linearPair.changeSpotPrice(0.5 ether);

        vm.expectRevert("Caller is not the owner");
        _linearPair.changeDelta(0.1 ether);

        vm.stopPrank();
    }

    function testConfigExponentialPair() public {
        vm.startPrank(owner);
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = 1;
        uint256[] memory nftAmounts = new uint256[](1);
        // create a exponential pair
        SeacowsPair _exponentialPair = createERC1155ETHTokenPair(
            testSeacowsSFT,
            nftIds,
            nftAmounts,
            exponentialCurve,
            payable(owner),
            100,
            1.1 ether,
            1 ether
        );
        exponentialPair = ISeacowsPairERC1155(address(_exponentialPair));

        // Change spot price
        _exponentialPair.changeSpotPrice(0.5 ether);
        assertEq(_exponentialPair.spotPrice(), 0.5 ether);
        // Change delta
        _exponentialPair.changeDelta(1.1 ether);
        assertEq(_exponentialPair.delta(), 1.1 ether);

        // Revert with invalid params
        vm.expectRevert("Invalid new spot price for curve");
        _exponentialPair.changeSpotPrice(0);

        vm.expectRevert("Invalid delta for curve");
        _exponentialPair.changeDelta(0);

        vm.stopPrank();
        /** Non pair owner is tryig to spot price */
        vm.startPrank(alice);

        vm.expectRevert("Caller is not the owner");
        _exponentialPair.changeSpotPrice(0.5 ether);

        vm.expectRevert("Caller is not the owner");
        _exponentialPair.changeDelta(1.1 ether);

        vm.stopPrank();
    }

    function testAddLiquidityLinearPair() public {
        vm.startPrank(owner);
        uint256[] memory nftIds = new uint256[](3);
        nftIds[0] = 1;
        nftIds[1] = 3;
        nftIds[2] = 6;

        uint256[] memory nftAmounts = new uint256[](3);
        // create a linear pair
        SeacowsPair _linearPair = createERC1155ETHTokenPair(
            testSeacowsSFT,
            nftIds,
            nftAmounts,
            linearCurve,
            payable(owner),
            14 ether,
            0.1 ether,
            5 ether
        );
        linearPair = ISeacowsPairERC1155(address(_linearPair));

        /** owner deposits ETH to erc721-weth pair */
        _linearPair.depositETH{ value: 4 ether }();
        /** check ETH balance */
        uint256 wethBalance = IWETH(weth).balanceOf(address(_linearPair));
        assertEq(wethBalance, 18 ether);
        /** check bonding curve */
        ICurve curve = _linearPair.bondingCurve();
        assertEq(address(curve), address(linearCurve));
        /** check delta */
        uint128 delta = _linearPair.delta();
        assertEq(delta, 0.1 ether);
        /** check spot price */
        uint128 spotPrice = _linearPair.spotPrice();
        assertEq(spotPrice, 5 ether);

        vm.stopPrank();

        /** alice is trying to deposit tokens */
        vm.startPrank(alice);
        vm.expectRevert("Not a pair owner");
        _linearPair.depositETH{ value: 4 ether }();
        vm.stopPrank();
    }

    function testAddLiquidityExponentialPair() public {
        vm.startPrank(owner);
        uint256[] memory nftIds = new uint256[](3);
        nftIds[0] = 1;
        nftIds[1] = 3;
        nftIds[2] = 6;

        uint256[] memory nftAmounts = new uint256[](3);
        // create a exponential pair
        SeacowsPair _exponentialPair = createERC1155ERC20TokenPair(
            testSeacowsSFT,
            nftIds,
            nftAmounts,
            exponentialCurve,
            payable(owner),
            token,
            100 ether,
            1.01 ether,
            20 ether
        );
        exponentialPair = ISeacowsPairERC1155(address(_exponentialPair));

        /** owner deposits token to erc721-erc20 token pair */
        token.approve(address(_exponentialPair), 1000 ether);
        _exponentialPair.depositERC20(120 ether);
        /** check token balance */
        uint256 tokenBalance = token.balanceOf(address(_exponentialPair));
        assertEq(tokenBalance, 220 ether);
        /** check bonding curve */
        ICurve curve = _exponentialPair.bondingCurve();
        assertEq(address(curve), address(exponentialCurve));
        /** check delta */
        uint128 delta = _exponentialPair.delta();
        assertEq(delta, 1.01 ether);
        /** check spot price */
        uint128 spotPrice = _exponentialPair.spotPrice();
        assertEq(spotPrice, 20 ether);
        vm.stopPrank();

        /** alice is trying to deposit tokens */
        vm.startPrank(alice);
        token.approve(address(_exponentialPair), 1000 ether);
        vm.expectRevert("Not a pair owner");
        _exponentialPair.depositERC20(100 ether);
        vm.stopPrank();
    }

    function testRemoveLiquidityLinearPair() public {
        vm.startPrank(owner);
        uint256[] memory nftIds = new uint256[](3);
        nftIds[0] = 1;
        nftIds[1] = 3;
        nftIds[2] = 6;

        uint256[] memory nftAmounts = new uint256[](3);
        // create a linear pair
        SeacowsPair _linearPair = createERC1155ETHTokenPair(
            testSeacowsSFT,
            nftIds,
            nftAmounts,
            linearCurve,
            payable(owner),
            14 ether,
            0.1 ether,
            5 ether
        );
        linearPair = ISeacowsPairERC1155(address(_linearPair));

        /** owner withdraws WETH from erc721-weth pair */
        _linearPair.withdrawERC20(owner, 4 ether);
        /** check ETH balance */
        uint256 wethBalance = IWETH(weth).balanceOf(address(_linearPair));
        assertEq(wethBalance, 10 ether);
        /** check bonding curve */
        ICurve curve = _linearPair.bondingCurve();
        assertEq(address(curve), address(linearCurve));
        /** check delta */
        uint128 delta = _linearPair.delta();
        assertEq(delta, 0.1 ether);
        /** check spot price */
        uint128 spotPrice = _linearPair.spotPrice();
        assertEq(spotPrice, 5 ether);

        /** owner is trying to withdraw to zero address */
        vm.expectRevert("Invalid address");
        _linearPair.withdrawERC20(address(0), 5 ether);

        /** owner is trying to withdraw zero amount */
        vm.expectRevert("Invalid amount");
        _linearPair.withdrawERC20(owner, 0 ether);

        /** owner is trying to withdraw too much amount */
        vm.expectRevert();
        _linearPair.withdrawERC20(owner, 100 ether);

        vm.stopPrank();

        /** alice is trying to withdraw WETH */
        vm.startPrank(alice);
        vm.expectRevert("Caller should be an owner");
        _linearPair.withdrawERC20(alice, 4 ether);
        vm.stopPrank();
    }

    function testRemoveLiquidityExponentialPair() public {
        vm.startPrank(owner);
        uint256[] memory nftIds = new uint256[](3);
        nftIds[0] = 1;
        nftIds[1] = 3;
        nftIds[2] = 6;

        uint256[] memory nftAmounts = new uint256[](3);
        // create a exponential pair
        SeacowsPair _exponentialPair = createERC1155ERC20TokenPair(
            testSeacowsSFT,
            nftIds,
            nftAmounts,
            exponentialCurve,
            payable(owner),
            token,
            100 ether,
            1.01 ether,
            20 ether
        );
        exponentialPair = ISeacowsPairERC1155(address(_exponentialPair));

        /** owner withdraws tokens from erc721-erc20 token pair */
        _exponentialPair.withdrawERC20(owner, 50 ether);
        /** check token balance */
        uint256 tokenBalance = token.balanceOf(address(_exponentialPair));
        assertEq(tokenBalance, 50 ether);
        /** check bonding curve */
        ICurve curve = _exponentialPair.bondingCurve();
        assertEq(address(curve), address(exponentialCurve));
        /** check delta */
        uint128 delta = _exponentialPair.delta();
        assertEq(delta, 1.01 ether);
        /** check spot price */
        uint128 spotPrice = _exponentialPair.spotPrice();
        assertEq(spotPrice, 20 ether);

        /** owner is trying to withdraw to zero address */
        vm.expectRevert("Invalid address");
        _exponentialPair.withdrawERC20(address(0), 100 ether);

        /** owner is trying to withdraw zero amount */
        vm.expectRevert("Invalid amount");
        _exponentialPair.withdrawERC20(owner, 0 ether);

        /** owner is trying to withdraw too much amount */
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        _exponentialPair.withdrawERC20(owner, 100 ether);

        vm.stopPrank();

        /** alice is trying to withdraw tokens */
        vm.startPrank(alice);
        vm.expectRevert("Caller should be an owner");
        _exponentialPair.withdrawERC20(alice, 100 ether);
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
        // approve erc1155 tokens to the pair
        testSeacowsSFT.setApprovalForAll(address(linearPair), true);
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

        uint256 outputAmount = linearPair.swapNFTsForToken(swapNFTIds, swapNFTAmounts, 4 ether, payable(alice));
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
        linearPair.swapNFTsForToken(swapLittleNFTIds, swapLittleNFTAmounts, 5 ether, payable(alice));

        // expect SPOT_PRICE_OVERFLOW
        swapLittleNFTAmounts[0] = 10;

        vm.expectRevert();
        linearPair.swapNFTsForToken(swapLittleNFTIds, swapLittleNFTAmounts, 5 ether, payable(alice));

        // trying to swap with invalid nft amount
        vm.expectRevert("Must ask for > 0 NFTs");
        uint256[] memory invalidNFTAmounts = new uint256[](2);
        invalidNFTAmounts[0] = 0;
        invalidNFTAmounts[1] = 0;
        linearPair.swapNFTsForToken(swapNFTIds, invalidNFTAmounts, 1 ether, payable(alice));

        // trying to swap with invalid nft ids
        vm.expectRevert("Invalid nft id");
        uint256[] memory invalidNFTIds = new uint256[](2);
        invalidNFTIds[0] = 2;
        invalidNFTIds[1] = 7;

        invalidNFTAmounts[0] = 10;
        invalidNFTAmounts[1] = 10;
        linearPair.swapNFTsForToken(invalidNFTIds, invalidNFTAmounts, 1 ether, payable(alice));

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
        seacowsPairFactory.disableProtocolFee(_exponentialPair, true);

        vm.startPrank(alice);
        // approve erc1155 tokens to the pair
        testSeacowsSFT.setApprovalForAll(address(exponentialPair), true);
        // nft and token balance before swap
        uint256 tokenBeforeBalance = IERC20(weth).balanceOf(alice);
        uint256 sftBeforeBalanceNine = testSeacowsSFT.balanceOf(alice, 9);
        // swap tokens for any nfts
        uint256[] memory swapNFTIds = new uint256[](1);
        swapNFTIds[0] = 9;
        uint256[] memory swapNFTAmounts = new uint256[](1);
        swapNFTAmounts[0] = 10;

        uint256 outputAmount = exponentialPair.swapNFTsForToken(swapNFTIds, swapNFTAmounts, 4 ether, payable(alice));
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
        exponentialPair.swapNFTsForToken(swapLittleNFTIds, swapLittleNFTAmounts, 5 ether, payable(alice));

        // trying to swap with invalid nft amount
        vm.expectRevert("Must ask for > 0 NFTs");
        uint256[] memory invalidNFTAmounts = new uint256[](1);
        invalidNFTAmounts[0] = 0;
        exponentialPair.swapNFTsForToken(swapNFTIds, invalidNFTAmounts, 1 ether, payable(alice));

        // trying to swap with invalid nft ids
        vm.expectRevert("Invalid nft id");
        uint256[] memory invalidNFTIds = new uint256[](1);
        invalidNFTIds[0] = 2;

        invalidNFTAmounts[0] = 10;
        exponentialPair.swapNFTsForToken(invalidNFTIds, invalidNFTAmounts, 1 ether, payable(alice));

        vm.stopPrank();
    }
}
