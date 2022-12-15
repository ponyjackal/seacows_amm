// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract HelperConfig {
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        string lpUri;
        address payable protocolFeeRecipient;
        uint256 protocolFeeMultiplier;
        address seacowsCollectionRegistry;
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
            protocolFeeRecipient: payable(address(0)),
            protocolFeeMultiplier: 5000000000000000,
            seacowsCollectionRegistry: address(0)
        });
    }

    function getAnvilEthConfig() internal pure returns (NetworkConfig memory anvilNetworkConfig) {
        anvilNetworkConfig = NetworkConfig({
            lpUri: "",
            protocolFeeRecipient: payable(address(0)),
            protocolFeeMultiplier: 5000000000000000,
            seacowsCollectionRegistry: address(0)
        });
    }
}
