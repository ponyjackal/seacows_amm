// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "forge-std/Test.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SeacowsRouter } from "../../SeacowsRouter.sol";
import { SeacowsPair } from "../../SeacowsPair.sol";
import { TestSeacowsSFT } from "../../TestCollectionToken/TestSeacowsSFT.sol";
import { TestERC20 } from "../../TestCollectionToken/TestERC20.sol";
import { SeacowsPairERC1155 } from "../../SeacowsPairERC1155.sol";
import { ISeacowsPairERC1155 } from "../../interfaces/ISeacowsPairERC1155.sol";
import { WhenCreatePair } from "../base/WhenCreatePair.t.sol";

/// @dev See the "Writing Tests" section in the Foundry Book if this is your first time with Forge.
/// https://book.getfoundry.sh/forge/writing-tests
contract SeacowsPairERC1155Test is WhenCreatePair {
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

        ERC20 _token = linearPair.token();
        assertEq(address(_token), address(token));

        SeacowsPair.PoolType poolType = linearPair.poolType();
        assertEq(uint256(poolType), uint256(SeacowsPair.PoolType.NFT));

        uint256 lpBalance = linearPair.balanceOf(owner, 1);
        assertEq(lpBalance, 0);

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

        ERC20 _token = exponentialPair.token();
        assertEq(address(_token), address(weth));

        SeacowsPair.PoolType poolType = exponentialPair.poolType();
        assertEq(uint256(poolType), uint256(SeacowsPair.PoolType.NFT));

        uint256 lpBalance = exponentialPair.balanceOf(owner, 1);
        assertEq(lpBalance, 0);

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
}
