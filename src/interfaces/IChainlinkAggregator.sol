// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ISeacowsPair } from "./ISeacowsPair.sol";

interface IChainlinkAggregator {
    function requestCryptoPriceERC20(
        ISeacowsPair _pair,
        ERC20 _token,
        IERC721 _nft,
        address payable _assetRecipient,
        uint128 _delta,
        uint96 _fee,
        uint256[] calldata _initialNFTIDs,
        uint256 _initialTokenBalance
    ) external returns (bytes32);
}
