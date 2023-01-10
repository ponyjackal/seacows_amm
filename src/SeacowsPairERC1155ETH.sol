// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { ISeacowsPairFactoryLike } from "./interfaces/ISeacowsPairFactoryLike.sol";
import { SeacowsPairERC1155 } from "./SeacowsPairERC1155.sol";
import { SeacowsPairETH } from "./SeacowsPairETH.sol";

/**
    @title An NFT/Token pair for an NFT that implements ERC721Enumerable
    Inspired by 0xmons; Modified from https://github.com/sudoswap/lssvm
 */
contract SeacowsPairERC1155ETH is SeacowsPairERC1155, SeacowsPairETH {
    constructor(string memory _uri) SeacowsPairERC1155(_uri) {}

    uint256 internal constant IMMUTABLE_PARAMS_LENGTH = 81;

    /**
        @notice Returns the ERC1155 token id associated with the pair
        @dev See SeacowsPairCloner for an explanation on how this works
     */
    function tokenId() public pure override returns (uint256 _tokenId) {
        uint256 paramsLength = _immutableParamsLength();
        assembly {
            _tokenId := shr(0x60, calldataload(add(sub(calldatasize(), paramsLength), 81)))
        }
    }

    /**
        @notice Returns the SeacowsPair type
     */
    function pairVariant() public pure override returns (ISeacowsPairFactoryLike.PairVariant) {
        return ISeacowsPairFactoryLike.PairVariant.ERC1155_ETH;
    }

    // @dev see SeacowsPairCloner for params length calculation
    function _immutableParamsLength() internal pure override returns (uint256) {
        return IMMUTABLE_PARAMS_LENGTH;
    }
}
