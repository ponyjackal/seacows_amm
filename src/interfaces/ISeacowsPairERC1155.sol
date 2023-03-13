// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import { ISeacowsPair } from "./ISeacowsPair.sol";
import { SeacowsRouter } from "../SeacowsRouter.sol";

interface ISeacowsPairERC1155 is ISeacowsPair {
    function nftAmount() external view returns (uint256 nftAmount);

    function nftIds() external view returns (uint256[] memory nftIds);

    function swapTokenForAnyNFTs(uint256 numNFTs, uint256 maxExpectedTokenInput, address nftRecipient, bool isRouter, address routerCaller)
        external
        payable
        returns (uint256 inputAmount);

    function swapNFTsForToken(
        uint256[] calldata nftIds,
        SeacowsRouter.NFTDetail[] calldata details,
        uint256 minExpectedTokenOutput,
        address payable tokenRecipient,
        bool isRouter,
        address routerCaller
    ) external returns (uint256 outputAmount);

    function withdrawERC1155(address _recipient, uint256 _amount) external;

    function setNFTIds(uint256[] memory _nftIds, uint256 _nftAmount) external;
}
