// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { ISeacowsPairFactoryLike } from "./ISeacowsPairFactoryLike.sol";
import { ICurve } from "../bondingcurve/ICurve.sol";
import { SeacowsPair } from "../SeacowsPair.sol";

interface ISeacowsPair {
    function initialize(address _owner, address payable _assetRecipient, uint128 _delta, uint96 _fee, uint128 _spotPrice) external payable;

    function pairVariant() external pure returns (ISeacowsPairFactoryLike.PairVariant);

    function owner() external view returns (address);

    function factory() external pure returns (ISeacowsPairFactoryLike _factory);

    function bondingCurve() external pure returns (ICurve _bondingCurve);

    function nft() external pure returns (address _nft);

    function spotPrice() external view returns (uint128 spotPrice);

    function delta() external view returns (uint128 delta);

    function fee() external view returns (uint96 fee);

    function isProtocolFeeEnabled() external view returns (bool isProtocolFeeEnabled);

    function poolType() external pure returns (SeacowsPair.PoolType _poolType);

    function token() external returns (ERC20 _token);

    function getAssetRecipient() external view returns (address payable _assetRecipient);

    function withdrawERC20(address recipient, uint256 amount) external;

    function withdrawERC721(IERC721 a, uint256[] calldata nftIds) external;

    function changeSpotPrice(uint128 newSpotPrice) external;

    function changeDelta(uint128 newDelta) external;

    function changeFee(uint96 newFee) external;

    function changeAssetRecipient(address payable newRecipient) external;

    function call(address payable target, bytes calldata data) external;

    function multicall(bytes[] calldata calls, bool revertOnFail) external;

    function mintLPToken(address recipient, uint256 amount) external;

    function burnLPToken(address recipient, uint256 amount) external;
}
