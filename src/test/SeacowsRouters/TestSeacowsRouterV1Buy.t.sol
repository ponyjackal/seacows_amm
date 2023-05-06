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
import { SeacowsRouterV1 } from "../../routers/SeacowsRouterV1.sol";

/// @dev See the "Writing Tests" section in the Foundry Book if this is your first time with Forge.
/// https://book.getfoundry.sh/forge/writing-tests
contract TestSeacowsRouterV1Buy is WhenCreatePair {
    SeacowsPair internal erc721ERC20Pair;
    SeacowsPair internal erc721ETHPair;

    TestERC721 internal nft;
    TestERC20 internal token;

    function setUp() public virtual override(WhenCreatePair) {
        WhenCreatePair.setUp();

        token = new TestERC20();
        token.mint(owner, 1000 ether);
        token.mint(alice, 1000 ether);

        nft = new TestERC721();
        nft.safeMint(owner, 10);
        nft.safeMint(alice, 2);
        /** Approve Bonding Curve */
        seacowsPairERC721Factory.setBondingCurveAllowed(linearCurve, true);
        seacowsPairERC721Factory.setBondingCurveAllowed(exponentialCurve, true);

        /** Create ERC721Enumerable-ERC20 NFT Pair */
        vm.startPrank(owner);
        token.approve(address(seacowsPairERC721Factory), 1 ether);
        nft.setApprovalForAll(address(seacowsPairERC721Factory), true);
        nft.setApprovalForAll(address(seacowsRouterV1), true);

        uint256[] memory nftETHIds = new uint256[](5);
        nftETHIds[0] = 1;
        nftETHIds[1] = 2;
        nftETHIds[2] = 4;
        nftETHIds[3] = 5;
        nftETHIds[4] = 7;

        erc721ETHPair = createNFTPairETH(nft, linearCurve, payable(owner), 0.5 ether, 5 ether, nftETHIds);

        /** Create ERC721-ERC20 NFT Pair */
        uint256[] memory nftIds = new uint256[](2);
        nftIds[0] = 3;
        nftIds[1] = 9;

        erc721ERC20Pair = createNFTPair(token, nft, exponentialCurve, payable(owner), 1.1 ether, 5 ether, nftIds, 0 ether);
        vm.stopPrank();

        /** enable/disable protocol fees */
        seacowsPairERC721Factory.disableProtocolFee(erc721ETHPair, false);
        seacowsPairERC721Factory.disableProtocolFee(erc721ERC20Pair, true);

        vm.startPrank(alice);
        nft.setApprovalForAll(address(seacowsPairERC721Factory), true);
        nft.setApprovalForAll(address(seacowsRouterV1), true);
        token.approve(address(seacowsRouterV1), 100 ether);
        token.approve(address(erc721ERC20Pair), 100 ether);
        token.approve(address(erc721ETHPair), 100 ether);
        vm.stopPrank();
    }

    /** buy specific nfts */

    function testBuySpecificNFTsWithProtocolFee() public {
        /** Alice is trying to buy NFTs from nft pair */
        vm.startPrank(alice);

        uint256[] memory nftIds = new uint256[](2);
        nftIds[0] = 1;
        nftIds[1] = 2;

        uint256 tokenBalanceAlice = alice.balance;
        uint256 tokenBalanceOwner = IWETH(weth).balanceOf(owner);

        SeacowsRouterV1.ERC721PairSwap[] memory params = new SeacowsRouterV1.ERC721PairSwap[](1);
        params[0] = SeacowsRouterV1.ERC721PairSwap(ISeacowsPairERC721(address(erc721ETHPair)), nftIds);
        seacowsRouterV1.swapTokenForNFTsETHERC721{ value: 100 ether }(params, address(alice));

        /** Check nft owners */
        assertEq(nft.ownerOf(1), alice);
        assertEq(nft.ownerOf(2), alice);
        /** Check pair configs */
        assertEq(erc721ETHPair.spotPrice(), 6 ether);
        assertEq(erc721ETHPair.delta(), 0.5 ether);
        /** Check token balance update */
        uint256 updatedTokenBalanceAlice = alice.balance;
        assertEq(updatedTokenBalanceAlice, tokenBalanceAlice - 11.5 ether);

        uint256 updatedTokenBalanceOwner = IWETH(weth).balanceOf(owner);
        assertEq(updatedTokenBalanceOwner, tokenBalanceOwner + 11.4425 ether);

        vm.stopPrank();
    }

    function testBuySpecificNFTsWithOutProtocolFee() public {
        /** Alice is trying to buy NFTs from nft pair */
        vm.startPrank(alice);

        uint256[] memory nftIds = new uint256[](2);
        nftIds[0] = 3;
        nftIds[1] = 9;

        uint256 tokenBalanceAlice = token.balanceOf(alice);
        uint256 tokenBalanceOwner = token.balanceOf(owner);

        SeacowsRouterV1.ERC721PairSwap[] memory params = new SeacowsRouterV1.ERC721PairSwap[](1);
        params[0] = SeacowsRouterV1.ERC721PairSwap(ISeacowsPairERC721(address(erc721ERC20Pair)), nftIds);
        seacowsRouterV1.swapTokenForNFTsERC721(params, 15 ether, address(alice));

        /** Check nft owners */
        assertEq(nft.ownerOf(3), alice);
        assertEq(nft.ownerOf(9), alice);
        /** Check pair configs */
        assertEq(erc721ERC20Pair.spotPrice(), 6.05 ether);
        assertEq(erc721ERC20Pair.delta(), 1.1 ether);
        /** Check token balance update */
        uint256 updatedTokenBalanceAlice = token.balanceOf(alice);
        assertEq(updatedTokenBalanceAlice, tokenBalanceAlice - 11.55 ether);

        uint256 updatedTokenBalanceOwner = token.balanceOf(owner);
        assertEq(updatedTokenBalanceOwner, tokenBalanceOwner + 11.55 ether);

        vm.stopPrank();
    }

    function testBuySpecificNFTsWithInsufficientTokens() public {
        /** Alice is trying to buy NFTs from nft pair */
        vm.startPrank(alice);

        uint256[] memory nftETHIds = new uint256[](2);
        nftETHIds[0] = 1;
        nftETHIds[1] = 2;

        SeacowsRouterV1.ERC721PairSwap[] memory ethParams = new SeacowsRouterV1.ERC721PairSwap[](1);
        ethParams[0] = SeacowsRouterV1.ERC721PairSwap(ISeacowsPairERC721(address(erc721ETHPair)), nftETHIds);

        vm.expectRevert();
        seacowsRouterV1.swapTokenForNFTsERC721(ethParams, 15 ether, address(alice));

        uint256[] memory nftIds = new uint256[](2);
        nftIds[0] = 1;
        nftIds[1] = 2;

        SeacowsRouterV1.ERC721PairSwap[] memory erc20Params = new SeacowsRouterV1.ERC721PairSwap[](1);
        erc20Params[0] = SeacowsRouterV1.ERC721PairSwap(ISeacowsPairERC721(address(erc721ERC20Pair)), nftIds);

        vm.expectRevert("In too many tokens");
        seacowsRouterV1.swapTokenForNFTsERC721(erc20Params, 10 ether, address(alice));

        vm.stopPrank();
    }
}
