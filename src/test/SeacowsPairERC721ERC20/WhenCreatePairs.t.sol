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
contract WhenCreatePairs is BaseFactorySetup, BaseCurveSetup {
    address internal owner;
    address internal spender;

    SeacowsPairERC20 internal pair;

    TestERC721Enumerable internal nftEnumerable;
    TestERC721 internal nft;
    TestERC20 internal token;

    function setUp() public virtual override(BaseFactorySetup, BaseCurveSetup) {
        owner = vm.addr(1);
        spender = vm.addr(2);
        
        BaseFactorySetup.setUp();
        BaseCurveSetup.setUp();

        token = new TestERC20();
        token.mint(owner, 1000 ether);

        nft = new TestERC721();
        nft.safeMint(owner);

        nftEnumerable = new TestERC721Enumerable();
        nftEnumerable.safeMint(owner);

        seacowsPairFactory.setBondingCurveAllowed(linearCurve, true);
    }
    
    /** create ERC721-ERC20 Trade Pair */
    function testCreateERC721ERC20TradePair() public {
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

        assertEq(address(pair.nft()), address(nft));
        assertEq(address(pair.token()), address(token));
        assertEq(address(pair.bondingCurve()), address(linearCurve));
        assertEq(pair.spotPrice(), 2 ether);
        assertEq(pair.delta(), 2.2 ether);
        assertEq(pair.fee(), 0.2 ether);
        assertEq(pair.owner(), owner);

        assertEq(token.balanceOf(address(pair)), 1 ether);
        assertEq(nft.ownerOf(0), address(pair));
        vm.stopPrank();
    }
    
    /** create ERC721Enumerable-ERC20 Trade Pair */
    function testCreateERC721EnumerableERC2TradePair() public {
        vm.startPrank(owner);
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = 0;
        SeacowsPairFactory.CreateERC20PairParams memory params = SeacowsPairFactory.CreateERC20PairParams(
            token,
            nftEnumerable,
            linearCurve,
            payable(address(0)),
            SeacowsPair.PoolType.TRADE,
            2 ether,
            0.2 ether,
            1 ether,
            nftIds,
            1 ether
        );
        token.approve(address(seacowsPairFactory), 1 ether);
        nftEnumerable.setApprovalForAll(address(seacowsPairFactory), true);
        pair = seacowsPairFactory.createPairERC20(params);

        assertEq(address(pair.nft()), address(nftEnumerable));
        assertEq(address(pair.token()), address(token));
        assertEq(address(pair.bondingCurve()), address(linearCurve));
        assertEq(pair.assetRecipient(), payable(address(0)));
        assertEq(pair.spotPrice(), 1 ether);
        assertEq(pair.delta(), 2 ether);
        assertEq(pair.fee(), 0.2 ether);
        assertEq(pair.owner(), owner);

        assertEq(token.balanceOf(address(pair)), 1 ether);
        assertEq(nftEnumerable.ownerOf(0), address(pair));
        vm.stopPrank();
    }
    
    /** create ERC721-ERC20 Token Pair */
    function testCreateERC721ERC20TokenPair() public {
        vm.startPrank(owner);
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = 0;
        SeacowsPairFactory.CreateERC20PairParams memory params = SeacowsPairFactory.CreateERC20PairParams(
            token,
            nft,
            linearCurve,
            payable(address(0)),
            SeacowsPair.PoolType.TOKEN,
            2.2 ether,
            0,
            2 ether,
            nftIds,
            1 ether
        );
        
        token.approve(address(seacowsPairFactory), 1 ether);
        nft.setApprovalForAll(address(seacowsPairFactory), true);
        pair = seacowsPairFactory.createPairERC20(params);

        assertEq(address(pair.nft()), address(nft));
        assertEq(address(pair.token()), address(token));
        assertEq(address(pair.bondingCurve()), address(linearCurve));
        assertEq(pair.assetRecipient(), payable(address(0)));
        assertEq(pair.spotPrice(), 2 ether);
        assertEq(pair.delta(), 2.2 ether);
        assertEq(pair.fee(), 0);
        assertEq(pair.owner(), owner);

        assertEq(token.balanceOf(address(pair)), 1 ether);
        assertEq(nft.ownerOf(0), address(pair));
        vm.stopPrank();
    }
    
    /** create ERC721Enumerable-ERC20 Token Pair */
    function testCreateERC721EnumerableERC20TokenPair() public {
        vm.startPrank(owner);
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = 0;
        SeacowsPairFactory.CreateERC20PairParams memory params = SeacowsPairFactory.CreateERC20PairParams(
            token,
            nftEnumerable,
            linearCurve,
            payable(address(0)),
            SeacowsPair.PoolType.TOKEN,
            2 ether,
            0,
            1 ether,
            nftIds,
            1 ether
        );
        token.approve(address(seacowsPairFactory), 1 ether);
        nftEnumerable.setApprovalForAll(address(seacowsPairFactory), true);
        pair = seacowsPairFactory.createPairERC20(params);

        assertEq(address(pair.nft()), address(nftEnumerable));
        assertEq(address(pair.token()), address(token));
        assertEq(address(pair.bondingCurve()), address(linearCurve));
        assertEq(pair.spotPrice(), 1 ether);
        assertEq(pair.delta(), 2 ether);
        assertEq(pair.fee(), 0);
        assertEq(pair.owner(), owner);

        assertEq(token.balanceOf(address(pair)), 1 ether);
        assertEq(nftEnumerable.ownerOf(0), address(pair));
        vm.stopPrank();
    }
}
