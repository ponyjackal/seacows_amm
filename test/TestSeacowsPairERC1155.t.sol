// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "forge-std/Test.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { HelperConfig } from "../script/HelperConfig.sol";
import { SeacowsPairFactory } from "../src/SeacowsPairFactory.sol";
import { ISeacowsPairFactoryLike } from "../src/interfaces/ISeacowsPairFactoryLike.sol";
import { SeacowsPairEnumerableETH } from "../src/SeacowsPairEnumerableETH.sol";
import { SeacowsPairMissingEnumerableETH } from "../src/SeacowsPairMissingEnumerableETH.sol";
import { SeacowsPairEnumerableERC20 } from "../src/SeacowsPairEnumerableERC20.sol";
import { SeacowsPairMissingEnumerableERC20 } from "../src/SeacowsPairMissingEnumerableERC20.sol";
import { SeacowsPairETH } from "../src/SeacowsPairETH.sol";
import { SeacowsPairERC1155ETH } from "../src/SeacowsPairERC1155ETH.sol";
import { SeacowsPairERC1155ERC20 } from "../src/SeacowsPairERC1155ERC20.sol";
import { UniswapPriceOracle } from "../src/priceoracle/UniswapPriceOracle.sol";
import { ChainlinkAggregator } from "../src/priceoracle/ChainlinkAggregator.sol";
import { TestSeacowsSFT } from "../src/TestCollectionToken/TestSeacowsSFT.sol";
import { ISeacowsPairERC1155 } from "../src/interfaces/ISeacowsPairERC1155.sol";

/// @dev See the "Writing Tests" section in the Foundry Book if this is your first time with Forge.
/// https://book.getfoundry.sh/forge/writing-tests
contract SeacowsPairERC1155Test is Test {
    uint256 internal ownerPrivateKey;
    uint256 internal spenderPrivateKey;

    address internal owner;
    address internal spender;

    SeacowsPairFactory internal seacowsPairFactory;
    SeacowsPairEnumerableETH internal seacowsPairEnumerableETH;
    SeacowsPairMissingEnumerableETH internal seacowsPairMissingEnumerableETH;
    SeacowsPairEnumerableERC20 internal seacowsPairEnumerableERC20;
    SeacowsPairMissingEnumerableERC20 internal seacowsPairMissingEnumerableERC20;
    SeacowsPairERC1155ETH internal seacowsPairERC1155ETH;
    SeacowsPairERC1155ERC20 internal seacowsPairERC1155ERC20;
    UniswapPriceOracle internal uniswapPriceOracle;
    ChainlinkAggregator internal chainlinkAggregator;
    TestSeacowsSFT internal testSeacowsSFT;

    function setUp() public {
        HelperConfig helperConfig = new HelperConfig();
        (
            string memory lpUri,
            address payable protocolFeeRecipient,
            uint256 protocolFeeMultiplier,
            address seacowsCollectionRegistry,
            address chainlinkToken,
            address chainlinkOracle,
            string memory chainlinkJobId
        ) = helperConfig.activeNetworkConfig();

        ownerPrivateKey = 0xA11CE;
        spenderPrivateKey = 0xB0B;

        owner = vm.addr(ownerPrivateKey);
        spender = vm.addr(spenderPrivateKey);

        /** deploy SeacowsPairEnumerableETH */
        seacowsPairEnumerableETH = new SeacowsPairEnumerableETH(lpUri);

        /** deploy SeacowsPairMissingEnumerableETH */
        seacowsPairMissingEnumerableETH = new SeacowsPairMissingEnumerableETH(lpUri);

        /** deploy SeacowsPairEnumerableERC20 */
        seacowsPairEnumerableERC20 = new SeacowsPairEnumerableERC20(lpUri);

        /** deploy SeacowsPairMissingEnumerableERC20 */
        seacowsPairMissingEnumerableERC20 = new SeacowsPairMissingEnumerableERC20(lpUri);

        /** deploy SeacowsPairERC1155ETH */
        seacowsPairERC1155ETH = new SeacowsPairERC1155ETH(lpUri);

        /** deploy SeacowsPairERC1155ERC20 */
        seacowsPairERC1155ERC20 = new SeacowsPairERC1155ERC20(lpUri);

        /** deploy ChainlinkAggregator */
        chainlinkAggregator = new ChainlinkAggregator(
            ISeacowsPairFactoryLike(address(0)),
            chainlinkToken,
            chainlinkOracle,
            chainlinkJobId
        );

        /** deploy UniswapPriceOracle */
        uniswapPriceOracle = new UniswapPriceOracle();

        /** deploy SeacowsPairFactory */
        seacowsPairFactory = new SeacowsPairFactory(
            seacowsPairEnumerableETH,
            seacowsPairMissingEnumerableETH,
            seacowsPairEnumerableERC20,
            seacowsPairMissingEnumerableERC20,
            seacowsPairERC1155ETH,
            seacowsPairERC1155ERC20,
            protocolFeeRecipient,
            protocolFeeMultiplier,
            seacowsCollectionRegistry,
            chainlinkAggregator,
            uniswapPriceOracle
        );

        // deploy sft contract
        testSeacowsSFT = new TestSeacowsSFT();
        testSeacowsSFT.safeMint(spender);
    }

    function test_create_eth_pair() public {
        vm.prank(spender);
        SeacowsPairETH ethPair = seacowsPairFactory.createPairERC1155ETH(testSeacowsSFT, 1, 1000, 10);

        uint256 tokenId = ISeacowsPairERC1155(address(ethPair)).tokenId();

        assertEq(tokenId, 5);
    }
}
