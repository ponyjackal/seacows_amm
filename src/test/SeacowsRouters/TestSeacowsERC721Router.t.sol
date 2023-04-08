// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "forge-std/Test.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ICurve } from "../../bondingcurve/ICurve.sol";
import { ISeacowsPairERC721 } from "../../interfaces/ISeacowsPairERC721.sol";

import { WhenCreatePair } from "../base/WhenCreatePair.t.sol";
import { SeacowsPair } from "../../pairs/SeacowsPair.sol";
import { TestWETH } from "../../TestCollectionToken/TestWETH.sol";
import { TestERC20 } from "../../TestCollectionToken/TestERC20.sol";
import { TestERC721 } from "../../TestCollectionToken/TestERC721.sol";

/// @dev See the "Writing Tests" section in the Foundry Book if this is your first time with Forge.
/// https://book.getfoundry.sh/forge/writing-tests
contract TestSeacowsERC721Router is WhenCreatePair {
    SeacowsPair internal tradePair;
    SeacowsPair internal tokenPair;
    SeacowsPair internal nftPair;

    TestERC721 internal nft;
    TestERC20 internal token;

    function setUp() public virtual override(WhenCreatePair) {
        WhenCreatePair.setUp();

        token = new TestERC20();
        token.mint(owner, 1000 ether);
        token.mint(alice, 1000 ether);

        nft = new TestERC721();

        for (uint256 i; i < 10; i++) {
            nft.safeMint(owner);
        }
        for (uint256 i; i < 10; i++) {
            nft.safeMint(alice);
        }

        /** Approve Bonding Curve */
        seacowsPairERC721Factory.setBondingCurveAllowed(linearCurve, true);
        seacowsPairERC721Factory.setBondingCurveAllowed(exponentialCurve, true);
        seacowsPairERC721Factory.setBondingCurveAllowed(cpmmCurve, true);

        /** Create ERC721Enumerable-ERC20 NFT Pair */
        vm.startPrank(owner);
        token.approve(address(seacowsPairERC721Factory), 1000 ether);
        nft.setApprovalForAll(address(seacowsPairERC721Factory), true);

        uint256[] memory nftPairNFTIds = new uint256[](3);
        nftPairNFTIds[0] = 1;
        nftPairNFTIds[1] = 3;
        nftPairNFTIds[2] = 6;

        nftPair = createNFTPair(token, nft, exponentialCurve, payable(owner), 1.05 ether, 10 ether, nftPairNFTIds, 100 ether);

        /** Create ERC721Enumerable-ERC20 Trade Pair */
        // uint256[] memory tradePairNFTIds = new uint256[](5);
        // tradePairNFTIds[0] = 0;
        // tradePairNFTIds[1] = 5;
        // tradePairNFTIds[2] = 2;
        // tradePairNFTIds[3] = 4;
        // tradePairNFTIds[4] = 7;

        // tradePair = createTradePair(token, nft, cpmmCurve, 1 ether, 0.1 ether, 10 ether, tradePairNFTIds, 100 ether);

        /** Create ERC721Enumerable-ERC20 Token Pair */
        tokenPair = createTokenPair(token, nft, linearCurve, payable(owner), 1 ether, 10 ether, new uint256[](0), 100 ether);
        vm.stopPrank();

        vm.startPrank(alice);
        nft.setApprovalForAll(address(seacowsPairERC721Factory), true);
        nft.setApprovalForAll(address(tokenPair), true);
        // nft.setApprovalForAll(address(tradePair), true);

        token.approve(address(nftPair), 1000 ether);
        // token.approve(address(tradePair), 1000 ether);
        vm.stopPrank();
    }
}
