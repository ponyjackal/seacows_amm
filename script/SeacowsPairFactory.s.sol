// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import { Script } from "forge-std/Script.sol";
import { HelperConfig } from "./HelperConfig.sol";
import { SeacowsPairFactory } from "../src/SeacowsPairFactory.sol";
import { SeacowsPairEnumerableETH } from "../src/SeacowsPairEnumerableETH.sol";
import { SeacowsPairMissingEnumerableETH } from "../src/SeacowsPairMissingEnumerableETH.sol";
import { SeacowsPairEnumerableERC20 } from "../src/SeacowsPairEnumerableERC20.sol";
import { SeacowsPairMissingEnumerableERC20 } from "../src/SeacowsPairMissingEnumerableERC20.sol";
import { UniswapPriceOracle } from "../src/priceoracle/UniswapPriceOracle.sol";
import { ChainlinkAggregator } from "../src/priceoracle/ChainlinkAggregator.sol";
import { IChainlinkAggregator } from "../src/interfaces/IChainlinkAggregator.sol";
import { IUniswapPriceOracle } from "../src/interfaces/IUniswapPriceOracle.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract DeploySeacowsPairFactory is Script {
    SeacowsPairFactory internal seacowsPairFactory;
    SeacowsPairEnumerableETH internal seacowsPairEnumerableETH;
    SeacowsPairMissingEnumerableETH internal seacowsPairMissingEnumerableETH;
    SeacowsPairEnumerableERC20 internal seacowsPairEnumerableERC20;
    SeacowsPairMissingEnumerableERC20 internal seacowsPairMissingEnumerableERC20;
    UniswapPriceOracle internal uniswapPriceOracle;
    ChainlinkAggregator internal chainlinkAggregator;

    function run() public {
        HelperConfig helperConfig = new HelperConfig();
        (
            string memory lpUri,
            address payable protocolFeeRecipient,
            uint256 protocolFeeMultiplier,
            address seacowsCollectionRegistry
        ) = helperConfig.activeNetworkConfig();

        /** deploy SeacowsPairEnumerableETH */
        seacowsPairEnumerableETH = new SeacowsPairEnumerableETH(lpUri);
        /** deploy SeacowsPairMissingEnumerableETH */
        seacowsPairMissingEnumerableETH = new SeacowsPairMissingEnumerableETH(lpUri);
        /** deploy SeacowsPairEnumerableERC20 */
        seacowsPairEnumerableERC20 = new SeacowsPairEnumerableERC20(lpUri);
        /** deploy SeacowsPairMissingEnumerableERC20 */
        seacowsPairMissingEnumerableERC20 = new SeacowsPairMissingEnumerableERC20(lpUri);

        vm.startBroadcast();
        // seacowsPairFactory = new SeacowsPairFactory(
        //     seacowsPairEnumerableETH,
        //     seacowsPairMissingEnumerableETH,
        //     seacowsPairEnumerableERC20,
        //     seacowsPairMissingEnumerableERC20,
        //     protocolFeeRecipient,
        //     protocol_feemultiplier,
        //     seacowscollectionRegistry
        // );
        vm.stopBroadcast();
    }
}
