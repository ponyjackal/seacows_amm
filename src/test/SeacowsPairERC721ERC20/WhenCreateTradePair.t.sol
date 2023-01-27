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
import { BaseSetup } from "../BaseSetup.t.sol";

/// @dev See the "Writing Tests" section in the Foundry Book if this is your first time with Forge.
/// https://book.getfoundry.sh/forge/writing-tests
contract WhenCreateTradePair is BaseFactorySetup, BaseCurveSetup, BaseSetup {
    SeacowsPairERC20 internal erc721ERC20TradePair;
    SeacowsPairERC20 internal erc721EnumerableERC20TradePair;

    TestERC721 internal nft;
    TestERC721Enumerable internal nftEnumerable;
    TestERC20 internal token;

    function setUp() public virtual override(BaseFactorySetup, BaseCurveSetup, BaseSetup) {
        BaseSetup.setUp();
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
        erc721EnumerableERC20TradePair = createTradePair(
            token,
            nftEnumerable,
            linearCurve,
            0.2 ether,
            0.2 ether,
            2 ether,
            nftEnumerableIds,
            1 ether
        );

        /** create ERC721-ERC20 Trade Pair */
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = 0;
        erc721ERC20TradePair = createTradePair(
            token,
            nft,
            linearCurve,
            0.2 ether,
            0.2 ether,
            2 ether,
            nftIds,
            1 ether);

        /** create ERC721Enumerable-ERC20 Trade Pair from ETH */
        // uint256[] memory nftIds = new uint256[](1);
        // nftIds[0] = 0;
        // createTradePairETH{value: 10 ether}(
        //     nft,
        //     linearCurve,
        //     payable(owner),
        //     0.2 ether,
        //     2 ether,
        //     nftIds
        // );
        
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

    function createTradePairETH(
        IERC721 _nft,
        ICurve _bondingCurve,
        uint128 _delta,
        uint96 _fee,
        uint128 _spotPrice,
        uint256[] memory _initialNFTIDs,
        uint256 _initialETHBalance
    ) public returns (SeacowsPairERC20 pair) {
        _nft.setApprovalForAll(address(seacowsPairFactory), true);
        pair = seacowsPairFactory.createPairETH{ value: _initialETHBalance }(
            _nft,
            _bondingCurve,
            payable(address(0)),
            SeacowsPair.PoolType.TRADE,
            _delta,
            _fee,
            _spotPrice,
            _initialNFTIDs
        );
    }

    // function testCreateERC721EnumerableERC20TradePairFromETH() public {
    //     assertEq(address(erc721EnumerableERC20TradePair.nft()), address(nftEnumerable));
    //     assertEq(address(erc721EnumerableERC20TradePair.token()), address(token));
    //     assertEq(address(erc721EnumerableERC20TradePair.bondingCurve()), address(linearCurve));
    //     assertEq(erc721EnumerableERC20TradePair.spotPrice(), 2 ether);
    //     assertEq(erc721EnumerableERC20TradePair.delta(), 0.2 ether);
    //     assertEq(erc721EnumerableERC20TradePair.fee(), 0.2 ether);
    //     assertEq(erc721EnumerableERC20TradePair.owner(), owner);

    //     assertEq(token.balanceOf(address(erc721EnumerableERC20TradePair)), 1 ether);
    //     assertEq(nftEnumerable.ownerOf(0), address(erc721EnumerableERC20TradePair));
    //     // check LP token balance: 1
    //     assertEq(erc721EnumerableERC20TradePair.balanceOf(owner, erc721EnumerableERC20TradePair.LP_TOKEN()), 1);
    // }

    function testCreateERC721ERC20TradePairFromETH() public {
        vm.startPrank(owner);
        /** create ERC721-ERC20 Trade Pair from ETH */
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = 1;

        nft.safeMint(owner);
        nft.setApprovalForAll(address(seacowsPairFactory), true);
        SeacowsPairERC20 pair = createTradePairETH(
            nft,
            linearCurve,
            0.2 ether,
            0.2 ether,
            2 ether,
            nftIds,
            1 ether
        );
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

    function testERC721EnumerableERC20AddLiquidity() public {
        vm.startPrank(owner);
        // check original LP token balance: 1
        assertEq(erc721EnumerableERC20TradePair.balanceOf(owner, erc721EnumerableERC20TradePair.LP_TOKEN()), 1);
        token.approve(address(seacowsPairFactory), 1000 ether);

        nftEnumerable.safeMint(owner);
        nftEnumerable.setApprovalForAll(address(seacowsPairFactory), true);
        assertEq(nftEnumerable.ownerOf(1), owner);
        
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = 1;
        seacowsPairFactory.addLiquidityERC20(erc721EnumerableERC20TradePair, nftIds, 3 ether);

        assertEq(token.balanceOf(address(erc721EnumerableERC20TradePair)), 4 ether);
        assertEq(nftEnumerable.ownerOf(1), address(erc721EnumerableERC20TradePair));
    
        // check LP token balance: 2
        assertEq(erc721EnumerableERC20TradePair.balanceOf(owner, erc721EnumerableERC20TradePair.LP_TOKEN()), 2);
        
        vm.stopPrank();
    }

    function testERC721ERC20AddLiquidity() public {
        vm.startPrank(owner);
        // check original LP token balance: 1
        assertEq(erc721ERC20TradePair.balanceOf(owner, erc721ERC20TradePair.LP_TOKEN()), 1);
        token.approve(address(seacowsPairFactory), 1000 ether);

        nft.safeMint(owner);
        nft.setApprovalForAll(address(seacowsPairFactory), true);
        assertEq(nft.ownerOf(1), owner);
        
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = 1;
        seacowsPairFactory.addLiquidityERC20(erc721ERC20TradePair, nftIds, 3 ether);

        assertEq(token.balanceOf(address(erc721ERC20TradePair)), 4 ether);
        assertEq(nft.ownerOf(1), address(erc721ERC20TradePair));
    
        // check LP token balance: 2
        assertEq(erc721ERC20TradePair.balanceOf(owner, erc721ERC20TradePair.LP_TOKEN()), 2);
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
}
