// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import { TestWETH } from "../src/TestCollectionToken/TestWETH.sol";

contract HelperConfig {
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        string lpUri;
        address weth;
        address payable protocolFeeRecipient;
        uint256 protocolFeeMultiplier;
    }

    mapping(uint256 => NetworkConfig) public chainIdToNetworkConfig;

    constructor() {
        chainIdToNetworkConfig[5] = getGoerliEthConfig();
        chainIdToNetworkConfig[31337] = getAnvilEthConfig();

        activeNetworkConfig = chainIdToNetworkConfig[block.chainid];
    }

    function getGoerliEthConfig() internal pure returns (NetworkConfig memory goerliNetworkConfig) {
        goerliNetworkConfig = NetworkConfig({
            lpUri: "",
            weth: 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6,
            protocolFeeRecipient: payable(address(0)),
            protocolFeeMultiplier: 5000000000000000
        });
    }

    function getAnvilEthConfig() internal returns (NetworkConfig memory anvilNetworkConfig) {
        TestWETH weth = new TestWETH();
        anvilNetworkConfig = NetworkConfig({
            lpUri: "",
            weth: address(weth),
            protocolFeeRecipient: payable(address(0)),
            protocolFeeMultiplier: 5000000000000000
        });
    }
}
