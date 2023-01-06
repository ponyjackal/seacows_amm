// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { SeacowsRouter } from "./SeacowsRouter.sol";
import { SeacowsPair } from "./SeacowsPair.sol";

/**
    @title An NFT/Token pair for an NFT that implements ERC721Enumerable
    Inspired by 0xmons; Modified from https://github.com/sudoswap/lssvm
 */
abstract contract SeacowsPairERC1155 is SeacowsPair {
    uint256 public tokenId;

    constructor(string memory _uri) SeacowsPair(_uri) {}

    /// @inheritdoc SeacowsPair
    function _sendAnyNFTsToRecipient(address _nft, address nftRecipient, uint256 numNFTs) internal override {
        // Send NFTs to recipient
        IERC1155(_nft).safeTransferFrom(address(this), nftRecipient, tokenId, numNFTs, "");
    }

    /// @inheritdoc SeacowsPair
    function withdrawERC1155(address _nft, uint256 numNFTs) external override onlyOwner {
        IERC1155(_nft).safeTransferFrom(address(this), msg.sender, tokenId, numNFTs, "");
    }
}
