// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { SeacowsPairERC20 } from "./SeacowsPairERC20.sol";
import { SeacowsPairEnumerable } from "./SeacowsPairEnumerable.sol";
import { ISeacowsPairFactoryLike } from "./ISeacowsPairFactoryLike.sol";

/**
    @title An NFT/Token pair where the NFT implements ERC721Enumerable, and the token is an ERC20
    Inspired by 0xmons; Modified from https://github.com/sudoswap/lssvm
 */
contract SeacowsPairEnumerableERC20 is SeacowsPairEnumerable, SeacowsPairERC20 {
    /**
        @notice Returns the SeacowsPair type
     */
    function pairVariant() public pure override returns (ISeacowsPairFactoryLike.PairVariant) {
        return ISeacowsPairFactoryLike.PairVariant.ENUMERABLE_ERC20;
    }
}