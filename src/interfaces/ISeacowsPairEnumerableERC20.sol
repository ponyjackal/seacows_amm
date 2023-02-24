// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ISeacowsPair } from "./ISeacowsPair.sol";
import { SeacowsRouter } from "../SeacowsRouter.sol";
import { CurveErrorCodes } from "../bondingcurve/CurveErrorCodes.sol";

interface ISeacowsPairEnumerableERC20 is ISeacowsPair {
    function swapTokenForAnyNFTs(uint256 numNFTs, uint256 maxExpectedTokenInput, address nftRecipient, bool isRouter, address routerCaller)
        external
        payable
        returns (uint256 inputAmount);

    function swapTokenForSpecificNFTs(
        uint256[] calldata nftIds,
        SeacowsRouter.NFTDetail[] calldata details,
        uint256 maxExpectedTokenInput,
        address nftRecipient,
        bool isRouter,
        address routerCaller
    ) external payable returns (uint256 inputAmount);

    function swapNFTsForToken(
        uint256[] calldata nftIds,
        SeacowsRouter.NFTDetail[] calldata details,
        uint256 minExpectedTokenOutput,
        address payable tokenRecipient,
        bool isRouter,
        address routerCaller
    ) external returns (uint256 outputAmount);

    function getBuyNFTQuote(uint256[] memory nftIds, SeacowsRouter.NFTDetail[] memory details)
        external
        returns (CurveErrorCodes.Error error, uint256 newSpotPrice, uint256 newDelta, uint256 inputAmount, uint256 protocolFee);

    function getSellNFTQuote(uint256[] memory nftIds, SeacowsRouter.NFTDetail[] memory details)
        external
        returns (CurveErrorCodes.Error error, uint256 newSpotPrice, uint256 newDelta, uint256 outputAmount, uint256 protocolFee);

    function getAllHeldIds() external view returns (uint256[] memory);

    function onERC721Received(address, address, uint256, bytes memory) external returns (bytes4);

    function withdrawERC721(IERC721 a, uint256[] calldata nftIds) external override;

    function getReserve() external view returns (uint256 nftReserve, uint256 tokenReserve);
}
