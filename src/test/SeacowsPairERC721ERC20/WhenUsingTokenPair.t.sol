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
contract WhenUsingTokenPair is BaseFactorySetup, BaseCurveSetup {
    address internal owner;
    address internal spender;

    SeacowsPairERC20 internal erc721ERC20Pair;
    SeacowsPairERC20 internal erc721EnumerableERC20Pair;

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

        nftEnumerable = new TestERC721Enumerable();
        nftEnumerable.safeMint(owner);

        nft = new TestERC721();
        nft.safeMint(owner);

        /** deploy Bonding Curve */
        seacowsPairFactory.setBondingCurveAllowed(linearCurve, true);

        /** create ERC721Enumerable-ERC20 Token Pair */
        // vm.startPrank(owner);
        uint256[] memory nftEnumerableIds = new uint256[](1);
        nftEnumerableIds[0] = 0;
        // token.approve(address(seacowsPairFactory), 1 ether);
        // nftEnumerable.setApprovalForAll(address(seacowsPairFactory), true);
        // SeacowsPairFactory.CreateERC20PairParams memory params = SeacowsPairFactory.CreateERC20PairParams(
        //     token,
        //     nftEnumerable,
        //     linearCurve,
        //     payable(owner),
        //     SeacowsPair.PoolType.TOKEN,
        //     2.2 ether,
        //     0, // Must be 0 for TOKEN Pool
        //     2 ether,
        //     nftEnumerableIds,
        //     1 ether
        // );
        // erc721EnumerableERC20Pair = seacowsPairFactory.createPairERC20(params);
        erc721EnumerableERC20Pair = this.createTokenPair(
            token,
            nftEnumerable,
            linearCurve,
            payable(owner),
            2.2 ether,
            2 ether,
            nftEnumerableIds,
            1 ether
        );
    }

    function createTokenPair(
        IERC20 _token,
        IERC721 _nft,
        ICurve _bondingCurve,
        address payable _assetRecipient,
        uint128 _delta,
        uint128 _spotPrice,
        uint256[] memory _initialNFTIDs,
        uint256 _initialTokenBalance
    ) public returns (SeacowsPairERC20 pair) {
        vm.startPrank(owner);
        _token.approve(address(seacowsPairFactory), _initialTokenBalance);
        _nft.setApprovalForAll(address(seacowsPairFactory), true);
        SeacowsPairFactory.CreateERC20PairParams memory params = SeacowsPairFactory.CreateERC20PairParams(
            _token,
            _nft,
            _bondingCurve,
            _assetRecipient,
            SeacowsPair.PoolType.TOKEN,
            _delta,
            0, // Must be 0 for TOKEN Pool
            _spotPrice,
            _initialNFTIDs,
            _initialTokenBalance
        );
        pair = seacowsPairFactory.createPairERC20(params);
        vm.stopPrank();
    }

    function testERC721EnumerableERC20TokenPair() public {
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
}
