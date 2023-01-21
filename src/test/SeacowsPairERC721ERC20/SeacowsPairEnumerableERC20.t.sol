// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "forge-std/Test.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { SeacowsPairERC20 } from "../../SeacowsPairERC20.sol";
import { SeacowsPairFactory } from "../../SeacowsPairFactory.sol";
import { SeacowsPair } from "../../SeacowsPair.sol";
import { TestWETH } from "../../TestCollectionToken/TestWETH.sol";
import { TestERC20 } from "../../TestCollectionToken/TestERC20.sol";
import { TestERC721 } from "../../TestCollectionToken/TestERC721.sol";
import { TestERC721Enumerable } from "../../TestCollectionToken/TestERC721Enumerable.sol";
import { BaseFactorySetup } from "../BaseFactorySetup.t.sol";
import { BaseCurveSetup } from "../BaseCurveSetup.t.sol";

/// @dev See the "Writing Tests" section in the Foundry Book if this is your first time with Forge.
/// https://book.getfoundry.sh/forge/writing-tests
contract TestSeacowsPairEnumerableERC20 is BaseFactorySetup, BaseCurveSetup {
    address internal owner;
    address internal spender;

    SeacowsPairERC20 internal pair;

    TestERC721Enumerable internal nft;
    TestERC20 internal token;

    function setUp() public virtual override(BaseFactorySetup, BaseCurveSetup) {
        owner = vm.addr(1);
        spender = vm.addr(2);
        
        BaseFactorySetup.setUp();
        BaseCurveSetup.setUp();

        token = new TestERC20();
        token.mint(owner, 1000 ether);

        nft = new TestERC721Enumerable();
        nft.safeMint(owner);

        /** deploy Bonding Curve */
        seacowsPairFactory.setBondingCurveAllowed(linearCurve, true);

        /** create Trade ERC721Enumerable-ERC20 Pair */
        vm.startPrank(owner);
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = 0;
        SeacowsPairFactory.CreateERC20PairParams memory params = SeacowsPairFactory.CreateERC20PairParams(
            token,
            nft,
            linearCurve,
            payable(address(0)),
            SeacowsPair.PoolType.TRADE,
            2.2 ether,
            0.2 ether,
            2 ether,
            nftIds,
            1 ether
        );
        token.approve(address(seacowsPairFactory), 1 ether);
        nft.setApprovalForAll(address(seacowsPairFactory), true);
        pair = seacowsPairFactory.createPairERC20(params);
        vm.stopPrank();
    }

    function testAddLiquidity() public {
        vm.startPrank(owner);
        token.approve(address(seacowsPairFactory), 1000 ether);

        nft.safeMint(owner);
        nft.setApprovalForAll(address(seacowsPairFactory), true);
        
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = 1;
        seacowsPairFactory.addLiquidityERC20(pair, nftIds, 3 ether);

        assertEq(token.balanceOf(address(pair)), 4 ether);
        assertEq(nft.ownerOf(1), address(pair));
        
        vm.stopPrank();
    }
}
