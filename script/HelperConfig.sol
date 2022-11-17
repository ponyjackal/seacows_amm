// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract HelperConfig {
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        address seacowsPairEnumerableETH;
        address seacowsPairMissingEnumerableETH;
        address seacowsPairEnumerableERC20;
        address seacowsPairMissingEnumerableERC20;
        address payable protocolFeeRecipient;
        uint256 protocol_feemultiplier;
        address seacowscollectionRegistry;
        address seacowsPairFactory;
    }

    mapping(uint256 => NetworkConfig) public chainIdToNetworkConfig;

    constructor() {
        chainIdToNetworkConfig[5] = getGoerliEthConfig();
        chainIdToNetworkConfig[31337] = getAnvilEthConfig();

        activeNetworkConfig = chainIdToNetworkConfig[block.chainid];
    }

    function getGoerliEthConfig() internal pure returns (NetworkConfig memory goerliNetworkConfig) {
        goerliNetworkConfig = NetworkConfig({
            seacowsPairEnumerableETH: address(0),
            seacowsPairMissingEnumerableETH: address(0),
            seacowsPairEnumerableERC20: address(0),
            seacowsPairMissingEnumerableERC20: address(0),
            protocolFeeRecipient: payable(address(0)),
            protocol_feemultiplier: 5000000000000000,
            seacowscollectionRegistry: address(0),
            seacowsPairFactory: address(0)
        });
    }

    function getAnvilEthConfig() internal pure returns (NetworkConfig memory anvilNetworkConfig) {
        anvilNetworkConfig = NetworkConfig({
            seacowsPairEnumerableETH: address(0),
            seacowsPairMissingEnumerableETH: address(0),
            seacowsPairEnumerableERC20: address(0),
            seacowsPairMissingEnumerableERC20: address(0),
            protocolFeeRecipient: payable(address(0)),
            protocol_feemultiplier: 5000000000000000,
            seacowscollectionRegistry: address(0),
            seacowsPairFactory: address(0)
        });
    }
}
