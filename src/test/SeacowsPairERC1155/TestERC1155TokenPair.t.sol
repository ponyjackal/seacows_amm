// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "forge-std/Test.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SeacowsPair } from "../../SeacowsPair.sol";
import { TestSeacowsSFT } from "../../TestCollectionToken/TestSeacowsSFT.sol";
import { TestERC20 } from "../../TestCollectionToken/TestERC20.sol";
import { SeacowsPairERC1155 } from "../../SeacowsPairERC1155.sol";
import { ISeacowsPairERC1155 } from "../../interfaces/ISeacowsPairERC1155.sol";
import { WhenCreatePair } from "../base/WhenCreatePair.t.sol";

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
        testSeacowsSFT.safeMint(owner);
        testSeacowsSFT.safeMint(alice);
        testSeacowsSFT.safeMint(bob);

        token = new TestERC20();
        token.mint(owner, 1e18);
        token.mint(alice, 1e18);
        token.mint(bob, 1e18);

        /** Approve Bonding Curve */
        seacowsPairFactory.setBondingCurveAllowed(linearCurve, true);
        seacowsPairFactory.setBondingCurveAllowed(exponentialCurve, true);

        vm.startPrank(owner);
        token.approve(address(seacowsPairFactory), 1000000);
        testSeacowsSFT.setApprovalForAll(address(seacowsPairFactory), true);
        vm.stopPrank();

        vm.startPrank(alice);
        token.approve(address(seacowsPairFactory), 1000000);
        testSeacowsSFT.setApprovalForAll(address(seacowsPairFactory), true);
        vm.stopPrank();

        vm.startPrank(bob);
        token.approve(address(seacowsPairFactory), 1000000);
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

        vm.expectRevert("Caller is not an admin");
        _linearPair.changeSpotPrice(0.5 ether);

        vm.expectRevert("Caller is not an admin");
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

        vm.expectRevert("Caller is not an admin");
        _exponentialPair.changeSpotPrice(0.5 ether);

        vm.expectRevert("Caller is not an admin");
        _exponentialPair.changeDelta(1.1 ether);

        vm.stopPrank();
    }
}
