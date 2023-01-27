// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { SeacowsRouter } from "./SeacowsRouter.sol";
import { SeacowsPair } from "./SeacowsPair.sol";
import { ISeacowsPairFactoryLike } from "./interfaces/ISeacowsPairFactoryLike.sol";

/**
    @title An NFT/Token pair for an NFT that implements ERC721Enumerable
    Inspired by 0xmons; Modified from https://github.com/sudoswap/lssvm
 */
abstract contract SeacowsPairEnumerable is SeacowsPair {
    constructor(string memory _uri) SeacowsPair(_uri) {}

    /// @inheritdoc SeacowsPair
    function _sendAnyNFTsToRecipient(address _nft, address nftRecipient, uint256 numNFTs) internal override {
        // Send NFTs to recipient
        // (we know NFT implements IERC721Enumerable so we just iterate)
        uint256 lastIndex = IERC721(_nft).balanceOf(address(this)) - 1;
        for (uint256 i = 0; i < numNFTs; ) {
            uint256 nftId = IERC721Enumerable(address(_nft)).tokenOfOwnerByIndex(address(this), lastIndex);
            IERC721(_nft).safeTransferFrom(address(this), nftRecipient, nftId);

            unchecked {
                --lastIndex;
                ++i;
            }
        }
    }

    /// @inheritdoc SeacowsPair
    function _sendSpecificNFTsToRecipient(address _nft, address nftRecipient, uint256[] calldata nftIds) internal override {
        // Send NFTs to recipient
        uint256 numNFTs = nftIds.length;
        for (uint256 i; i < numNFTs; ) {
            IERC721(_nft).safeTransferFrom(address(this), nftRecipient, nftIds[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc SeacowsPair
    function getAllHeldIds() external view override returns (uint256[] memory) {
        IERC721 _nft = IERC721(nft());
        uint256 numNFTs = _nft.balanceOf(address(this));
        uint256[] memory ids = new uint256[](numNFTs);
        for (uint256 i; i < numNFTs; ) {
            ids[i] = IERC721Enumerable(address(_nft)).tokenOfOwnerByIndex(address(this), i);

            unchecked {
                ++i;
            }
        }
        return ids;
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function withdrawERC721(IERC721 a, uint256[] calldata nftIds) external onlyOwner {
        require(poolType() == PoolType.NFT, "Invalid pool type");
        uint256 numNFTs = nftIds.length;
        for (uint256 i; i < numNFTs; ) {
            a.safeTransferFrom(address(this), msg.sender, nftIds[i]);

            unchecked {
                ++i;
            }
        }

        emit NFTWithdrawal(msg.sender, numNFTs);
    }
}
