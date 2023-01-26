// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { SeacowsPairERC20 } from "./SeacowsPairERC20.sol";
import { SeacowsPairMissingEnumerable } from "./SeacowsPairMissingEnumerable.sol";
import { ISeacowsPairFactoryLike } from "./interfaces/ISeacowsPairFactoryLike.sol";
import { SeacowsRouter } from "./SeacowsRouter.sol";
import { ICurve } from "./bondingcurve/ICurve.sol";
import { CurveErrorCodes } from "./bondingcurve/CurveErrorCodes.sol";

contract SeacowsPairMissingEnumerableERC20 is SeacowsPairMissingEnumerable, SeacowsPairERC20 {
    uint256 internal constant IMMUTABLE_PARAMS_LENGTH = 81;

    constructor(string memory _uri) SeacowsPairMissingEnumerable(_uri) {}

    function pairVariant() public pure override returns (ISeacowsPairFactoryLike.PairVariant) {
        return ISeacowsPairFactoryLike.PairVariant.MISSING_ENUMERABLE_ERC20;
    }

    // @dev see SeacowsPairCloner for params length calculation
    function _immutableParamsLength() internal pure override returns (uint256) {
        return IMMUTABLE_PARAMS_LENGTH;
    }

    /**
     * @notice get reserves in the pool, only available for trade pair
     */
    function _getReserve() internal view override returns (uint256 nftReserve, uint256 tokenReserve) {
        // nft balance
        nftReserve = IERC721(nft()).balanceOf(address(this));
        // token balance
        tokenReserve = token().balanceOf(address(this));
    }
}
