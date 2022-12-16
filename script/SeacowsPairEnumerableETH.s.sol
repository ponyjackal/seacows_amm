// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import { Script } from "forge-std/Script.sol";
import { HelperConfig } from "./HelperConfig.sol";
import { SeacowsPairEnumerableETH } from "../src/SeacowsPairEnumerableETH.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract DeploySeacowsPairEnumerableETH is Script {
    SeacowsPairEnumerableETH internal seacowsPairEnumerableETH;

    function run() public {
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

        vm.startBroadcast();

        /** deploy SeacowsPairEnumerableETH */
        seacowsPairEnumerableETH = new SeacowsPairEnumerableETH(lpUri);

        vm.stopBroadcast();
    }
}
