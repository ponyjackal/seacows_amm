// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {SeacowsPairETH} from "./SeacowsPairETH.sol";
import {SeacowsPairMissingEnumerable} from "./SeacowsPairMissingEnumerable.sol";
import {ISeacowsPairFactoryLike} from "./ISeacowsPairFactoryLike.sol";

contract SeacowsPairMissingEnumerableETH is
    SeacowsPairMissingEnumerable,
    SeacowsPairETH
{
    function pairVariant()
        public
        pure
        override
        returns (ISeacowsPairFactoryLike.PairVariant)
    {
        return ISeacowsPairFactoryLike.PairVariant.MISSING_ENUMERABLE_ETH;
    }
}
