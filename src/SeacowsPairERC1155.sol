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

    // /**
    //     @notice Sends a set of ERC115 NFTs to the pair in exchange for token
    //     @dev To compute the amount of token to that will be received, call bondingCurve.getSellInfo.
    //     @param numNFTs The amount of erc1155 nft amount
    //     @param minExpectedTokenOutput The minimum acceptable token received by the sender. If the actual
    //     amount is less than this value, the transaction will be reverted.
    //     @param tokenRecipient The recipient of the token output
    //     @param isRouter True if calling from SeacowsRouter, false otherwise. Not used for
    //     ETH pairs.
    //     @param routerCaller If isRouter is true, ERC20 tokens will be transferred from this address. Not used for
    //     ETH pairs.
    //     @return outputAmount The amount of token received
    //  */
    // function swapNFTsForTokenERC1155(
    //     uint256 numNFTs,
    //     uint256 minExpectedTokenOutput,
    //     address payable tokenRecipient,
    //     bool isRouter,
    //     address routerCaller
    // ) external virtual nonReentrant returns (uint256 outputAmount) {
    //     // Store locally to remove extra calls
    //     ISeacowsPairFactoryLike _factory = factory();
    //     ICurve _bondingCurve = bondingCurve();

    //     // Input validation
    //     {
    //         PoolType _poolType = poolType();
    //         require(_poolType == PoolType.TRADE, "Wrong Pool type");
    //         require(numNFTs > 0, "Must ask for > 0 NFTs");
    //     }

    //     // Call bonding curve for pricing information
    //     uint256 protocolFee;
    //     (protocolFee, outputAmount) = _calculateSellInfoAndUpdatePoolParamsERC1155(numNFTs, minExpectedTokenOutput, _bondingCurve, _factory);

    //     _sendTokenOutput(tokenRecipient, outputAmount);

    //     _payProtocolFeeFromPair(_factory, protocolFee);

    //     _takeNFTsFromSenderERC1155(numNFTs, _factory, isRouter, routerCaller);

    //     emit SwapNFTInPair();
    // }

    // /**
    //     @notice Calculates the amount needed to be sent by the pair for a sell and adjusts spot price or delta if necessary
    //     @param numNFTs the amount of erc1155 tokens
    //     @param minExpectedTokenOutput The minimum acceptable token received by the sender. If the actual
    //     amount is less than this value, the transaction will be reverted.
    //     @param protocolFee The percentage of protocol fee to be taken, as a percentage
    //     @return protocolFee The amount of tokens to send as protocol fee
    //     @return outputAmount The amount of tokens total tokens receive
    //  */
    // function _calculateSellInfoAndUpdatePoolParamsERC1155(
    //     uint256 numNFTs,
    //     uint256 minExpectedTokenOutput,
    //     ICurve _bondingCurve,
    //     ISeacowsPairFactoryLike _factory
    // ) internal returns (uint256 protocolFee, uint256 outputAmount) {
    //     CurveErrorCodes.Error error;
    //     // Save on 2 SLOADs by caching
    //     uint128 currentSpotPrice = spotPrice;
    //     uint128 newSpotPrice;
    //     // uint128 newSpotPriceOriginal;
    //     uint128 currentDelta = delta;
    //     uint128 newDelta = delta;

    //     // For trade pair, we only accept CPMM
    //     // get reserve
    //     (uint256 nftReserve, uint256 tokenReserve) = _getReserve();
    //     (error, newSpotPrice, outputAmount, protocolFee) = _bondingCurve.getCPMMSellInfo(
    //         currentSpotPrice,
    //         numNFTs,
    //         fee,
    //         _factory.protocolFeeMultiplier(),
    //         nftReserve,
    //         tokenReserve
    //     );

    //     _updateSpotPrice(error, outputAmount, minExpectedTokenOutput, currentDelta, newDelta, currentSpotPrice, newSpotPrice);
    // }

    function withdrawERC1155(address _recipient, uint256 _amount) external onlyFactory {
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
