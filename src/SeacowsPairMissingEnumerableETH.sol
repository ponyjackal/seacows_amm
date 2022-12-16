// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { SeacowsPairETH } from "./SeacowsPairETH.sol";
import { SeacowsPairMissingEnumerable } from "./SeacowsPairMissingEnumerable.sol";
import { ISeacowsPairFactoryLike } from "./interfaces/ISeacowsPairFactoryLike.sol";
import { SeacowsRouter } from "./SeacowsRouter.sol";
import { ICurve } from "./bondingcurve/ICurve.sol";
import { CurveErrorCodes } from "./bondingcurve/CurveErrorCodes.sol";

contract SeacowsPairMissingEnumerableETH is SeacowsPairMissingEnumerable, SeacowsPairETH {
    constructor(string memory _uri) SeacowsPairMissingEnumerable(_uri) {}

    function pairVariant() public pure override returns (ISeacowsPairFactoryLike.PairVariant) {
        return ISeacowsPairFactoryLike.PairVariant.MISSING_ENUMERABLE_ETH;
    }
}
