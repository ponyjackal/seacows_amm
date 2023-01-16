// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract HelperConfig {
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        string lpUri;
        address weth;
        address payable protocolFeeRecipient;
        uint256 protocolFeeMultiplier;
        address seacowsCollectionRegistry;
        address chainlinkToken;
        address chainlinkOracle;
        string chainlinkJobId;
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
            protocolFeeMultiplier: 5000000000000000,
            seacowsCollectionRegistry: address(0),
            chainlinkToken: 0x326C977E6efc84E512bB9C30f76E30c160eD06FB,
            chainlinkOracle: 0xCC79157eb46F5624204f47AB42b3906cAA40eaB7,
            chainlinkJobId: "ca98366cc7314957b8c012c72f05aeeb"
        });
    }

    function getAnvilEthConfig() internal pure returns (NetworkConfig memory anvilNetworkConfig) {
        anvilNetworkConfig = NetworkConfig({
            lpUri: "",
            weth: 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6, // TODO: change to the correct weth
            protocolFeeRecipient: payable(address(0)),
            protocolFeeMultiplier: 5000000000000000,
            seacowsCollectionRegistry: address(0),
            chainlinkToken: address(0),
            chainlinkOracle: address(0),
            chainlinkJobId: ""
        });
    }
}
