// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import { Script } from "forge-std/Script.sol";
import { HelperConfig } from "./HelperConfig.sol";
import { SeacowsRouter } from "../src/SeacowsRouter.sol";
import { SeacowsPairFactory } from "../src/SeacowsPairFactory.sol";
import { ISeacowsPairFactoryLike } from "../src/interfaces/ISeacowsPairFactoryLike.sol";
// import { SeacowsPairEnumerableETH } from "../src/SeacowsPairEnumerableETH.sol";
// import { SeacowsPairMissingEnumerableETH } from "../src/SeacowsPairMissingEnumerableETH.sol";
import { SeacowsPairEnumerableERC20 } from "../src/SeacowsPairEnumerableERC20.sol";
import { SeacowsPairMissingEnumerableERC20 } from "../src/SeacowsPairMissingEnumerableERC20.sol";
import { SeacowsPairERC1155ETH } from "../src/SeacowsPairERC1155ETH.sol";
import { SeacowsPairERC1155ERC20 } from "../src/SeacowsPairERC1155ERC20.sol";
import { UniswapPriceOracle } from "../src/priceoracle/UniswapPriceOracle.sol";
import { ChainlinkAggregator } from "../src/priceoracle/ChainlinkAggregator.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract DeploySeacowsPairFactory is Script {
    SeacowsRouter internal seacowsRouter;
    SeacowsPairFactory internal seacowsPairFactory;
    // SeacowsPairEnumerableETH internal seacowsPairEnumerableETH;
    // SeacowsPairMissingEnumerableETH internal seacowsPairMissingEnumerableETH;
    SeacowsPairEnumerableERC20 internal seacowsPairEnumerableERC20;
    SeacowsPairMissingEnumerableERC20 internal seacowsPairMissingEnumerableERC20;
    SeacowsPairERC1155ETH internal seacowsPairERC1155ETH;
    SeacowsPairERC1155ERC20 internal seacowsPairERC1155ERC20;
    UniswapPriceOracle internal uniswapPriceOracle;
    ChainlinkAggregator internal chainlinkAggregator;

    function run() public {
        HelperConfig helperConfig = new HelperConfig();
        (
            string memory lpUri,
            address weth,
            address payable protocolFeeRecipient,
            uint256 protocolFeeMultiplier,
            address seacowsCollectionRegistry,
            address chainlinkToken,
            address chainlinkOracle,
            string memory chainlinkJobId
        ) = helperConfig.activeNetworkConfig();

        vm.startBroadcast();

        /** deploy SeacowsPairEnumerableETH */
        // seacowsPairEnumerableETH = new SeacowsPairEnumerableETH(lpUri);

        /** deploy SeacowsPairMissingEnumerableETH */
        // seacowsPairMissingEnumerableETH = new SeacowsPairMissingEnumerableETH(lpUri);

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
            weth,
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

        /** update SeacowsPairFactory in ChainlinkAggregator*/
        chainlinkAggregator.updateSeacowsPairFactory(ISeacowsPairFactoryLike(seacowsPairFactory));

        /** deploy SeacowsRouter */
        seacowsRouter = new SeacowsRouter(ISeacowsPairFactoryLike(seacowsPairFactory));

        vm.stopBroadcast();
    }
}
