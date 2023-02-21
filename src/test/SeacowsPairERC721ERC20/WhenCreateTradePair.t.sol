// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "forge-std/Test.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ICurve } from "../../bondingcurve/ICurve.sol";
import { SeacowsPairERC20 } from "../../SeacowsPairERC20.sol";
import { SeacowsPairFactory } from "../../SeacowsPairFactory.sol";
import { SeacowsPair } from "../../SeacowsPair.sol";
import { TestWETH } from "../../TestCollectionToken/TestWETH.sol";
import { TestERC20 } from "../../TestCollectionToken/TestERC20.sol";
import { TestERC721 } from "../../TestCollectionToken/TestERC721.sol";
import { TestERC721Enumerable } from "../../TestCollectionToken/TestERC721Enumerable.sol";
import { WhenCreatePair } from "../base/WhenCreatePair.t.sol";

/// @dev See the "Writing Tests" section in the Foundry Book if this is your first time with Forge.
/// https://book.getfoundry.sh/forge/writing-tests
contract WhenCreateTradePair is WhenCreatePair {
    SeacowsPairERC20 internal erc721ERC20TradePair;
    SeacowsPairERC20 internal erc721EnumerableERC20TradePair;

    TestERC721 internal nft;
    TestERC721Enumerable internal nftEnumerable;
    TestERC20 internal token;

    function setUp() public virtual override(WhenCreatePair) {
        WhenCreatePair.setUp();

        token = new TestERC20();
        token.mint(owner, 1000 ether);

        nft = new TestERC721();
        nft.safeMint(owner);

        nftEnumerable = new TestERC721Enumerable();
        nftEnumerable.safeMint(owner);

        /** deploy Bonding Curve */
        seacowsPairFactory.setBondingCurveAllowed(linearCurve, true);

        /** create ERC721Enumerable-ERC20 Trade Pair */
        vm.startPrank(owner);
        token.approve(address(seacowsPairFactory), 1000 ether);
        nftEnumerable.setApprovalForAll(address(seacowsPairFactory), true);
        nft.setApprovalForAll(address(seacowsPairFactory), true);

        uint256[] memory nftEnumerableIds = new uint256[](1);
        nftEnumerableIds[0] = 0;
        erc721EnumerableERC20TradePair = createTradePair(token, nftEnumerable, linearCurve, 0.2 ether, 0.2 ether, 2 ether, nftEnumerableIds, 1 ether);

        /** create ERC721-ERC20 Trade Pair */
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = 0;
        erc721ERC20TradePair = createTradePair(token, nft, linearCurve, 0.2 ether, 0.2 ether, 2 ether, nftIds, 1 ether);

        vm.stopPrank();
    }

    function testCreateERC721EnumerableERC20TradePairFromETH() public {
        vm.startPrank(owner);
        /** create ERC721-ERC20 Trade Pair from ETH */
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = 1;

        nftEnumerable.safeMint(owner);
        nftEnumerable.setApprovalForAll(address(seacowsPairFactory), true);
        SeacowsPairERC20 pair = createTradePairETH(nftEnumerable, linearCurve, 0.2 ether, 0.2 ether, 2 ether, nftIds, 1 ether);
        assertEq(address(pair.nft()), address(nftEnumerable));
        assertEq(address(pair.token()), weth);
        assertEq(address(pair.bondingCurve()), address(linearCurve));
        assertEq(pair.spotPrice(), 2 ether);
        assertEq(pair.delta(), 0.2 ether);
        assertEq(pair.fee(), 0.2 ether);
        assertEq(pair.owner(), owner);

        assertEq(IERC20(weth).balanceOf(address(pair)), 1 ether);
        assertEq(nftEnumerable.ownerOf(1), address(pair));
        // check LP token balance: 1
        assertEq(pair.balanceOf(owner, pair.LP_TOKEN()), 1);
        vm.stopPrank();
    }

    function testCreateERC721ERC20TradePairFromETH() public {
        vm.startPrank(owner);
        /** create ERC721-ERC20 Trade Pair from ETH */
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = 1;

        nft.safeMint(owner);
        nft.setApprovalForAll(address(seacowsPairFactory), true);
        SeacowsPairERC20 pair = createTradePairETH(nft, linearCurve, 0.2 ether, 0.2 ether, 2 ether, nftIds, 1 ether);
        assertEq(address(pair.nft()), address(nft));
        assertEq(address(pair.token()), weth);
        assertEq(address(pair.bondingCurve()), address(linearCurve));
        assertEq(pair.spotPrice(), 2 ether);
        assertEq(pair.delta(), 0.2 ether);
        assertEq(pair.fee(), 0.2 ether);
        assertEq(pair.owner(), owner);

        assertEq(IERC20(weth).balanceOf(address(pair)), 1 ether);
        assertEq(nft.ownerOf(1), address(pair));
        // check LP token balance: 1
        assertEq(pair.balanceOf(owner, pair.LP_TOKEN()), 1);
        vm.stopPrank();
    }

    function testERC721EnumerableERC20TradePair() public {
        assertEq(address(erc721EnumerableERC20TradePair.nft()), address(nftEnumerable));
        assertEq(address(erc721EnumerableERC20TradePair.token()), address(token));
        assertEq(address(erc721EnumerableERC20TradePair.bondingCurve()), address(linearCurve));
        assertEq(erc721EnumerableERC20TradePair.spotPrice(), 2 ether);
        assertEq(erc721EnumerableERC20TradePair.delta(), 0.2 ether);
        assertEq(erc721EnumerableERC20TradePair.fee(), 0.2 ether);
        assertEq(erc721EnumerableERC20TradePair.owner(), owner);

        assertEq(token.balanceOf(address(erc721EnumerableERC20TradePair)), 1 ether);
        assertEq(nftEnumerable.ownerOf(0), address(erc721EnumerableERC20TradePair));
        // check LP token balance: 1
        assertEq(erc721EnumerableERC20TradePair.balanceOf(owner, erc721EnumerableERC20TradePair.LP_TOKEN()), 1);
    }

    function testERC721ERC20TradePair() public {
        assertEq(address(erc721ERC20TradePair.nft()), address(nft));
        assertEq(address(erc721ERC20TradePair.token()), address(token));
        assertEq(address(erc721ERC20TradePair.bondingCurve()), address(linearCurve));
        assertEq(erc721ERC20TradePair.spotPrice(), 2 ether);
        assertEq(erc721ERC20TradePair.delta(), 0.2 ether);
        assertEq(erc721ERC20TradePair.fee(), 0.2 ether);
        assertEq(erc721ERC20TradePair.owner(), owner);

        assertEq(token.balanceOf(address(erc721ERC20TradePair)), 1 ether);
        assertEq(nft.ownerOf(0), address(erc721ERC20TradePair));

        // check LP token balance: 1
        assertEq(erc721ERC20TradePair.balanceOf(owner, erc721ERC20TradePair.LP_TOKEN()), 1);
    }

    function testCreateAnotherERC721EnumerableERC20TradePair() public {
        nftEnumerable.safeMint(owner);
        assertEq(nftEnumerable.ownerOf(1), owner);
        vm.startPrank(owner);
        nftEnumerable.setApprovalForAll(address(seacowsPairFactory), true);
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = 1;
        SeacowsPairERC20 pair = createTradePair(token, nftEnumerable, linearCurve, 10 ether, 0, 2 ether, nftIds, 10 ether);
        assertEq(address(pair.nft()), address(nftEnumerable));
        assertEq(address(pair.token()), address(token));
        assertEq(address(pair.bondingCurve()), address(linearCurve));
        assertEq(pair.spotPrice(), 2 ether);
        assertEq(pair.delta(), 10 ether);
        assertEq(pair.fee(), 0);
        assertEq(pair.owner(), owner);

        assertEq(token.balanceOf(address(pair)), 10 ether);
        assertEq(nftEnumerable.ownerOf(1), address(pair));
        // check LP token balance: 1
        assertEq(pair.balanceOf(owner, pair.LP_TOKEN()), 1);
        vm.stopPrank();
    }
}
