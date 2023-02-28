// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "forge-std/Test.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SeacowsRouter } from "../SeacowsRouter.sol";
import { SeacowsPairERC1155ERC20 } from "../SeacowsPairERC1155ERC20.sol";
import { TestSeacowsSFT } from "../TestCollectionToken/TestSeacowsSFT.sol";
import { TestERC20 } from "../TestCollectionToken/TestERC20.sol";
import { SeacowsPair } from "../SeacowsPair.sol";
import { ISeacowsPairERC1155ERC20 } from "../interfaces/ISeacowsPairERC1155ERC20.sol";
import { WhenCreatePair } from "./base/WhenCreatePair.t.sol";

/// @dev See the "Writing Tests" section in the Foundry Book if this is your first time with Forge.
/// https://book.getfoundry.sh/forge/writing-tests
contract TestSeacowsPairFactoryTest is WhenCreatePair {
    TestSeacowsSFT internal testSeacowsSFT;
    SeacowsPairERC1155ERC20 internal pair;
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

        // create a pair
        vm.startPrank(owner);
        token.approve(address(seacowsPairFactory), 1000000);
        testSeacowsSFT.setApprovalForAll(address(seacowsPairFactory), true);
        pair = createERC1155ERC20Pair(testSeacowsSFT, 1, 1000, token, 100000, 10);
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

    function testEnableProtocolFee() public {
        /** Check protocol fee */
        uint256 protocolFeeMultiplier = seacowsPairFactory.protocolFeeMultiplier();
        assertEq(protocolFeeMultiplier, 5000000000000000);

        /** check if protocol fee is enabled */
        vm.startPrank(alice);
        // approve erc1155 tokens to the pair
        testSeacowsSFT.setApprovalForAll(address(pair), true);
        // nft and token balance before swap
        uint256 tokenBeforeBalance = token.balanceOf(alice);
        uint256 sftBeforeBalance = testSeacowsSFT.balanceOf(alice, 1);
        // swap tokens for any nfts
        uint256 outputAmount = pair.swapNFTsForToken(new uint256[](100), new SeacowsRouter.NFTDetail[](0), 9950, payable(alice), false, address(0));
        // check balances after swap
        uint256 tokenAfterBalance = token.balanceOf(alice);
        uint256 sftAfterBalance = testSeacowsSFT.balanceOf(alice, 1);

        assertEq(tokenAfterBalance, tokenBeforeBalance + 9950);
        assertEq(sftAfterBalance, sftBeforeBalance - 100);

        vm.stopPrank();

        /** Factory disable protocol fee for the pair */
        seacowsPairFactory.disableProtocolFee(pair, true);
        /** Protocol fee should be the same */
        protocolFeeMultiplier = seacowsPairFactory.protocolFeeMultiplier();
        assertEq(protocolFeeMultiplier, 5000000000000000);

        /** check if protocol fee is disabled */
        vm.startPrank(alice);
        // approve erc1155 tokens to the pair
        testSeacowsSFT.setApprovalForAll(address(pair), true);
        // nft and token balance before swap
        tokenBeforeBalance = token.balanceOf(alice);
        sftBeforeBalance = testSeacowsSFT.balanceOf(alice, 1);
        // swap tokens for any nfts
        outputAmount = pair.swapNFTsForToken(new uint256[](100), new SeacowsRouter.NFTDetail[](0), 8000, payable(alice), false, address(0));
        // check balances after swap
        tokenAfterBalance = token.balanceOf(alice);
        sftAfterBalance = testSeacowsSFT.balanceOf(alice, 1);

        assertEq(tokenAfterBalance, tokenBeforeBalance + 8100);
        assertEq(sftAfterBalance, sftBeforeBalance - 100);

        vm.stopPrank();

        /** Non-owner is trying to update protocol recipient */
        vm.startPrank(alice);
        vm.expectRevert("Ownable: caller is not the owner");
        seacowsPairFactory.disableProtocolFee(pair, true);
        vm.stopPrank();
    }
}
