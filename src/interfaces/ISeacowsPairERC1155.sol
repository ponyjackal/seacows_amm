// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import { ISeacowsPair } from "./ISeacowsPair.sol";

interface ISeacowsPairERC1155 is ISeacowsPair {
    function nftAmount() external view returns (uint256 nftAmount);

    function getNFTIds() external view returns (uint256[] memory nftIds);

    function isValidNFTID(uint256 _id) external view returns (bool);

    function swapTokenForNFTs(
        uint256[] memory _nftIds,
        uint256[] memory _amounts,
        uint256 maxExpectedTokenInput,
        address nftRecipient
    ) external returns (uint256 inputAmount);

    function swapNFTsForToken(
        uint256[] memory _nftIds,
        uint256[] memory _amounts,
        uint256 minExpectedTokenOutput,
        address payable tokenRecipient
    ) external returns (uint256 outputAmount);

    function withdrawERC1155(address _recipient, uint256[] memory _nftIds, uint256[] memory _amounts) external;

    function setNFTIds(uint256[] memory _nftIds) external;

    function addNFTAmount(uint256 _nftAmount) external;

    function removeNFTAmount(uint256 _nftAmount) external;
}
