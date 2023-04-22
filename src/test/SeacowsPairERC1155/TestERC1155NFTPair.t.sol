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

/// @dev See the "Writing Tests" section in the Foundry Book if this is your first time with Forge.
/// https://book.getfoundry.sh/forge/writing-tests
contract TestERC1155NFTPair is WhenCreatePair {
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

    function testLinearPair() public {
        vm.startPrank(owner);
        // create a linear pair
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = 1;
        uint256[] memory nftAmounts = new uint256[](1);
        nftAmounts[0] = 1000;

        SeacowsPair _linearPair = createERC1155ERC20NFTPair(
            testSeacowsSFT,
            nftIds,
            nftAmounts,
            linearCurve,
            payable(owner),
            token,
            0,
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

        IERC20 _token = linearPair.token();
        assertEq(address(_token), address(token));

        SeacowsPair.PoolType poolType = linearPair.poolType();
        assertEq(uint256(poolType), uint256(SeacowsPair.PoolType.NFT));

        assertEq(linearPair.delta(), 0.1 ether);
        assertEq(linearPair.fee(), 0);

        vm.stopPrank();
    }

    function testExponentialPair() public {
        vm.startPrank(owner);
        // create a exponential pair
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = 1;
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
            1 ether
        );
        exponentialPair = ISeacowsPairERC1155(address(_exponentialPair));

        address nft = exponentialPair.nft();
        assertEq(nft, address(testSeacowsSFT));

        uint256[] memory _nftIds = exponentialPair.getNFTIds();
        assertEq(_nftIds[0], 1);

        uint256 spotPrice = exponentialPair.spotPrice();
        assertEq(spotPrice, 1 ether);

        IERC20 _token = exponentialPair.token();
        assertEq(address(_token), address(weth));

        SeacowsPair.PoolType poolType = exponentialPair.poolType();
        assertEq(uint256(poolType), uint256(SeacowsPair.PoolType.NFT));

        assertEq(exponentialPair.delta(), 1.1 ether);
        assertEq(exponentialPair.fee(), 0);
        vm.stopPrank();
    }

    function testLinearPairWithInvalidParams() public {
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = 1;
        uint256[] memory nftAmounts = new uint256[](1);
        nftAmounts[0] = 1000;

        vm.startPrank(owner);
        vm.expectRevert("Invalid delta for curve");
        createERC1155ERC20NFTPair(testSeacowsSFT, nftIds, nftAmounts, linearCurve, payable(owner), token, 0, 0 ether, 1 ether);

        vm.expectRevert("Invalid new spot price for curve");
        createERC1155ERC20NFTPair(testSeacowsSFT, nftIds, nftAmounts, linearCurve, payable(owner), token, 0, 0.1 ether, 0 ether);

        vm.stopPrank();
    }

    function testExponentialPairWithInvalidParams() public {
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = 1;
        uint256[] memory nftAmounts = new uint256[](1);
        nftAmounts[0] = 1000;

        vm.startPrank(owner);
        vm.expectRevert("Invalid delta for curve");
        createERC1155ETHNFTPair(testSeacowsSFT, nftIds, nftAmounts, exponentialCurve, payable(owner), 0, 0 ether, 1 ether);

        vm.expectRevert("Invalid new spot price for curve");
        createERC1155ETHNFTPair(testSeacowsSFT, nftIds, nftAmounts, exponentialCurve, payable(owner), 0, 1.1 ether, 0 ether);

        vm.stopPrank();
    }

    function testConfigLinearPair() public {
        vm.startPrank(owner);
        // create a linear pair
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = 1;
        uint256[] memory nftAmounts = new uint256[](1);
        nftAmounts[0] = 1000;

        SeacowsPair _linearPair = createERC1155ERC20NFTPair(
            testSeacowsSFT,
            nftIds,
            nftAmounts,
            linearCurve,
            payable(owner),
            token,
            0,
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
        // create a exponential pair
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = 1;
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

    function testDepositERC1155LinearPair() public {
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
            1 ether,
            5 ether
        );
        linearPair = ISeacowsPairERC1155(address(_linearPair));

        /** Deposit NFTs */
        uint256[] memory depositIds = new uint256[](2);
        depositIds[0] = 1;
        depositIds[1] = 3;
        uint256[] memory depositAmounts = new uint256[](2);
        depositAmounts[0] = 10;
        depositAmounts[1] = 1000;

        testSeacowsSFT.setApprovalForAll(address(linearPair), true);

        linearPair.depositERC1155(depositIds, depositAmounts);
        /** Check erc1155 nft balances */
        uint256 balanceOne = testSeacowsSFT.balanceOf(address(_linearPair), 1);
        assertEq(balanceOne, 20);
        uint256 balanceThree = testSeacowsSFT.balanceOf(address(_linearPair), 3);
        assertEq(balanceThree, 1000);
        uint256 balanceSix = testSeacowsSFT.balanceOf(address(_linearPair), 6);
        assertEq(balanceSix, 100);
        /** check bonding curve */
        ICurve curve = _linearPair.bondingCurve();
        assertEq(address(curve), address(linearCurve));
        /** check delta */
        uint128 delta = _linearPair.delta();
        assertEq(delta, 1 ether);
        /** check spot price */
        uint128 spotPrice = _linearPair.spotPrice();
        assertEq(spotPrice, 5 ether);

        /** Try to deposit invalid nft ids */
        uint256[] memory invalidIds = new uint256[](3);
        invalidIds[0] = 4;
        invalidIds[1] = 5;
        invalidIds[2] = 8;
        uint256[] memory invalidAmounts = new uint256[](3);
        invalidAmounts[0] = 10;
        invalidAmounts[1] = 100;
        invalidAmounts[2] = 1000;
        vm.expectRevert("Invalid nft id");
        linearPair.depositERC1155(invalidIds, invalidAmounts);

        vm.stopPrank();

        vm.startPrank(alice);
        testSeacowsSFT.setApprovalForAll(address(linearPair), true);

        vm.expectRevert("Caller is not the owner");
        linearPair.depositERC1155(depositIds, depositAmounts);
        vm.stopPrank();
    }

    function testDepositERC1155ExponentialPair() public {
        vm.startPrank(owner);
        // create a exponential pair
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = 9;
        uint256[] memory nftAmounts = new uint256[](1);
        nftAmounts[0] = 1000;

        SeacowsPair _exponentialPair = createERC1155ERC20NFTPair(
            testSeacowsSFT,
            nftIds,
            nftAmounts,
            exponentialCurve,
            payable(owner),
            token,
            0,
            1.05 ether,
            20 ether
        );
        exponentialPair = ISeacowsPairERC1155(address(_exponentialPair));

        /** Deposit NFTs */
        uint256[] memory depositIds = new uint256[](1);
        depositIds[0] = 9;
        uint256[] memory depositAmounts = new uint256[](1);
        depositAmounts[0] = 10;

        testSeacowsSFT.setApprovalForAll(address(exponentialPair), true);

        exponentialPair.depositERC1155(depositIds, depositAmounts);
        /** Check erc1155 nft balances */
        uint256 balanceNine = testSeacowsSFT.balanceOf(address(_exponentialPair), 9);
        assertEq(balanceNine, 1010);
        /** check bonding curve */
        ICurve curve = _exponentialPair.bondingCurve();
        assertEq(address(curve), address(exponentialCurve));
        /** check delta */
        uint128 delta = _exponentialPair.delta();
        assertEq(delta, 1.05 ether);
        /** check spot price */
        uint128 spotPrice = _exponentialPair.spotPrice();
        assertEq(spotPrice, 20 ether);

        /** Try to deposit invalid nft ids */
        uint256[] memory invalidIds = new uint256[](1);
        invalidIds[0] = 1;
        uint256[] memory invalidAmounts = new uint256[](1);
        invalidAmounts[0] = 10;
        vm.expectRevert("Invalid nft id");
        exponentialPair.depositERC1155(invalidIds, invalidAmounts);

        vm.stopPrank();

        vm.startPrank(alice);
        testSeacowsSFT.setApprovalForAll(address(exponentialPair), true);
        vm.expectRevert("Caller is not the owner");
        exponentialPair.depositERC1155(depositIds, depositAmounts);
        vm.stopPrank();
    }

    function testWithdrawERC1155LinearPair() public {
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
            1 ether,
            5 ether
        );
        linearPair = ISeacowsPairERC1155(address(_linearPair));

        /** Withdraw NFTs */
        uint256[] memory withdrawIds = new uint256[](2);
        withdrawIds[0] = 1;
        withdrawIds[1] = 6;
        uint256[] memory withdrawAmounts = new uint256[](2);
        withdrawAmounts[0] = 10;
        withdrawAmounts[1] = 40;

        linearPair.withdrawERC1155(owner, withdrawIds, withdrawAmounts);
        /** Check erc1155 nft balances */
        uint256 balanceOne = testSeacowsSFT.balanceOf(address(_linearPair), 1);
        assertEq(balanceOne, 0);
        uint256 balanceThree = testSeacowsSFT.balanceOf(address(_linearPair), 3);
        assertEq(balanceThree, 0);
        uint256 balanceSix = testSeacowsSFT.balanceOf(address(_linearPair), 6);
        assertEq(balanceSix, 60);
        /** check bonding curve */
        ICurve curve = _linearPair.bondingCurve();
        assertEq(address(curve), address(linearCurve));
        /** check delta */
        uint128 delta = _linearPair.delta();
        assertEq(delta, 1 ether);
        /** check spot price */
        uint128 spotPrice = _linearPair.spotPrice();
        assertEq(spotPrice, 5 ether);

        /** Try to deposit invalid nft ids */
        uint256[] memory invalidIds = new uint256[](3);
        invalidIds[0] = 4;
        invalidIds[1] = 5;
        invalidIds[2] = 8;
        uint256[] memory invalidAmounts = new uint256[](3);
        invalidAmounts[0] = 10;
        invalidAmounts[1] = 100;
        invalidAmounts[2] = 1000;
        vm.expectRevert("Invalid nft id");
        linearPair.withdrawERC1155(owner, invalidIds, invalidAmounts);

        vm.stopPrank();

        vm.startPrank(alice);
        vm.expectRevert("Caller is not the owner");
        linearPair.withdrawERC1155(alice, withdrawIds, withdrawAmounts);
        vm.stopPrank();
    }

    function testWithdrawERC1155ExponentialPair() public {
        vm.startPrank(owner);
        // create a exponential pair
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = 9;
        uint256[] memory nftAmounts = new uint256[](1);
        nftAmounts[0] = 1000;

        SeacowsPair _exponentialPair = createERC1155ERC20NFTPair(
            testSeacowsSFT,
            nftIds,
            nftAmounts,
            exponentialCurve,
            payable(owner),
            token,
            0,
            1.05 ether,
            20 ether
        );
        exponentialPair = ISeacowsPairERC1155(address(_exponentialPair));

        /** Withdraw NFTs */
        uint256[] memory withdrawIds = new uint256[](1);
        withdrawIds[0] = 9;
        uint256[] memory withdrawAmounts = new uint256[](1);
        withdrawAmounts[0] = 100;

        exponentialPair.withdrawERC1155(owner, withdrawIds, withdrawAmounts);
        /** Check erc1155 nft balances */
        uint256 balanceNine = testSeacowsSFT.balanceOf(address(_exponentialPair), 9);
        assertEq(balanceNine, 900);
        /** check bonding curve */
        ICurve curve = _exponentialPair.bondingCurve();
        assertEq(address(curve), address(exponentialCurve));
        /** check delta */
        uint128 delta = _exponentialPair.delta();
        assertEq(delta, 1.05 ether);
        /** check spot price */
        uint128 spotPrice = _exponentialPair.spotPrice();
        assertEq(spotPrice, 20 ether);

        /** Try to deposit invalid nft ids */
        uint256[] memory invalidIds = new uint256[](1);
        invalidIds[0] = 1;
        uint256[] memory invalidAmounts = new uint256[](1);
        invalidAmounts[0] = 10;
        vm.expectRevert("Invalid nft id");
        exponentialPair.withdrawERC1155(owner, invalidIds, invalidAmounts);

        vm.stopPrank();

        vm.startPrank(alice);
        vm.expectRevert("Caller is not the owner");
        exponentialPair.withdrawERC1155(alice, withdrawIds, withdrawAmounts);
        vm.stopPrank();
    }

    // function testSwapTokenForNFTsLinearPair() public {
    //     vm.startPrank(owner);
    //     // create a linear pair
    //     uint256[] memory nftIds = new uint256[](3);
    //     nftIds[0] = 1;
    //     nftIds[1] = 3;
    //     nftIds[2] = 6;

    //     uint256[] memory nftAmounts = new uint256[](3);
    //     nftAmounts[0] = 10;
    //     nftAmounts[1] = 0;
    //     nftAmounts[2] = 100;

    //     SeacowsPair _linearPair = createERC1155ERC20NFTPair(
    //         testSeacowsSFT,
    //         nftIds,
    //         nftAmounts,
    //         linearCurve,
    //         payable(owner),
    //         token,
    //         0,
    //         0.5 ether,
    //         5 ether
    //     );
    //     linearPair = ISeacowsPairERC1155(address(_linearPair));

    //     vm.stopPrank();

    //     vm.startPrank(alice);
    //     // approve erc20 tokens to the pair
    //     token.approve(address(linearPair), 1000 ether);
    //     // nft and token balance before swap
    //     uint256 tokenBeforeBalance = token.balanceOf(alice);
    //     uint256 sftBeforeBalanceOne = testSeacowsSFT.balanceOf(alice, 1);
    //     uint256 sftBeforeBalanceThree = testSeacowsSFT.balanceOf(alice, 3);
    //     uint256 sftBeforeBalanceSix = testSeacowsSFT.balanceOf(alice, 6);
    //     // swap tokens for any nfts
    //     uint256[] memory buyNFTIds = new uint256[](2);
    //     buyNFTIds[0] = 1;
    //     buyNFTIds[1] = 6;
    //     uint256[] memory buyNFTAmounts = new uint256[](2);
    //     buyNFTAmounts[0] = 1;
    //     buyNFTAmounts[1] = 2;

    //     linearPair.swapTokenForNFTs(buyNFTIds, buyNFTAmounts, 20 ether, alice);
    //     // check balances after swapd
    //     uint256 tokenAfterBalance = token.balanceOf(alice);
    //     uint256 sftAfterBalanceOne = testSeacowsSFT.balanceOf(alice, 1);
    //     uint256 sftAfterBalanceThree = testSeacowsSFT.balanceOf(alice, 3);
    //     uint256 sftAfterBalanceSix = testSeacowsSFT.balanceOf(alice, 6);

    //     assertEq(tokenAfterBalance, tokenBeforeBalance - 18 ether);
    //     assertEq(sftAfterBalanceOne, sftBeforeBalanceOne + 1);
    //     assertEq(sftAfterBalanceThree, sftBeforeBalanceThree);
    //     assertEq(sftAfterBalanceSix, sftBeforeBalanceSix + 2);
    //     // check spot price
    //     assertEq(linearPair.spotPrice(), 6.5 ether);

    //     // trying to swap with insufficient amount of tokens
    //     vm.expectRevert("In too many tokens");
    //     linearPair.swapTokenForNFTs(buyNFTIds, buyNFTAmounts, 10 ether, alice);

    //     // trying to swap with invalid ids
    //     uint256[] memory invalidBuyNFTIds = new uint256[](2);
    //     invalidBuyNFTIds[0] = 5;
    //     invalidBuyNFTIds[1] = 8;

    //     vm.expectRevert("Invalid nft id");
    //     linearPair.swapTokenForNFTs(invalidBuyNFTIds, buyNFTAmounts, 20 ether, alice);

    //     // trying to swap with invalid nft amount
    //     vm.expectRevert("Invalid nft amount");
    //     uint256[] memory invalidNftAmounts = new uint256[](2);
    //     invalidNftAmounts[0] = 0;
    //     invalidNftAmounts[1] = 0;

    //     linearPair.swapTokenForNFTs(buyNFTIds, invalidNftAmounts, 20 ether, alice);

    //     vm.stopPrank();
    // }

    // function testSwapTokenForNFTsExponentialPair() public {
    //     vm.startPrank(owner);
    //     // create a exponential pair
    //     uint256[] memory nftIds = new uint256[](1);
    //     nftIds[0] = 9;
    //     uint256[] memory nftAmounts = new uint256[](1);
    //     nftAmounts[0] = 1000;

    //     SeacowsPair _exponentialPair = createERC1155ETHNFTPair(
    //         testSeacowsSFT,
    //         nftIds,
    //         nftAmounts,
    //         exponentialCurve,
    //         payable(owner),
    //         0,
    //         1.1 ether,
    //         5 ether
    //     );
    //     exponentialPair = ISeacowsPairERC1155(address(_exponentialPair));
    //     vm.stopPrank();

    //     // disable protocol fee
    //     seacowsPairERC1155Factory.disableProtocolFee(_exponentialPair, true);

    //     vm.startPrank(alice);
    //     // deposit eth for weth
    //     IWETH(weth).deposit{ value: 100 ether }();
    //     // approve erc20 tokens to the pair
    //     IERC20(weth).approve(address(exponentialPair), 100 ether);
    //     // nft and token balance before swap
    //     uint256 tokenBeforeBalance = IERC20(weth).balanceOf(alice);
    //     uint256 sftBeforeBalanceNine = testSeacowsSFT.balanceOf(alice, 9);
    //     // swap tokens for any nfts
    //     uint256[] memory buyNFTIds = new uint256[](1);
    //     buyNFTIds[0] = 9;
    //     uint256[] memory buyNFTAmounts = new uint256[](1);
    //     buyNFTAmounts[0] = 5;

    //     exponentialPair.swapTokenForNFTs(buyNFTIds, buyNFTAmounts, 35 ether, alice);
    //     // check balances after swapd
    //     uint256 tokenAfterBalance = IERC20(weth).balanceOf(alice);
    //     uint256 sftAfterBalanceNine = testSeacowsSFT.balanceOf(alice, 9);

    //     assertEq(tokenAfterBalance, tokenBeforeBalance - 33.57805 ether);
    //     assertEq(sftAfterBalanceNine, sftBeforeBalanceNine + 5);
    //     // check spot price
    //     assertEq(exponentialPair.spotPrice(), 8.05255 ether);

    //     // trying to swap with insufficient amount of tokens
    //     vm.expectRevert("In too many tokens");
    //     exponentialPair.swapTokenForNFTs(buyNFTIds, buyNFTAmounts, 10 ether, alice);

    //     // trying to swap with invalid ids
    //     uint256[] memory invalidBuyNFTIds = new uint256[](1);
    //     invalidBuyNFTIds[0] = 5;

    //     vm.expectRevert("Invalid nft id");
    //     exponentialPair.swapTokenForNFTs(invalidBuyNFTIds, buyNFTAmounts, 35 ether, alice);

    //     // trying to swap with invalid nft amount
    //     vm.expectRevert("Invalid nft amount");
    //     uint256[] memory invalidNftAmounts = new uint256[](1);
    //     invalidNftAmounts[0] = 0;

    //     exponentialPair.swapTokenForNFTs(buyNFTIds, invalidNftAmounts, 35 ether, alice);

    //     vm.stopPrank();
    // }
}
