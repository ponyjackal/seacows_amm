// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { ISeacowsPairFactoryLike } from "./ISeacowsPairFactoryLike.sol";
import { ICurve } from "../bondingcurve/ICurve.sol";
import { SeacowsPair } from "../pairs/SeacowsPair.sol";
import { CurveErrorCodes } from "../bondingcurve/CurveErrorCodes.sol";

interface ISeacowsPair {
    function initialize(address _owner, address payable _assetRecipient, uint128 _delta, uint96 _fee, uint128 _spotPrice) external payable;

    /** view functions */

    function pairVariant() external pure returns (ISeacowsPairFactoryLike.PairVariant);

    function owner() external view returns (address);

    function factory() external pure returns (ISeacowsPairFactoryLike _factory);

    function bondingCurve() external pure returns (ICurve _bondingCurve);

    function nft() external pure returns (address _nft);

    function spotPrice() external view returns (uint128 spotPrice);

    function delta() external view returns (uint128 delta);

    function fee() external view returns (uint96 fee);

    function token() external returns (IERC20 _token);

    function poolType() external pure returns (SeacowsPair.PoolType _poolType);

    function isProtocolFeeDisabled() external view returns (bool isProtocolFeeDisabled);

    function getAssetRecipient() external view returns (address payable _assetRecipient);

    function getReserves() external view returns (uint256 _nftReserve, uint256 _tokenReserve, uint256 _blockTimestampLast);

    function getBuyNFTQuote(uint256 numOfNfts)
        external
        returns (CurveErrorCodes.Error error, uint256 newSpotPrice, uint256 newDelta, uint256 inputAmount, uint256 protocolFee);

    function getSellNFTQuote(uint256 numOfNfts)
        external
        returns (CurveErrorCodes.Error error, uint256 newSpotPrice, uint256 newDelta, uint256 outputAmount, uint256 protocolFee);

    /** mutative functions */

    function withdrawERC20(address recipient, uint256 amount) external;

    function changeSpotPrice(uint128 newSpotPrice) external;

    function changeDelta(uint128 newDelta) external;

    function changeAssetRecipient(address payable newRecipient) external;

    function syncReserve() external;
}
