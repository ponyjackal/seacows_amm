// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { SeacowsRouter } from "./SeacowsRouter.sol";

interface ISeacowsPairFactoryLike {
    enum PairVariant {
        ENUMERABLE_ETH,
        MISSING_ENUMERABLE_ETH,
        ENUMERABLE_ERC20,
        MISSING_ENUMERABLE_ERC20
    }

    function protocolFeeMultiplier() external view returns (uint256);

    function protocolFeeRecipient() external view returns (address payable);

    function priceOracleRegistry() external view returns (address);

    function callAllowed(address target) external view returns (bool);

    function routerStatus(SeacowsRouter router) external view returns (bool allowed, bool wasEverAllowed);

    function isPair(address potentialPair, PairVariant variant) external view returns (bool);
}
