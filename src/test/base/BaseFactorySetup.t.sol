// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "forge-std/Test.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { SeacowsPairCloner } from "../../lib/SeacowsPairCloner.sol";
import { SeacowsPairFactory } from "../../SeacowsPairFactory.sol";
import { ISeacowsPairFactoryLike } from "../../interfaces/ISeacowsPairFactoryLike.sol";
import { SeacowsPairEnumerableERC20 } from "../../SeacowsPairEnumerableERC20.sol";
import { SeacowsPairMissingEnumerableERC20 } from "../../SeacowsPairMissingEnumerableERC20.sol";
import { SeacowsPairERC20 } from "../../SeacowsPairERC20.sol";
import { SeacowsPair } from "../../SeacowsPair.sol";
import { SeacowsPairERC1155ERC20 } from "../../SeacowsPairERC1155ERC20.sol";
import { UniswapPriceOracle } from "../../priceoracle/UniswapPriceOracle.sol";
import { ChainlinkAggregator } from "../../priceoracle/ChainlinkAggregator.sol";
import { LinearCurve } from "../../bondingcurve/LinearCurve.sol";
import { TestWETH } from "../../TestCollectionToken/TestWETH.sol";

/// @dev See the "Writing Tests" section in the Foundry Book if this is your first time with Forge.
/// https://book.getfoundry.sh/forge/writing-tests
contract BaseFactorySetup is Test {
    using SeacowsPairCloner for SeacowsPairEnumerableERC20;

    // string internal ownerPrivateKey;
    // string internal spenderPrivateKey;

    address internal weth;
    address payable internal protocolFeeRecipient;
    uint256 internal protocolFeeMultiplier;
    uint256 internal seacowsCollectionRegistry;

    SeacowsPairFactory internal seacowsPairFactory;
    SeacowsPairEnumerableERC20 internal seacowsPairEnumerableERC20;
    SeacowsPairMissingEnumerableERC20 internal seacowsPairMissingEnumerableERC20;
    SeacowsPairERC1155ERC20 internal seacowsPairERC1155ERC20;
    UniswapPriceOracle internal uniswapPriceOracle;
    ChainlinkAggregator internal chainlinkAggregator;

    function setUp() public virtual {
        string memory lpUri = "";
        address seacowsCollectionRegistry = address(0);
        address chainlinkToken = address(0);
        address chainlinkOracle = address(0);
        string memory chainlinkJobId = "";
        
        weth = address(new TestWETH());
        protocolFeeRecipient = payable(address(0));
        protocolFeeMultiplier = 5000000000000000;


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
}
