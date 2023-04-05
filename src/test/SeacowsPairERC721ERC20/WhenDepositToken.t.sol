// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "forge-std/Test.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ICurve } from "../../bondingcurve/ICurve.sol";
import { SeacowsPair } from "../../pairs/SeacowsPair.sol";
import { TestWETH } from "../../TestCollectionToken/TestWETH.sol";
import { IWETH } from "../../interfaces/IWETH.sol";
import { TestERC20 } from "../../TestCollectionToken/TestERC20.sol";
import { TestERC721 } from "../../TestCollectionToken/TestERC721.sol";
import { TestERC721Enumerable } from "../../TestCollectionToken/TestERC721Enumerable.sol";
import { WhenCreatePair } from "../base/WhenCreatePair.t.sol";

/// @dev See the "Writing Tests" section in the Foundry Book if this is your first time with Forge.
/// https://book.getfoundry.sh/forge/writing-tests
contract WhenDepositToken is WhenCreatePair {
    SeacowsPair internal erc721ERC20Pair;
    SeacowsPair internal erc721WETHPair;

    TestERC721 internal nft;
    TestERC20 internal token;

    function setUp() public virtual override(WhenCreatePair) {
        WhenCreatePair.setUp();

        token = new TestERC20();
        token.mint(owner, 1000 ether);

        nft = new TestERC721();
        nft.safeMint(owner);

        /** Approve Bonding Curve */
        seacowsPairERC721Factory.setBondingCurveAllowed(linearCurve, true);
        seacowsPairERC721Factory.setBondingCurveAllowed(exponentialCurve, true);

        vm.startPrank(owner);
        nft.setApprovalForAll(address(seacowsPairERC721Factory), true);
        token.approve(address(seacowsPairERC721Factory), 1000 ether);
        /** Create ERC721-WETH Token Pair */
        nft.safeMint(owner);
        uint256[] memory nftIdsforWETHPair = new uint256[](1);
        nftIdsforWETHPair[0] = 0;
        erc721WETHPair = createTokenPairETH(nft, linearCurve, payable(owner), 0.1 ether, 5 ether, nftIdsforWETHPair, 14 ether);

        /** Create ERC721-ERC20 Token Pair */
        nft.safeMint(owner);
        uint256[] memory nftIdsforERC20Pair = new uint256[](1);
        nftIdsforERC20Pair[0] = 1;
        erc721ERC20Pair = createTokenPair(token, nft, exponentialCurve, payable(owner), 1.01 ether, 20 ether, nftIdsforERC20Pair, 100 ether);
        vm.stopPrank();

        /** mint nft and tokens to alice */
        token.mint(alice, 1000 ether);
        nft.safeMint(alice);
        /** approve tokens and nft to factory */
        vm.startPrank(alice);
        nft.setApprovalForAll(address(seacowsPairERC721Factory), true);
        token.approve(address(seacowsPairERC721Factory), 1000 ether);
        vm.stopPrank();
    }

    function testdepositERC20() public {
        vm.startPrank(owner);
        /** allow more tokens before deposit */
        token.approve(address(erc721ERC20Pair), 1000 ether);
        /** owner deposits token to erc721-erc20 token pair */
        erc721ERC20Pair.depositERC20(120 ether);
        /** check token balance */
        uint256 tokenBalance = token.balanceOf(address(erc721ERC20Pair));
        assertEq(tokenBalance, 220 ether);
        /** check bonding curve */
        ICurve curve = erc721ERC20Pair.bondingCurve();
        assertEq(address(curve), address(exponentialCurve));
        /** check delta */
        uint128 delta = erc721ERC20Pair.delta();
        assertEq(delta, 1.01 ether);
        /** check spot price */
        uint128 spotPrice = erc721ERC20Pair.spotPrice();
        assertEq(spotPrice, 20 ether);
        vm.stopPrank();

        /** alice is trying to deposit tokens */
        vm.startPrank(alice);
        token.approve(address(erc721ERC20Pair), 1000 ether);
        vm.expectRevert("Not a pair owner");
        erc721ERC20Pair.depositERC20(100 ether);
        vm.stopPrank();
    }

    function testdepositWETH() public {
        vm.startPrank(owner);
        /** owner deposits ETH to erc721-weth pair */
        erc721WETHPair.depositETH{ value: 4 ether }();
        /** check ETH balance */
        uint256 wethBalance = IWETH(weth).balanceOf(address(erc721WETHPair));
        assertEq(wethBalance, 18 ether);
        /** check bonding curve */
        ICurve curve = erc721WETHPair.bondingCurve();
        assertEq(address(curve), address(linearCurve));
        /** check delta */
        uint128 delta = erc721WETHPair.delta();
        assertEq(delta, 0.1 ether);
        /** check spot price */
        uint128 spotPrice = erc721WETHPair.spotPrice();
        assertEq(spotPrice, 5 ether);
        vm.stopPrank();

        /** alice is trying to deposit tokens */
        vm.startPrank(alice);
        vm.expectRevert("Not a pair owner");
        erc721WETHPair.depositETH{ value: 4 ether }();
        vm.stopPrank();
    }
}
