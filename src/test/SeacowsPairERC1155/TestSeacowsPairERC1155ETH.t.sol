// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "forge-std/Test.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SeacowsPairERC1155ERC20 } from "../../SeacowsPairERC1155ERC20.sol";
import { TestSeacowsSFT } from "../../TestCollectionToken/TestSeacowsSFT.sol";
import { ISeacowsPairERC1155 } from "../../interfaces/ISeacowsPairERC1155.sol";
import { TestERC20 } from "../../TestCollectionToken/TestERC20.sol";
import { SeacowsPair } from "../../SeacowsPair.sol";
import { ISeacowsPairERC1155ERC20 } from "../../interfaces/ISeacowsPairERC1155ERC20.sol";
import { WhenCreatePair } from "../base/WhenCreatePair.t.sol";
import { IWETH } from "../../interfaces/IWETH.sol";

/// @dev See the "Writing Tests" section in the Foundry Book if this is your first time with Forge.
/// https://book.getfoundry.sh/forge/writing-tests
contract SeacowsPairERC1155ETHTest is WhenCreatePair {
    TestSeacowsSFT internal testSeacowsSFT;
    SeacowsPairERC1155ERC20 internal pair;

    function setUp() public override(WhenCreatePair) {
        WhenCreatePair.setUp();

        // deploy sft contract
        testSeacowsSFT = new TestSeacowsSFT();
        testSeacowsSFT.safeMint(owner);
        testSeacowsSFT.safeMint(alice);
        testSeacowsSFT.safeMint(bob);

        // create a pair
        vm.startPrank(owner);
        pair = createERC1155ETHPair(testSeacowsSFT, 1, 1000, 100000, 10);
        vm.stopPrank();

        vm.startPrank(alice);
        testSeacowsSFT.setApprovalForAll(address(seacowsPairFactory), true);
        vm.stopPrank();

        vm.startPrank(bob);
        testSeacowsSFT.setApprovalForAll(address(seacowsPairFactory), true);
        vm.stopPrank();
    }

    function test_create_eth_pair() public {
        vm.startPrank(owner);

        address nft = pair.nft();
        assertEq(nft, address(testSeacowsSFT));

        uint256 tokenId = pair.tokenId();
        assertEq(tokenId, 1);

        ERC20 token = pair.token();
        assertEq(address(token), address(weth));

        uint256 spotPrice = pair.spotPrice();
        assertEq(spotPrice, 100);

        SeacowsPair.PoolType poolType = pair.poolType();
        assertEq(uint256(poolType), uint256(SeacowsPair.PoolType.TRADE));

        uint256 lpBalance = pair.balanceOf(owner, 1);
        assertEq(lpBalance, 1000);

        vm.stopPrank();
    }

    function test_add_liquidity() public {
        vm.startPrank(alice);

        seacowsPairFactory.addLiquidityETHERC1155{ value: 10000 }(ISeacowsPairERC1155ERC20(address(pair)), 100);
        // check LP token balance
        uint256 lpBalance = pair.balanceOf(alice, 1);
        assertEq(lpBalance, 100);
        // check pair weth balance
        uint256 tokenBalance = IERC20(weth).balanceOf(address(pair));
        assertEq(tokenBalance, 110000);
        // check pair erc1155 balance
        uint256 sftBalance = testSeacowsSFT.balanceOf(address(pair), 1);
        assertEq(sftBalance, 1100);
        // check spot price
        uint256 spotPrice = ISeacowsPairERC1155(address(pair)).spotPrice();
        assertEq(spotPrice, 100);

        // revert cases
        vm.expectRevert("Invalid eth amount based on spot price");
        seacowsPairFactory.addLiquidityETHERC1155{ value: 100 }(ISeacowsPairERC1155ERC20(address(pair)), 100);

        vm.expectRevert("Invalid NFT amount");
        seacowsPairFactory.addLiquidityETHERC1155{ value: 10000 }(ISeacowsPairERC1155ERC20(address(pair)), 0);

        vm.stopPrank();
    }

    function test_remove_liquidity() public {
        vm.startPrank(alice);

        seacowsPairFactory.addLiquidityETHERC1155{ value: 10000 }(ISeacowsPairERC1155ERC20(address(pair)), 100);

        seacowsPairFactory.removeLiquidityETHERC1155(ISeacowsPairERC1155ERC20(address(pair)), 10);

        // check pair weth token balance
        uint256 tokenBalance = IERC20(weth).balanceOf(address(pair));
        assertEq(tokenBalance, 109000);
        // check pair erc1155 balance
        uint256 sftBalance = testSeacowsSFT.balanceOf(address(pair), 1);
        assertEq(sftBalance, 1090);
        // check LP token balance
        uint256 lpBalance = pair.balanceOf(alice, 1);
        assertEq(lpBalance, 90);
        // check spot price
        uint256 spotPrice = ISeacowsPairERC1155(address(pair)).spotPrice();
        assertEq(spotPrice, 100);
        // trying to remove invalid LP token
        vm.expectRevert("Insufficient LP token");
        seacowsPairFactory.removeLiquidityERC20ERC1155(ISeacowsPairERC1155ERC20(address(pair)), 100, false);

        vm.stopPrank();
    }

    function test_swap_any_nfts() public {
        vm.startPrank(alice);
        // deposit eth for weth
        IWETH(weth).deposit{ value: 1000000 ether }();
        // approve weth tokens to the pair
        IERC20(weth).approve(address(pair), 1000000);
        // nft and token balance before swap
        uint256 tokenBeforeBalance = IERC20(weth).balanceOf(alice);
        uint256 sftBeforeBalance = testSeacowsSFT.balanceOf(alice, 1);
        // swap tokens for any nfts
        pair.swapTokenForAnyNFTs(100, 10150, alice, false, address(0));
        // check balances after swap
        uint256 tokenAfterBalance = IERC20(weth).balanceOf(alice);
        uint256 sftAfterBalance = testSeacowsSFT.balanceOf(alice, 1);

        assertEq(tokenAfterBalance, tokenBeforeBalance - 10050);
        assertEq(sftAfterBalance, sftBeforeBalance + 100);

        // trying to swap with insufficient amount of tokens
        vm.expectRevert("In too many tokens");
        pair.swapTokenForAnyNFTs(100, 10150, alice, false, address(0));

        // trying to swap with invalid nft amount
        vm.expectRevert("Invalid nft amount");
        pair.swapTokenForAnyNFTs(0, 10150, alice, false, address(0));

        vm.stopPrank();
    }

    function test_swap_tokens() public {
        vm.startPrank(alice);
        // approve erc1155 tokens to the pair
        testSeacowsSFT.setApprovalForAll(address(pair), true);
        // nft and token balance before swap
        uint256 tokenBeforeBalance = IERC20(weth).balanceOf(alice);
        uint256 sftBeforeBalance = testSeacowsSFT.balanceOf(alice, 1);
        // swap tokens for any nfts
        uint256 outputAmount = pair.swapNFTsForTokenERC1155(100, 9950, payable(alice), false, address(0));
        // check balances after swap
        uint256 tokenAfterBalance = IERC20(weth).balanceOf(alice);
        uint256 sftAfterBalance = testSeacowsSFT.balanceOf(alice, 1);

        assertEq(tokenAfterBalance, tokenBeforeBalance + 9950);
        assertEq(sftAfterBalance, sftBeforeBalance - 100);

        // expect too much output tokens
        vm.expectRevert("Out too little tokens");
        pair.swapNFTsForTokenERC1155(100, 9950, payable(alice), false, address(0));

        // trying to swap with invalid nft amount
        vm.expectRevert("Must ask for > 0 NFTs");
        pair.swapNFTsForTokenERC1155(0, 9950, payable(alice), false, address(0));

        vm.stopPrank();
    }
}
