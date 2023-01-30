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
contract WhenCreateNFTPair is WhenCreatePair {
    SeacowsPairERC20 internal erc721ERC20Pair;
    SeacowsPairERC20 internal erc721EnumerableERC20Pair;

    TestERC721Enumerable internal nftEnumerable;
    TestERC721 internal nft;
    TestERC20 internal token;

    function setUp() public virtual override(WhenCreatePair) {
        WhenCreatePair.setUp();

        token = new TestERC20();
        token.mint(owner, 1000 ether);

        nftEnumerable = new TestERC721Enumerable();
        nftEnumerable.safeMint(owner);

        nft = new TestERC721();
        nft.safeMint(owner);

        /** Approve Bonding Curve */
        seacowsPairFactory.setBondingCurveAllowed(linearCurve, true);

        /** Create ERC721Enumerable-ERC20 NFT Pair */
        vm.startPrank(owner);
        uint256[] memory nftEnumerableIds = new uint256[](1);
        nftEnumerableIds[0] = 0;
        token.approve(address(seacowsPairFactory), 1 ether);
        nftEnumerable.setApprovalForAll(address(seacowsPairFactory), true);
        erc721EnumerableERC20Pair = createNFTPair(
            token,
            nftEnumerable,
            linearCurve,
            payable(owner),
            2.2 ether,
            2 ether,
            nftEnumerableIds,
            1 ether
        );

        /** Create ERC721-ERC20 NFT Pair */
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = 0;
        token.approve(address(seacowsPairFactory), 1 ether);
        nft.setApprovalForAll(address(seacowsPairFactory), true);
        erc721ERC20Pair = createNFTPair(
            token,
            nft,
            linearCurve,
            payable(owner),
            2.2 ether,
            2 ether,
            nftIds,
            1 ether
        );
        vm.stopPrank();
    }

    function testERC721EnumerableERC20NFTPair() public {
        assertEq(erc721EnumerableERC20Pair.nft(), address(nftEnumerable));
        assertEq(address(erc721EnumerableERC20Pair.token()), address(token));
        assertEq(address(erc721EnumerableERC20Pair.bondingCurve()), address(linearCurve));
        assertEq(erc721EnumerableERC20Pair.spotPrice(), 2 ether);
        assertEq(erc721EnumerableERC20Pair.delta(), 2.2 ether);
        assertEq(erc721EnumerableERC20Pair.fee(), 0);
        assertEq(erc721EnumerableERC20Pair.owner(), owner);

        assertEq(token.balanceOf(address(erc721EnumerableERC20Pair)), 1 ether);
        assertEq(nftEnumerable.ownerOf(0), address(erc721EnumerableERC20Pair));
        // check LP token balance: 0 (No LP token minted)
        assertEq(erc721EnumerableERC20Pair.balanceOf(owner, erc721EnumerableERC20Pair.LP_TOKEN()), 0);
    }

    function testCannotAddLiquidityToNFTPair() public {
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = 0;

        vm.expectRevert();
        seacowsPairFactory.addLiquidityERC20(erc721EnumerableERC20Pair, nftIds, 3 ether);

        vm.expectRevert();
        seacowsPairFactory.addLiquidityERC20(erc721ERC20Pair, nftIds, 3 ether);
    }
}
