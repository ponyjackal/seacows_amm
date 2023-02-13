// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { SeacowsPairERC20 } from "./SeacowsPairERC20.sol";
import { SeacowsPairEnumerable } from "./SeacowsPairEnumerable.sol";
import { ISeacowsPairFactoryLike } from "./interfaces/ISeacowsPairFactoryLike.sol";
import { SeacowsRouter } from "./SeacowsRouter.sol";
import { ICurve } from "./bondingcurve/ICurve.sol";
import { CurveErrorCodes } from "./bondingcurve/CurveErrorCodes.sol";

/**
    @title An NFT/Token pair where the NFT implements ERC721Enumerable, and the token is an ERC20
    Inspired by 0xmons; Modified from https://github.com/sudoswap/lssvm
 */
contract SeacowsPairEnumerableERC20 is SeacowsPairEnumerable, SeacowsPairERC20 {
    uint256 internal constant IMMUTABLE_PARAMS_LENGTH = 81;

    constructor(string memory _uri) SeacowsPairEnumerable(_uri) {}

    /**
        @notice Returns the SeacowsPair type
     */
    function pairVariant() public pure override returns (ISeacowsPairFactoryLike.PairVariant) {
        return ISeacowsPairFactoryLike.PairVariant.ENUMERABLE_ERC20;
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
