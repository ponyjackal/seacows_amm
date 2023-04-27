// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import { SeacowsPair } from "./SeacowsPair.sol";
import { ISeacowsPairFactoryLike } from "../interfaces/ISeacowsPairFactoryLike.sol";
import { ICurve } from "../bondingcurve/ICurve.sol";
import { CurveErrorCodes } from "../bondingcurve/CurveErrorCodes.sol";

contract SeacowsPairERC721 is SeacowsPair, ERC721Holder {
    event WithdrawERC721(address indexed recipient, uint256[] ids);
    event ERC721Deposit(address indexed depositer, uint256[] ids);
    event Swap(address indexed sender, uint256 tokenIn, uint256[] nftIdsIn, uint256 tokenOut, uint256[] nftIdsOut, address indexed recipient);

    /** Internal Functions */
    function _sendSpecificNFTsToRecipient(address _nft, address nftRecipient, uint256[] calldata nftIds) internal {
        // Send NFTs to caller
        // If missing enumerable, update pool's own ID set
        uint256 numNFTs = nftIds.length;
        for (uint256 i; i < numNFTs; ) {
            IERC721(_nft).safeTransferFrom(address(this), nftRecipient, nftIds[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
        @notice Calculates the amount needed to be sent into the pair for a buy and adjusts spot price or delta if necessary
        @param nftIds The nftIds to buy from the pair
        @param maxExpectedTokenInput The maximum acceptable cost from the sender. If the actual
        amount is greater than this value, the transaction will be reverted.
        @param protocolFee The percentage of protocol fee to be taken, as a percentage
        @return protocolFee The amount of tokens to send as protocol fee
        @return inputAmount The amount of tokens total tokens receive
     */
    function _calculateBuyInfoAndUpdatePoolParams(
        uint256[] memory nftIds,
        uint256 maxExpectedTokenInput,
        ICurve _bondingCurve,
        ISeacowsPairFactoryLike _factory
    ) internal virtual returns (uint256 protocolFee, uint256 inputAmount) {
        CurveErrorCodes.Error error;
        // Save on 2 SLOADs by caching
        uint128 currentSpotPrice = spotPrice;
        uint128 newSpotPrice;
        // uint128 newSpotPriceOriginal;
        uint128 currentDelta = delta;
        uint128 newDelta = delta;

        uint256 numOfNFTs = nftIds.length;

        (error, newSpotPrice, newDelta, inputAmount, protocolFee) = _bondingCurve.getBuyInfo(
            address(this),
            numOfNFTs,
            _factory.protocolFeeMultiplier()
        );

        // Revert if bonding curve had an error
        if (error != CurveErrorCodes.Error.OK) {
            revert BondingCurveError(error);
        }
        // Revert if input is more than expected
        require(inputAmount <= maxExpectedTokenInput, "In too many tokens");

        // Consolidate writes to save gas
        if (currentSpotPrice != newSpotPrice || currentDelta != newDelta) {
            spotPrice = newSpotPrice;
            delta = newDelta;
        }

        // Emit spot price update if it has been updated
        if (currentSpotPrice != newSpotPrice) {
            emit SpotPriceUpdate(currentSpotPrice, newSpotPrice);
        }

        // Emit delta update if it has been updated
        if (currentDelta != newDelta) {
            emit DeltaUpdate(currentDelta, newDelta);
        }
    }

    /**
        @notice Calculates the amount needed to be sent by the pair for a sell and adjusts spot price or delta if necessary
        @param nftIds The nftIds to buy from the pair
        @param minExpectedTokenOutput The minimum acceptable token received by the sender. If the actual
        amount is less than this value, the transaction will be reverted.
        @param protocolFee The percentage of protocol fee to be taken, as a percentage
        @return protocolFee The amount of tokens to send as protocol fee
        @return outputAmount The amount of tokens total tokens receive
     */
    function _calculateSellInfoAndUpdatePoolParams(
        uint256[] memory nftIds,
        uint256 minExpectedTokenOutput,
        ICurve _bondingCurve,
        ISeacowsPairFactoryLike _factory
    ) internal virtual returns (uint256 protocolFee, uint256 outputAmount) {
        CurveErrorCodes.Error error;
        // Save on 2 SLOADs by caching
        uint128 currentSpotPrice = spotPrice;
        uint128 newSpotPrice;
        // uint128 newSpotPriceOriginal;
        uint128 currentDelta = delta;
        uint128 newDelta = delta;
        uint256 numOfNFTs = nftIds.length;

        (error, newSpotPrice, newDelta, outputAmount, protocolFee) = _bondingCurve.getSellInfo(
            address(this),
            numOfNFTs,
            _factory.protocolFeeMultiplier()
        );

        _updateSpotPrice(error, outputAmount, minExpectedTokenOutput, currentDelta, newDelta, currentSpotPrice, newSpotPrice);
    }

    /**
        @notice Takes NFTs from the caller and sends them into the pair's asset recipient
        @dev This is used by the SeacowsPair's swapNFTForToken function. 
        @param _nft The NFT collection to take from
        @param nftIds The specific NFT IDs to take
     */
    function _takeNFTsFromSender(address _nft, uint256[] calldata nftIds) internal {
        address _assetRecipient = getAssetRecipient();
        uint256 numNFTs = nftIds.length;

        // we assume they already sent the assets to the pair
        // we transfer nfts from the pair to the asset recipient
        for (uint256 i; i < numNFTs; ) {
            IERC721(_nft).safeTransferFrom(address(this), _assetRecipient, nftIds[i]);

            unchecked {
                ++i;
            }
        }
    }

    /** View Functions */

    function pairVariant() public pure override returns (ISeacowsPairFactoryLike.PairVariant) {
        return ISeacowsPairFactoryLike.PairVariant.ERC721_ERC20;
    }

    /** Mutative Functions */

    /**
        @notice Sends a set of NFTs to the pair in exchange for token
        @dev To compute the amount of token to that will be received, call bondingCurve.getSellInfo.
        we assume this function is called through the router
        @param nftIds The list of IDs of the NFTs to sell to the pair
        @param minExpectedTokenOutput The minimum acceptable token received by the sender. If the actual
        amount is less than this value, the transaction will be reverted.
        @param tokenRecipient The recipient of the token output
        @return outputAmount The amount of token received
     */
    function swapNFTsForToken(uint256[] calldata nftIds, uint256 minExpectedTokenOutput, address payable tokenRecipient)
        external
        virtual
        nonReentrant
        returns (uint256 outputAmount)
    {
        // Input validation
        {
            require(poolType == PoolType.TOKEN, "Wrong Pool type");
            require(nftIds.length > 0, "Must ask for > 0 NFTs");
        }

        // Call bonding curve for pricing information
        uint256 protocolFee;
        (protocolFee, outputAmount) = _calculateSellInfoAndUpdatePoolParams(nftIds, minExpectedTokenOutput, bondingCurve, factory);

        _payProtocolFeeFromPair(factory, protocolFee);

        // make sure we recieved correct amount of nfts by checking reserves
        require(nftReserve + nftIds.length <= IERC721(nft).balanceOf(address(this)), "Invalid NFT amount");

        _takeNFTsFromSender(nft, nftIds);

        // we sync reserves after sending tokens
        _sendTokenOutput(tokenRecipient, outputAmount);

        // we update reserves accordingly
        syncReserve();

        emit Swap(msg.sender, 0, nftIds, outputAmount, new uint256[](0), tokenRecipient);
    }

    /**
        @notice Sends token to the pair in exchange for a specific set of NFTs
        @dev To compute the amount of token to send, call bondingCurve.getBuyInfo
        This swap is meant for users who want specific IDs. Also higher chance of
        reverting if some of the specified IDs leave the pool before the swap goes through.
        we assume this function is called through the router
        @param nftIds The list of IDs of the NFTs to purchase
        @param maxExpectedTokenInput The maximum acceptable cost from the sender. If the actual
        amount is greater than this value, the transaction will be reverted.
        @param nftRecipient The recipient of the NFTs
        @return inputAmount The amount of token used for purchase
     */
    function swapTokenForSpecificNFTs(uint256[] calldata nftIds, uint256 maxExpectedTokenInput, address nftRecipient)
        external
        payable
        virtual
        nonReentrant
        returns (uint256 inputAmount)
    {
        // Input validation
        {
            require(poolType == PoolType.NFT, "Wrong Pool type");
            require((nftIds.length > 0), "Must ask for > 0 NFTs");
        }

        // Call bonding curve for pricing information
        uint256 protocolFee;
        (protocolFee, inputAmount) = _calculateBuyInfoAndUpdatePoolParams(nftIds, maxExpectedTokenInput, bondingCurve, factory);

        // make sure we recieved correct amount of tokens by checking reserves
        require(tokenReserve + inputAmount <= token.balanceOf(address(this)), "Invalid token amount");

        _refundTokenToSender(inputAmount);

        _pullTokenInputAndPayProtocolFee(inputAmount, factory, protocolFee);

        _sendSpecificNFTsToRecipient(nft, nftRecipient, nftIds);

        // we sync rerseves
        syncReserve();

        emit Swap(msg.sender, inputAmount, new uint256[](0), 0, nftIds, nftRecipient);
    }

    function withdrawERC721(uint256[] calldata nftIds) external onlyWithdrawable {
        IERC721 _nft = IERC721(nft);
        uint256 numNFTs = nftIds.length;

        // Otherwise, withdraw and also remove the ID from the ID set
        for (uint256 i; i < numNFTs; ) {
            _nft.safeTransferFrom(address(this), msg.sender, nftIds[i]);

            unchecked {
                ++i;
            }
        }

        // sync reserves
        syncReserve();

        emit WithdrawERC721(msg.sender, nftIds);
    }

    /** 
      @dev Used to deposit NFTs into a pair after creation and emit an event for indexing 
      (if recipient is indeed a pair)
    */
    function depositERC721(uint256[] calldata ids) external onlyOwner {
        require(owner() == msg.sender, "Not a pair owner");
        require(poolType == SeacowsPair.PoolType.NFT, "Not a nft pair");

        // transfer NFTs from caller to recipient
        uint256 numNFTs = ids.length;
        for (uint256 i; i < numNFTs; ) {
            IERC721(nft).safeTransferFrom(msg.sender, address(this), ids[i]);

            unchecked {
                ++i;
            }
        }

        // sync reserves
        syncReserve();

        emit ERC721Deposit(msg.sender, ids);
    }

    // update reserves and, on the first call per block, price accumulators
    function syncReserve() public override {
        // we update reserves accordingly
        uint256 _nftBalance = IERC721(nft).balanceOf(address(this));
        uint256 _tokenBalance = token.balanceOf(address(this));

        _updateReserve(_nftBalance, _tokenBalance);
    }
}
