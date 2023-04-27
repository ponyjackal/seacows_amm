// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ISeacowsPair } from "./ISeacowsPair.sol";
import { CurveErrorCodes } from "../bondingcurve/CurveErrorCodes.sol";

interface ISeacowsPairERC721 is ISeacowsPair {
    function swapTokenForNFTs(uint256[] calldata nftIds, uint256 maxExpectedTokenInput, address nftRecipient)
        external
        payable
        returns (uint256 inputAmount);

    function swapNFTsForToken(uint256[] calldata nftIds, uint256 minExpectedTokenOutput, address payable tokenRecipient)
        external
        returns (uint256 outputAmount);

    function getAllHeldIds() external view returns (uint256[] memory);

    function onERC721Received(address, address, uint256, bytes memory) external returns (bytes4);

    function withdrawERC721(uint256[] calldata nftIds) external;

    function depositERC721(uint256[] calldata ids) external;
}
