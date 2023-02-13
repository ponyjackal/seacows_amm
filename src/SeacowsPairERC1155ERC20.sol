// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { ISeacowsPairFactoryLike } from "./interfaces/ISeacowsPairFactoryLike.sol";
import { SeacowsPairERC1155 } from "./SeacowsPairERC1155.sol";
import { SeacowsPairERC20 } from "./SeacowsPairERC20.sol";
import { SeacowsRouter } from "./SeacowsRouter.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
    @title An NFT/Token pair for an NFT that implements ERC721Enumerable
    Inspired by 0xmons; Modified from https://github.com/sudoswap/lssvm
 */
contract SeacowsPairERC1155ERC20 is SeacowsPairERC1155, SeacowsPairERC20 {
    using SafeERC20 for ERC20;

    constructor(string memory _uri) SeacowsPairERC1155(_uri) {}

    uint256 internal constant IMMUTABLE_PARAMS_LENGTH = 113;

    /**
        @notice Returns the ERC1155 token id associated with the pair
        @dev See SeacowsPairCloner for an explanation on how this works
     */
    function tokenId() public pure override returns (uint256 _tokenId) {
        uint256 paramsLength = _immutableParamsLength();
        assembly {
            _tokenId := shr(0x60, calldataload(add(sub(calldatasize(), paramsLength), 81)))
        }
    }

    /**
        @notice Returns the SeacowsPair type
     */
    function pairVariant() public pure override returns (ISeacowsPairFactoryLike.PairVariant) {
        return ISeacowsPairFactoryLike.PairVariant.ERC1155_ERC20;
    }

    // @dev see SeacowsPairCloner for params length calculation
    function _immutableParamsLength() internal pure override returns (uint256) {
        return IMMUTABLE_PARAMS_LENGTH;
    }

    /**
        @notice Takes NFTs from the caller and sends them into the pair's asset recipient
        @dev This is used by the SeacowsPair's swapNFTForToken function.
        @param _nft The NFT collection to take from
        @param nftIds The specific NFT IDs to take, we just need the length of IDs, no need the values in it
        @param isRouter True if calling from SeacowsRouter, false otherwise. Not used for
        ETH pairs.
        @param routerCaller If isRouter is true, ERC20 tokens will be transferred from this address. Not used for
        ETH pairs.
     */
    function _takeNFTsFromSender(address _nft, uint256[] calldata nftIds, ISeacowsPairFactoryLike _factory, bool isRouter, address routerCaller)
        internal
        override
    {
        {
            address _assetRecipient = getAssetRecipient();
            uint256 _tokenId = tokenId();
            uint256 numNFTs = nftIds.length;

            if (isRouter) {
                // Verify if router is allowed
                SeacowsRouter router = SeacowsRouter(payable(msg.sender));
                (bool routerAllowed, ) = _factory.routerStatus(router);
                require(routerAllowed, "Not router");

                // Call router to pull NFTs
                uint256 beforeBalance = IERC1155(_nft).balanceOf(_assetRecipient, _tokenId);
                IERC1155(_nft).safeTransferFrom(msg.sender, _assetRecipient, _tokenId, numNFTs, "");
                router.pairTransferNFTFromERC1155(IERC1155(_nft), _tokenId, routerCaller, _assetRecipient, numNFTs, pairVariant());

                require((IERC1155(_nft).balanceOf(_assetRecipient, _tokenId) - beforeBalance) == numNFTs, "NFTs not transferred");
            } else {
                // Pull NFTs directly from sender
                IERC1155(_nft).safeTransferFrom(msg.sender, _assetRecipient, _tokenId, numNFTs, "");
            }
        }
    }

    /**
     * @notice get reserves in the pool, only available for trade pair
     */
    function _getReserve() internal view override returns (uint256 nftReserve, uint256 tokenReserve) {
        // nft balance
        nftReserve = IERC1155(nft()).balanceOf(address(this), tokenId());
        // token balance
        tokenReserve = token().balanceOf(address(this));
    }
}
