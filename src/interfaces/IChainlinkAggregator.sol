// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import { SeacowsPairETH } from "../SeacowsPairETH.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IChainlinkAggregator {
    function requestCryptoPrice(
        SeacowsPairETH _pair,
        IERC721 _nft,
        address payable _assetRecipient,
        uint128 _delta,
        uint96 _fee,
        uint256[] calldata _initialNFTIDs
    ) external returns (bytes32);
}
