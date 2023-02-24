// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "forge-std/Test.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ICurve } from "../../bondingcurve/ICurve.sol";
import { SeacowsPair } from "../../SeacowsPair.sol";
import { SeacowsPairFactory } from "../../SeacowsPairFactory.sol";
import { SeacowsPair } from "../../SeacowsPair.sol";
import { TestWETH } from "../../TestCollectionToken/TestWETH.sol";
import { TestERC20 } from "../../TestCollectionToken/TestERC20.sol";
import { TestERC721 } from "../../TestCollectionToken/TestERC721.sol";
import { TestERC721Enumerable } from "../../TestCollectionToken/TestERC721Enumerable.sol";
import { WhenCreatePair } from "../base/WhenCreatePair.t.sol";

/// @dev See the "Writing Tests" section in the Foundry Book if this is your first time with Forge.
/// https://book.getfoundry.sh/forge/writing-tests
contract WhenDepositNFTs is WhenCreatePair {
    SeacowsPair internal erc721ERC20Pair;
    SeacowsPair internal erc721ETHPair;

    TestERC721 internal nft;
    TestERC20 internal token;

    function setUp() public virtual override(WhenCreatePair) {
        WhenCreatePair.setUp();

        token = new TestERC20();
        token.mint(owner, 1000 ether);

        nft = new TestERC721();
        uint256 i;
        for (; i < 10; i++) {
            nft.safeMint(owner);
        }
        nft.safeMint(alice);
        nft.safeMint(alice);
        /** Approve Bonding Curve */
        seacowsPairFactory.setBondingCurveAllowed(linearCurve, true);
        seacowsPairFactory.setBondingCurveAllowed(exponentialCurve, true);

        /** Create ERC721Enumerable-ERC20 NFT Pair */
        vm.startPrank(owner);
        token.approve(address(seacowsPairFactory), 1 ether);
        nft.setApprovalForAll(address(seacowsPairFactory), true);

        uint256[] memory nftETHIds = new uint256[](3);
        nftETHIds[0] = 1;
        nftETHIds[1] = 3;
        nftETHIds[2] = 6;

        erc721ETHPair = createNFTPairETH(nft, linearCurve, payable(owner), 1 ether, 5 ether, nftETHIds);

        /** Create ERC721-ERC20 NFT Pair */
        uint256[] memory nftIds = new uint256[](2);
        nftIds[0] = 0;
        nftIds[1] = 5;

        erc721ERC20Pair = createNFTPair(token, nft, exponentialCurve, payable(owner), 1.05 ether, 20 ether, nftIds, 1 ether);
        vm.stopPrank();

        vm.startPrank(alice);
        nft.setApprovalForAll(address(seacowsPairFactory), true);
        vm.stopPrank();
    }

    function testDepositNFTsETH() public {
        vm.startPrank(owner);
        uint256[] memory nftIds = new uint256[](2);
        nftIds[0] = 2;
        nftIds[1] = 4;

        /** Deposit NFTs */
        seacowsPairFactory.depositNFTs(nft, nftIds, address(erc721ETHPair));
        /** Check nft balance */
        uint256 balance = nft.balanceOf(address(erc721ETHPair));
        assertEq(balance, 5);
        /** check bonding curve */
        ICurve curve = erc721ETHPair.bondingCurve();
        assertEq(address(curve), address(linearCurve));
        /** check delta */
        uint128 delta = erc721ETHPair.delta();
        assertEq(delta, 1 ether);
        /** check spot price */
        uint128 spotPrice = erc721ETHPair.spotPrice();
        assertEq(spotPrice, 5 ether);
        vm.stopPrank();

        vm.startPrank(alice);
        uint256[] memory nftIdsForAlice = new uint256[](2);
        nftIdsForAlice[0] = 10;
        nftIdsForAlice[1] = 11;
        vm.expectRevert("Not a pair owner");
        seacowsPairFactory.depositNFTs(nft, nftIdsForAlice, address(erc721ETHPair));
        vm.stopPrank();
    }

    function testDepositNFTsERC20() public {
        vm.startPrank(owner);
        uint256[] memory nftIds = new uint256[](2);
        nftIds[0] = 7;
        nftIds[1] = 8;

        /** Deposit NFTs */
        seacowsPairFactory.depositNFTs(nft, nftIds, address(erc721ERC20Pair));
        /** Check nft balance */
        uint256 balance = nft.balanceOf(address(erc721ERC20Pair));
        assertEq(balance, 4);
        /** check bonding curve */
        ICurve curve = erc721ERC20Pair.bondingCurve();
        assertEq(address(curve), address(exponentialCurve));
        /** check delta */
        uint128 delta = erc721ERC20Pair.delta();
        assertEq(delta, 1.05 ether);
        /** check spot price */
        uint128 spotPrice = erc721ERC20Pair.spotPrice();
        assertEq(spotPrice, 20 ether);
        vm.stopPrank();

        vm.startPrank(alice);
        uint256[] memory nftIdsForAlice = new uint256[](2);
        nftIdsForAlice[0] = 10;
        nftIdsForAlice[1] = 11;
        vm.expectRevert("Not a pair owner");
        seacowsPairFactory.depositNFTs(nft, nftIdsForAlice, address(erc721ETHPair));
        vm.stopPrank();
    }
}
