// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { SeacowsPairERC20 } from "./SeacowsPairERC20.sol";
import { SeacowsPairMissingEnumerable } from "./SeacowsPairMissingEnumerable.sol";
import { ISeacowsPairFactoryLike } from "./ISeacowsPairFactoryLike.sol";

contract SeacowsPairMissingEnumerableERC20 is SeacowsPairMissingEnumerable, SeacowsPairERC20 {
    function pairVariant() public pure override returns (ISeacowsPairFactoryLike.PairVariant) {
        return ISeacowsPairFactoryLike.PairVariant.MISSING_ENUMERABLE_ERC20;
    }
}