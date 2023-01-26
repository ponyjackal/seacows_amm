// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "forge-std/Test.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { HelperConfig } from "../../script/HelperConfig.sol";
import { SeacowsPairFactory } from "../SeacowsPairFactory.sol";
import { ISeacowsPairFactoryLike } from "../interfaces/ISeacowsPairFactoryLike.sol";
import { SeacowsPairEnumerableERC20 } from "../SeacowsPairEnumerableERC20.sol";
import { SeacowsPairMissingEnumerableERC20 } from "../SeacowsPairMissingEnumerableERC20.sol";
import { SeacowsPairERC20 } from "../SeacowsPairERC20.sol";
import { SeacowsPairERC1155ERC20 } from "../SeacowsPairERC1155ERC20.sol";
import { UniswapPriceOracle } from "../priceoracle/UniswapPriceOracle.sol";
import { ChainlinkAggregator } from "../priceoracle/ChainlinkAggregator.sol";
import { TestSeacowsSFT } from "../TestCollectionToken/TestSeacowsSFT.sol";
import { ISeacowsPairERC1155 } from "../interfaces/ISeacowsPairERC1155.sol";
import { CPMMCurve } from "../bondingcurve/CPMMCurve.sol";
import { TestERC20 } from "../TestCollectionToken/TestERC20.sol";
import { SeacowsPair } from "../SeacowsPair.sol";
import { ISeacowsPairERC1155ERC20 } from "../interfaces/ISeacowsPairERC1155ERC20.sol";

/// @dev See the "Writing Tests" section in the Foundry Book if this is your first time with Forge.
/// https://book.getfoundry.sh/forge/writing-tests
contract SeacowsPairERC1155Test is Test {
    uint256 internal ownerPrivateKey;
    uint256 internal spenderPrivateKey;
    uint256 internal traderPrivateKey;

    address internal weth;
    address internal owner;
    address internal spender;
    address internal trader;

    SeacowsPairFactory internal seacowsPairFactory;
    SeacowsPairEnumerableERC20 internal seacowsPairEnumerableERC20;
    SeacowsPairMissingEnumerableERC20 internal seacowsPairMissingEnumerableERC20;
    SeacowsPairERC1155ERC20 internal seacowsPairERC1155ERC20;
    UniswapPriceOracle internal uniswapPriceOracle;
    ChainlinkAggregator internal chainlinkAggregator;
    TestSeacowsSFT internal testSeacowsSFT;
    SeacowsPairERC20 internal pair;
    CPMMCurve internal cpmmCurve;
    TestERC20 internal token;

    function setUp() public {
        HelperConfig helperConfig = new HelperConfig();
        (
            string memory lpUri,
            address _weth,
            address payable protocolFeeRecipient,
            uint256 protocolFeeMultiplier,
            address seacowsCollectionRegistry,
            address chainlinkToken,
            address chainlinkOracle,
            string memory chainlinkJobId
        ) = helperConfig.activeNetworkConfig();

        ownerPrivateKey = 0xA11CE;
        spenderPrivateKey = 0xB0B;
        traderPrivateKey = 0xA12DF;

        owner = vm.addr(ownerPrivateKey);
        spender = vm.addr(spenderPrivateKey);
        trader = vm.addr(traderPrivateKey);

        /** deploy TestWETH */
        weth = _weth;

        /** deploy SeacowsPairEnumerableERC20 */
        seacowsPairEnumerableERC20 = new SeacowsPairEnumerableERC20(lpUri);

        /** deploy SeacowsPairMissingEnumerableERC20 */
        seacowsPairMissingEnumerableERC20 = new SeacowsPairMissingEnumerableERC20(lpUri);

        /** deploy SeacowsPairERC1155ERC20 */
        seacowsPairERC1155ERC20 = new SeacowsPairERC1155ERC20(lpUri);

        /** deploy ChainlinkAggregator */
        chainlinkAggregator = new ChainlinkAggregator(ISeacowsPairFactoryLike(address(0)), chainlinkToken, chainlinkOracle, chainlinkJobId);

        /** deploy UniswapPriceOracle */
        uniswapPriceOracle = new UniswapPriceOracle();

        /** deploy SeacowsPairFactory */
        seacowsPairFactory = new SeacowsPairFactory(
            weth,
            // seacowsPairEnumerableETH,
            // seacowsPairMissingEnumerableETH,
            seacowsPairEnumerableERC20,
            seacowsPairMissingEnumerableERC20,
            // seacowsPairERC1155ETH,
            seacowsPairERC1155ERC20,
            protocolFeeRecipient,
            protocolFeeMultiplier,
            seacowsCollectionRegistry,
            chainlinkAggregator,
            uniswapPriceOracle
        );

        // deploy sft contract
        testSeacowsSFT = new TestSeacowsSFT();
        testSeacowsSFT.safeMint(owner);
        testSeacowsSFT.safeMint(spender);
        testSeacowsSFT.safeMint(trader);

        token = new TestERC20();
        token.mint(owner, 1e18);
        token.mint(spender, 1e18);
        token.mint(trader, 1e18);

        // deploy CPMM
        cpmmCurve = new CPMMCurve();

        // create a pair
        vm.startPrank(owner);
        token.approve(address(seacowsPairFactory), 1000000);
        testSeacowsSFT.setApprovalForAll(address(seacowsPairFactory), true);

        pair = seacowsPairFactory.createPairERC1155ERC20(testSeacowsSFT, 1, cpmmCurve, 1000, ERC20(token), 100000, 10);

        vm.stopPrank();

        vm.startPrank(spender);
        token.approve(address(seacowsPairFactory), 1000000);
        testSeacowsSFT.setApprovalForAll(address(seacowsPairFactory), true);
        vm.stopPrank();

        vm.startPrank(trader);
        token.approve(address(seacowsPairFactory), 1000000);
        testSeacowsSFT.setApprovalForAll(address(seacowsPairFactory), true);
        vm.stopPrank();
    }

    function test_create_erc20_pair() public {
        address nft = ISeacowsPairERC1155(address(pair)).nft();
        assertEq(nft, address(testSeacowsSFT));

        uint256 tokenId = ISeacowsPairERC1155(address(pair)).tokenId();
        assertEq(tokenId, 1);

        uint256 spotPrice = ISeacowsPairERC1155(address(pair)).spotPrice();
        assertEq(spotPrice, 100);

        ERC20 token = ISeacowsPairERC1155ERC20(address(pair)).token();
        assertEq(address(token), address(token));

        SeacowsPair.PoolType poolType = ISeacowsPairERC1155ERC20(address(pair)).poolType();
        assertEq(uint256(poolType), uint256(SeacowsPair.PoolType.TRADE));

        uint256 lpBalance = pair.balanceOf(owner, 1);
        assertEq(lpBalance, 1000);
    }

    function test_add_liquidity() public {
        vm.startPrank(spender);

        seacowsPairFactory.addLiquidityERC20ERC1155(ISeacowsPairERC1155ERC20(address(pair)), 100, 10000);
        // check LP token balance
        uint256 lpBalance = pair.balanceOf(spender, 1);
        assertEq(lpBalance, 100);
        // check pair erc20 token balance
        uint256 tokenBalance = token.balanceOf(address(pair));
        assertEq(tokenBalance, 110000);
        // check pair erc1155 balance
        uint256 sftBalance = testSeacowsSFT.balanceOf(address(pair), 1);
        assertEq(sftBalance, 1100);
        // check spot price
        uint256 spotPrice = ISeacowsPairERC1155(address(pair)).spotPrice();
        assertEq(spotPrice, 100);

        // revert cases
        vm.expectRevert("Invalid token amount based on spot price");
        seacowsPairFactory.addLiquidityERC20ERC1155(ISeacowsPairERC1155ERC20(address(pair)), 100, 100);

        vm.expectRevert("Invalid NFT amount");
        seacowsPairFactory.addLiquidityERC20ERC1155(ISeacowsPairERC1155ERC20(address(pair)), 0, 10000);

        vm.stopPrank();
    }

    function test_remove_liquidity() public {
        vm.startPrank(spender);

        seacowsPairFactory.addLiquidityERC20ERC1155(ISeacowsPairERC1155ERC20(address(pair)), 100, 10000);

        seacowsPairFactory.removeLiquidityERC20ERC1155(ISeacowsPairERC1155ERC20(address(pair)), 10, false);

        // check pair erc20 token balance
        uint256 tokenBalance = token.balanceOf(address(pair));
        assertEq(tokenBalance, 109000);
        // check pair erc1155 balance
        uint256 sftBalance = testSeacowsSFT.balanceOf(address(pair), 1);
        assertEq(sftBalance, 1090);
        // check LP token balance
        uint256 lpBalance = pair.balanceOf(spender, 1);
        assertEq(lpBalance, 90);
        // check spot price
        uint256 spotPrice = ISeacowsPairERC1155(address(pair)).spotPrice();
        assertEq(spotPrice, 100);
        // trying to remove invalid LP token
        vm.expectRevert("Insufficient LP token");
        seacowsPairFactory.removeLiquidityERC20ERC1155(ISeacowsPairERC1155ERC20(address(pair)), 100, false);

        vm.stopPrank();
    }

    function test_swap_any_nfts() public {
        vm.startPrank(spender);
        // approve erc20 tokens to the pair
        token.approve(address(pair), 1000000);
        // nft and token balance before swap
        uint256 tokenBeforeBalance = token.balanceOf(spender);
        uint256 sftBeforeBalance = testSeacowsSFT.balanceOf(spender, 1);
        // swap tokens for any nfts
        pair.swapTokenForAnyNFTs(100, 10150, spender, false, address(0));
        // check balances after swap
        uint256 tokenAfterBalance = token.balanceOf(spender);
        uint256 sftAfterBalance = testSeacowsSFT.balanceOf(spender, 1);

        assertEq(tokenAfterBalance, tokenBeforeBalance - 10050);
        assertEq(sftAfterBalance, sftBeforeBalance + 100);

        vm.stopPrank();
    }
}
