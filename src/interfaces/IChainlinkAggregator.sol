// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ERC20 } from "../solmate/ERC20.sol";
import { ISeacowsPairETH } from "./ISeacowsPairETH.sol";
import { ISeacowsPairERC20 } from "./ISeacowsPairERC20.sol";

interface IChainlinkAggregator {
    function requestCryptoPriceETH(
        ISeacowsPairETH _pair,
        IERC721 _nft,
        address payable _assetRecipient,
        uint128 _delta,
        uint96 _fee,
        uint256[] calldata _initialNFTIDs
    ) external returns (bytes32);

    function requestCryptoPriceERC20(
        ISeacowsPairERC20 _pair,
        ERC20 _token,
        IERC721 _nft,
        address payable _assetRecipient,
        uint128 _delta,
        uint96 _fee,
        uint256[] calldata _initialNFTIDs,
        uint256 _initialTokenBalance
    ) external returns (bytes32);
}
