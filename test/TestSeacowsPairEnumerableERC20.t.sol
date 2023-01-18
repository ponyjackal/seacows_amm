// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "forge-std/Test.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { HelperConfig } from "../script/HelperConfig.sol";
import { SeacowsPairCloner } from "../src/lib/SeacowsPairCloner.sol";
import { SeacowsPairFactory } from "../src/SeacowsPairFactory.sol";
import { ISeacowsPairFactoryLike } from "../src/interfaces/ISeacowsPairFactoryLike.sol";
import { SeacowsPairEnumerableERC20 } from "../src/SeacowsPairEnumerableERC20.sol";
import { SeacowsPairMissingEnumerableERC20 } from "../src/SeacowsPairMissingEnumerableERC20.sol";
import { SeacowsPairERC20 } from "../src/SeacowsPairERC20.sol";
import { SeacowsPairERC1155ERC20 } from "../src/SeacowsPairERC1155ERC20.sol";
import { UniswapPriceOracle } from "../src/priceoracle/UniswapPriceOracle.sol";
import { ChainlinkAggregator } from "../src/priceoracle/ChainlinkAggregator.sol";
import { TestWETH } from "../src/TestCollectionToken/TestWETH.sol";
import { TestERC721 } from "../src/TestCollectionToken/TestERC721.sol";
import { TestERC20 } from "../src/TestCollectionToken/TestERC20.sol";

/// @dev See the "Writing Tests" section in the Foundry Book if this is your first time with Forge.
/// https://book.getfoundry.sh/forge/writing-tests
contract TestSeacowsPairEnumerableERC20 is Test {
    using SeacowsPairCloner for SeacowsPairEnumerableERC20;
    uint256 internal ownerPrivateKey;
    uint256 internal spenderPrivateKey;

    address internal weth;
    address internal owner;
    address internal spender;
    address payable internal protocolFeeRecipient;

    SeacowsPairFactory internal seacowsPairFactory;
    SeacowsPairEnumerableERC20 internal seacowsPairEnumerableERC20;
    SeacowsPairMissingEnumerableERC20 internal seacowsPairMissingEnumerableERC20;
    SeacowsPairERC1155ERC20 internal seacowsPairERC1155ERC20;
    UniswapPriceOracle internal uniswapPriceOracle;
    ChainlinkAggregator internal chainlinkAggregator;
    TestERC721 internal nft;
    TestERC20 internal token;

    function setUp() public {
        HelperConfig helperConfig = new HelperConfig();
        (
            string memory lpUri,
            address _weth,
            address payable _protocolFeeRecipient,
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
        protocolFeeRecipient = _protocolFeeRecipient;

        token = new TestERC20();
        nft = new TestERC721();

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
            seacowsPairEnumerableERC20,
            seacowsPairMissingEnumerableERC20,
            seacowsPairERC1155ERC20,
            protocolFeeRecipient,
            protocolFeeMultiplier,
            seacowsCollectionRegistry,
            chainlinkAggregator,
            uniswapPriceOracle
        );
    }

    function test_createTradeEnumerableERC20Pair() public {
        // TODO: Complete the Test case
        // SeacowsPairERC20 pair = seacowsPairFactory.createPairERC20(token, nft);
        // seacowsPairFactory.initialize(owner, protocolFeeRecipient, 2.2 ether, 0.2 ether, 2 ether);
        // assertEq(pair.spotPrice(), 2 ether);
        // assertEq(pair.delta(), 2.2 ether);
        // assertEq(pair.fee(), 0.2 ether);
    }
}
