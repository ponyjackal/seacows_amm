// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { SeacowsRouter } from "./SeacowsRouter.sol";
import { SeacowsPairETH } from "./SeacowsPairETH.sol";
import { SeacowsPairERC20 } from "./SeacowsPairERC20.sol";
import { ERC20 } from "./solmate/ERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

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

    function initializePairETHFromOracle(
        SeacowsPairETH pair,
        IERC721 _nft,
        address payable _assetRecipient,
        uint128 _delta,
        uint96 _fee,
        uint128 _spotPrice,
        uint256[] calldata _initialNFTIDs
    ) external;

    function initializePairERC20FromOracle(
        SeacowsPairERC20 pair,
        ERC20 _token,
        IERC721 _nft,
        address payable _assetRecipient,
        uint128 _delta,
        uint96 _fee,
        uint128 _spotPrice,
        uint256[] calldata _initialNFTIDs,
        uint256 _initialTokenBalance
    ) external;
}
