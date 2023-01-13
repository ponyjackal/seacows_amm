// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { SeacowsRouter } from "../SeacowsRouter.sol";
import { ISeacowsPairFactoryLike } from "./ISeacowsPairFactoryLike.sol";
import { ICurve } from "../bondingcurve/ICurve.sol";

interface ISeacowsPair {
    enum PoolType {
        TOKEN,
        NFT,
        TRADE
    }

    function initialize(
        address _owner,
        address payable _assetRecipient,
        uint128 _delta,
        uint96 _fee,
        uint128 _spotPrice
    ) external;

    function swapTokenForAnyNFTs(
        uint256 numNFTs,
        uint256 maxExpectedTokenInput,
        address nftRecipient,
        bool isRouter,
        address routerCaller
    ) external;

    function swapTokenForSpecificNFTs(
        uint256[] calldata nftIds,
        SeacowsRouter.NFTDetail[] calldata details,
        uint256 maxExpectedTokenInput,
        address nftRecipient,
        bool isRouter,
        address routerCaller
    ) external;

    function swapNFTsForToken(
        uint256[] calldata nftIds,
        SeacowsRouter.NFTDetail[] calldata details,
        uint256 minExpectedTokenOutput,
        address payable tokenRecipient,
        bool isRouter,
        address routerCaller
    ) external;

    function getBuyNFTQuote(uint256[] memory nftIds, SeacowsRouter.NFTDetail[] memory details) external;

    function getSellNFTQuote(uint256[] memory nftIds, SeacowsRouter.NFTDetail[] memory details) external;

    function getAllHeldIds() external view returns (uint256[] memory);

    function pairVariant() external pure returns (ISeacowsPairFactoryLike.PairVariant);

    function factory() external pure returns (ISeacowsPairFactoryLike _factory);

    function bondingCurve() external pure returns (ICurve _bondingCurve);

    function nft() external pure returns (IERC721 _nft);

    function poolType() external pure returns (PoolType _poolType);

    function getAssetRecipient() external view returns (address payable _assetRecipient);

    function withdrawERC721(IERC721 a, uint256[] calldata nftIds) external;

    function withdrawERC20(ERC20 a, uint256 amount) external;

    function changeSpotPrice(uint128 newSpotPrice) external;

    function changeDelta(uint128 newDelta) external;

    function changeFee(uint96 newFee) external;

    function changeAssetRecipient(address payable newRecipient) external;

    function call(address payable target, bytes calldata data) external;

    function multicall(bytes[] calldata calls, bool revertOnFail) external;
}
