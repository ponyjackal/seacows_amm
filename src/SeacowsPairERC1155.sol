// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { SeacowsPair } from "./SeacowsPair.sol";
import { ISeacowsPairFactoryLike } from "./interfaces/ISeacowsPairFactoryLike.sol";
import { ICurve } from "./bondingcurve/ICurve.sol";
import { CurveErrorCodes } from "./bondingcurve/CurveErrorCodes.sol";

/**
    @title An NFT/Token pair for an NFT that implements ERC721Enumerable
    Inspired by 0xmons; Modified from https://github.com/sudoswap/lssvm
 */
abstract contract SeacowsPairERC1155 is SeacowsPair {
    constructor(string memory _uri) SeacowsPair(_uri) {}

    /**
        @notice Returns the ERC1155 token id associated with the pair
        @dev See SeacowsPairCloner for an explanation on how this works
     */
    function tokenId() public pure virtual returns (uint256 _tokenId);

    /// @inheritdoc SeacowsPair
    function _sendAnyNFTsToRecipient(address _nft, address nftRecipient, uint256 numNFTs) internal override {
        // Send NFTs to recipient
        IERC1155(_nft).safeTransferFrom(address(this), nftRecipient, tokenId(), numNFTs, "");
    }

    function withdrawERC1155(address _recipient, uint256 _amount) external onlyWithdrawable {
        require(poolType() == PoolType.TRADE, "Invalid pool type");
        IERC1155(nft()).safeTransferFrom(address(this), _recipient, tokenId(), _amount, "");

        emit NFTWithdrawal(_recipient, _amount);
    }

    /** Deprecated functions, just overrided based on design pattern */
    /// @inheritdoc SeacowsPair
    function _sendSpecificNFTsToRecipient(address _nft, address nftRecipient, uint256[] calldata nftIds) internal override {}

    /// @inheritdoc SeacowsPair
    function getAllHeldIds() external view override returns (uint256[] memory) {
        uint256[] memory res;
        return res;
    }
}
