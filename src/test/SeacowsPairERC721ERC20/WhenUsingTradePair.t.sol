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
import { BaseFactorySetup } from "../BaseFactorySetup.t.sol";
import { BaseCurveSetup } from "../BaseCurveSetup.t.sol";

/// @dev See the "Writing Tests" section in the Foundry Book if this is your first time with Forge.
/// https://book.getfoundry.sh/forge/writing-tests
contract WhenUsingTradePair is BaseFactorySetup, BaseCurveSetup {
    address internal owner;
    address internal spender;

    SeacowsPairERC20 internal erc721ERC20Pair;
    SeacowsPairERC20 internal erc721EnumerableERC20Pair;

    TestERC721 internal nft;
    TestERC721Enumerable internal nftEnumerable;
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

        /** deploy Bonding Curve */
        seacowsPairFactory.setBondingCurveAllowed(linearCurve, true);

        /** create ERC721Enumerable-ERC20 Trade Pair */
        vm.startPrank(owner);
        uint256[] memory nftEnumerableIds = new uint256[](1);
        nftEnumerableIds[0] = 0;
        // token.approve(address(seacowsPairFactory), 1 ether);
        // nftEnumerable.setApprovalForAll(address(seacowsPairFactory), true);
        erc721EnumerableERC20Pair = createTradePair(
            token,
            nftEnumerable,
            linearCurve,
            0.2 ether,
            0.2 ether,
            2 ether,
            nftEnumerableIds,
            1 ether
        );

        /** create ERC721Enumerable-ERC20 Trade Pair */
        // token.approve(address(seacowsPairFactory), 1 ether);
        // nft.setApprovalForAll(address(seacowsPairFactory), true);
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = 0;
        erc721ERC20Pair = createTradePair(
            token,
            nft,
            linearCurve,
            0.2 ether,
            0.2 ether,
            2 ether,
            nftIds,
            1 ether);
        vm.stopPrank();
    }

    function createTradePair(
        IERC20 _token,
        IERC721 _nft,
        ICurve _bondingCurve,
        uint128 _delta,
        uint96 _fee,
        uint128 _spotPrice,
        uint256[] memory _initialNFTIDs,
        uint256 _initialTokenBalance
    ) public returns (SeacowsPairERC20 pair) {
        _token.approve(address(seacowsPairFactory), _initialTokenBalance);
        _nft.setApprovalForAll(address(seacowsPairFactory), true);
        SeacowsPairFactory.CreateERC20PairParams memory params = SeacowsPairFactory.CreateERC20PairParams(
            _token,
            _nft,
            _bondingCurve,
            payable(address(0)),
            SeacowsPair.PoolType.TRADE,
            _delta,
            _fee,
            _spotPrice,
            _initialNFTIDs,
            _initialTokenBalance
        );
        pair = seacowsPairFactory.createPairERC20(params);
    }

    function testERC721EnumerableERC20TradePair() public {
        assertEq(address(erc721EnumerableERC20Pair.nft()), address(nftEnumerable));
        assertEq(address(erc721EnumerableERC20Pair.token()), address(token));
        assertEq(address(erc721EnumerableERC20Pair.bondingCurve()), address(linearCurve));
        assertEq(erc721EnumerableERC20Pair.spotPrice(), 2 ether);
        assertEq(erc721EnumerableERC20Pair.delta(), 0.2 ether);
        assertEq(erc721EnumerableERC20Pair.fee(), 0.2 ether);
        assertEq(erc721EnumerableERC20Pair.owner(), owner);

        assertEq(token.balanceOf(address(erc721EnumerableERC20Pair)), 1 ether);
        assertEq(nftEnumerable.ownerOf(0), address(erc721EnumerableERC20Pair));
        // check LP token balance: 1
        assertEq(erc721EnumerableERC20Pair.balanceOf(owner, erc721EnumerableERC20Pair.LP_TOKEN()), 1);
    }

    function testERC721ERC20TradePair() public {
        assertEq(address(erc721ERC20Pair.nft()), address(nft));
        assertEq(address(erc721ERC20Pair.token()), address(token));
        assertEq(address(erc721ERC20Pair.bondingCurve()), address(linearCurve));
        assertEq(erc721ERC20Pair.spotPrice(), 2 ether);
        assertEq(erc721ERC20Pair.delta(), 0.2 ether);
        assertEq(erc721ERC20Pair.fee(), 0.2 ether);
        assertEq(erc721ERC20Pair.owner(), owner);

        assertEq(token.balanceOf(address(erc721ERC20Pair)), 1 ether);
        assertEq(nft.ownerOf(0), address(erc721ERC20Pair));

        // check LP token balance: 1
        assertEq(erc721ERC20Pair.balanceOf(owner, erc721ERC20Pair.LP_TOKEN()), 1);
    }

    function testERC721EnumerableERC20AddLiquidity() public {
        vm.startPrank(owner);
        // check original LP token balance: 1
        assertEq(erc721EnumerableERC20Pair.balanceOf(owner, erc721EnumerableERC20Pair.LP_TOKEN()), 1);
        token.approve(address(seacowsPairFactory), 1000 ether);

        nftEnumerable.safeMint(owner);
        nftEnumerable.setApprovalForAll(address(seacowsPairFactory), true);
        assertEq(nftEnumerable.ownerOf(1), owner);
        
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = 1;
        seacowsPairFactory.addLiquidityERC20(erc721EnumerableERC20Pair, nftIds, 3 ether);

        assertEq(token.balanceOf(address(erc721EnumerableERC20Pair)), 4 ether);
        assertEq(nftEnumerable.ownerOf(1), address(erc721EnumerableERC20Pair));
    
        // check LP token balance: 2
        assertEq(erc721EnumerableERC20Pair.balanceOf(owner, erc721EnumerableERC20Pair.LP_TOKEN()), 2);
        
        vm.stopPrank();
    }

    function testERC721ERC20AddLiquidity() public {
        vm.startPrank(owner);
        // check original LP token balance: 1
        assertEq(erc721ERC20Pair.balanceOf(owner, erc721ERC20Pair.LP_TOKEN()), 1);
        token.approve(address(seacowsPairFactory), 1000 ether);

        nft.safeMint(owner);
        nft.setApprovalForAll(address(seacowsPairFactory), true);
        assertEq(nft.ownerOf(1), owner);
        
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = 1;
        seacowsPairFactory.addLiquidityERC20(erc721ERC20Pair, nftIds, 3 ether);

        assertEq(token.balanceOf(address(erc721ERC20Pair)), 4 ether);
        assertEq(nft.ownerOf(1), address(erc721ERC20Pair));
    
        // check LP token balance: 2
        assertEq(erc721ERC20Pair.balanceOf(owner, erc721ERC20Pair.LP_TOKEN()), 2);
        vm.stopPrank();
    }

    function testCreateAnotherERC721EnumerableERC20TradePair() public {
        nftEnumerable.safeMint(owner);
        assertEq(nftEnumerable.ownerOf(1), owner);
        vm.startPrank(owner);
        nftEnumerable.setApprovalForAll(address(seacowsPairFactory), true);
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = 1;
        SeacowsPairERC20 pair = createTradePair(
            token,
            nftEnumerable,
            linearCurve,
            10 ether,
            0,
            2 ether,
            nftIds,
            10 ether
        );
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

    function testERC721EnumerableERC20Swap() public {
        vm.startPrank(owner);
        
        vm.stopPrank();
    }
}
