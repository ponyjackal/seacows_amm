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
contract WhenDepositToken is WhenCreatePair {
    SeacowsPairERC20 internal erc721ERC20Pair;
    SeacowsPairERC20 internal erc721WETHPair;

    TestERC721 internal nft;
    TestERC20 internal token;

    function setUp() public virtual override(WhenCreatePair) {
        WhenCreatePair.setUp();

        token = new TestERC20();
        token.mint(owner, 1000 ether);

        nft = new TestERC721();
        nft.safeMint(owner);

        /** Approve Bonding Curve */
        seacowsPairFactory.setBondingCurveAllowed(linearCurve, true);
        seacowsPairFactory.setBondingCurveAllowed(exponentialCurve, true);

        /** Create ERC721-WETH Token Pair */
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = 0;
        token.approve(address(seacowsPairFactory), 1 ether);
        nft.setApprovalForAll(address(seacowsPairFactory), true);
        erc721WETHPair = createTokenPairETH(nft, linearCurve, payable(owner), 0.1 ether, 5 ether, nftIds, 14 ether);

        /** Create ERC721-ERC20 Token Pair */
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = 0;
        token.approve(address(seacowsPairFactory), 1 ether);
        nft.setApprovalForAll(address(seacowsPairFactory), true);
        erc721ERC20Pair = createTokenPair(token, nft, exponentialCurve, payable(owner), 1.01 ether, 20 ether, nftIds, 100 ether);
        vm.stopPrank();
    }
}
