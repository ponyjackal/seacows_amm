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
contract TestERC1155ERC20TradePair is WhenCreatePair {
    TestSeacowsSFT internal testSeacowsSFT;
    ISeacowsPairERC1155 internal pair;
    TestERC20 internal token;

    function setUp() public override(WhenCreatePair) {
        WhenCreatePair.setUp();

        // deploy sft contract
        testSeacowsSFT = new TestSeacowsSFT();
        testSeacowsSFT.safeMint(owner, 1);
        testSeacowsSFT.safeMint(alice, 1);
        testSeacowsSFT.safeMint(bob, 1);

        token = new TestERC20();
        token.mint(owner, 1e18);
        token.mint(alice, 1e18);
        token.mint(bob, 1e18);

        /** Approve Bonding Curve */
        seacowsPairFactory.setBondingCurveAllowed(cpmmCurve, true);

        // create a pair
        vm.startPrank(owner);
        token.approve(address(seacowsPairFactory), 1000000);
        testSeacowsSFT.setApprovalForAll(address(seacowsPairFactory), true);

        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = 1;
        uint256[] memory nftAmounts = new uint256[](1);
        nftAmounts[0] = 1000;

        SeacowsPair _pair = createERC1155ERC20TradePair(testSeacowsSFT, nftIds, nftAmounts, token, 100000, 10);
        pair = ISeacowsPairERC1155(address(_pair));
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

    function test_create_erc20_pair() public {
        address nft = pair.nft();
        assertEq(nft, address(testSeacowsSFT));

        uint256[] memory nftId = pair.getNFTIds();
        assertEq(nftId[0], 1);

        uint256 spotPrice = pair.spotPrice();
        assertEq(spotPrice, 100);

        ERC20 _token = pair.token();
        assertEq(address(_token), address(token));

        SeacowsPair.PoolType poolType = pair.poolType();
        assertEq(uint256(poolType), uint256(SeacowsPair.PoolType.TRADE));

        uint256 lpBalance = seacowsPairFactory.balanceOf(owner, 1);
        assertEq(lpBalance, 1000);
    }

    function test_add_liquidity() public {
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = 1;
        uint256[] memory nftAmounts = new uint256[](1);
        nftAmounts[0] = 100;

        vm.startPrank(alice);

        seacowsPairFactory.addLiquidityERC1155ERC20(ISeacowsPairERC1155(address(pair)), nftIds, nftAmounts, 10000);
        // check LP token balance
        uint256 lpBalance = seacowsPairFactory.balanceOf(alice, seacowsPairFactory.pairTokenIds(address(pair)));
        assertEq(lpBalance, 100);
        // check pair erc20 token balance
        uint256 tokenBalance = token.balanceOf(address(pair));
        assertEq(tokenBalance, 110000);
        // check pair erc1155 balance
        uint256 sftBalance = testSeacowsSFT.balanceOf(address(pair), 1);
        assertEq(sftBalance, 1100);
        // check spot price
        uint256 spotPrice = ISeacowsPairERC1155(address(pair)).spotPrice();
        assertEq(spotPrice, 100);

        // revert cases
        vm.expectRevert("Invalid token amount based on spot price");
        seacowsPairFactory.addLiquidityERC1155ERC20(ISeacowsPairERC1155(address(pair)), nftIds, nftAmounts, 100);

        vm.expectRevert("Invalid NFT amount");
        nftAmounts[0] = 0;
        seacowsPairFactory.addLiquidityERC1155ERC20(ISeacowsPairERC1155(address(pair)), nftIds, nftAmounts, 10000);

        vm.stopPrank();
    }

    function test_remove_liquidity() public {
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = 1;
        uint256[] memory nftAmounts = new uint256[](1);
        nftAmounts[0] = 100;

        vm.startPrank(alice);

        seacowsPairFactory.addLiquidityERC1155ERC20(ISeacowsPairERC1155(address(pair)), nftIds, nftAmounts, 10000);

        uint256[] memory newNFTAmounts = new uint256[](1);
        newNFTAmounts[0] = 10;

        seacowsPairFactory.removeLiquidityERC1155ERC20(ISeacowsPairERC1155(address(pair)), nftIds, newNFTAmounts, false);

        // check pair erc20 token balance
        uint256 tokenBalance = token.balanceOf(address(pair));
        assertEq(tokenBalance, 109000);
        // check pair erc1155 balance
        uint256 sftBalance = testSeacowsSFT.balanceOf(address(pair), 1);
        assertEq(sftBalance, 1090);
        // check LP token balance
        uint256 lpBalance = seacowsPairFactory.balanceOf(alice, 1);
        assertEq(lpBalance, 90);
        // check spot price
        uint256 spotPrice = ISeacowsPairERC1155(address(pair)).spotPrice();
        assertEq(spotPrice, 100);
        // trying to remove invalid LP token
        vm.expectRevert("ERC1155: burn amount exceeds balance");
        seacowsPairFactory.removeLiquidityERC1155ERC20(ISeacowsPairERC1155(address(pair)), nftIds, nftAmounts, false);

        vm.stopPrank();
    }

    function test_swap_any_nfts() public {
        vm.startPrank(alice);
        // approve erc20 tokens to the pair
        token.approve(address(pair), 1000000);
        // nft and token balance before swap
        uint256 tokenBeforeBalance = token.balanceOf(alice);
        uint256 sftBeforeBalance = testSeacowsSFT.balanceOf(alice, 1);
        // swap tokens for any nfts
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = 1;
        uint256[] memory nftAmounts = new uint256[](1);
        nftAmounts[0] = 100;
        pair.swapTokenForNFTs(nftIds, nftAmounts, 10150, alice);
        // check balances after swap
        uint256 tokenAfterBalance = token.balanceOf(alice);
        uint256 sftAfterBalance = testSeacowsSFT.balanceOf(alice, 1);

        assertEq(tokenAfterBalance, tokenBeforeBalance - 10050);
        assertEq(sftAfterBalance, sftBeforeBalance + 100);

        // trying to swap with insufficient amount of tokens
        vm.expectRevert("In too many tokens");
        pair.swapTokenForNFTs(nftIds, nftAmounts, 10150, alice);

        // trying to swap with invalid nft amount
        vm.expectRevert("Invalid nft amount");
        uint256[] memory invalidNftAmounts = new uint256[](1);
        invalidNftAmounts[0] = 0;
        pair.swapTokenForNFTs(nftIds, invalidNftAmounts, 10150, alice);

        vm.stopPrank();
    }

    function test_swap_tokens() public {
        vm.startPrank(alice);
        // approve erc1155 tokens to the pair
        testSeacowsSFT.setApprovalForAll(address(pair), true);
        // nft and token balance before swap
        uint256 tokenBeforeBalance = token.balanceOf(alice);
        uint256 sftBeforeBalance = testSeacowsSFT.balanceOf(alice, 1);
        // swap tokens for any nfts
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = 1;
        uint256[] memory nftAmounts = new uint256[](1);
        nftAmounts[0] = 100;
        uint256 outputAmount = pair.swapNFTsForToken(nftIds, nftAmounts, 9950, payable(alice));
        // check balances after swap
        uint256 tokenAfterBalance = token.balanceOf(alice);
        uint256 sftAfterBalance = testSeacowsSFT.balanceOf(alice, 1);

        assertEq(tokenAfterBalance, tokenBeforeBalance + 9950);
        assertEq(sftAfterBalance, sftBeforeBalance - 100);

        // expect too much output tokens
        vm.expectRevert("Out too little tokens");
        pair.swapNFTsForToken(nftIds, nftAmounts, 9950, payable(alice));

        // trying to swap with invalid nft amount
        vm.expectRevert("Must ask for > 0 NFTs");
        uint256[] memory invalidNftAmounts = new uint256[](1);
        invalidNftAmounts[0] = 0;
        pair.swapNFTsForToken(nftIds, invalidNftAmounts, 9950, payable(alice));

        vm.stopPrank();
    }
}
