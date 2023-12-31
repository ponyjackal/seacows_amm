// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import { SeacowsPairTrade } from "./SeacowsPairTrade.sol";
import { ISeacowsPairFactoryLike } from "../interfaces/ISeacowsPairFactoryLike.sol";
import { ICurve } from "../bondingcurve/ICurve.sol";
import { CurveErrorCodes } from "../bondingcurve/CurveErrorCodes.sol";

contract SeacowsPairERC721Trade is SeacowsPairTrade {
    using EnumerableSet for EnumerableSet.UintSet;

    // Used for internal ID tracking
    EnumerableSet.UintSet private idSet;

    event WithdrawERC721(address indexed recipient, uint256[] ids);
    event ERC721Deposit(address indexed depositor, uint256[] ids);

    /** Internal Functions */

    function _sendAnyNFTsToRecipient(address _nft, address nftRecipient, uint256 numNFTs) internal {
        // Send NFTs to recipient
        // We're missing enumerable, so we also update the pair's own ID set
        // NOTE: We start from last index to first index to save on gas
        uint256 lastIndex = idSet.length() - 1;
        for (uint256 i; i < numNFTs; ) {
            uint256 nftId = idSet.at(lastIndex);
            IERC721(_nft).safeTransferFrom(address(this), nftRecipient, nftId);
            idSet.remove(nftId);

            unchecked {
                --lastIndex;
                ++i;
            }
        }
    }

    function _sendSpecificNFTsToRecipient(address _nft, address nftRecipient, uint256[] calldata nftIds) internal {
        // Send NFTs to caller
        // If missing enumerable, update pool's own ID set
        uint256 numNFTs = nftIds.length;
        for (uint256 i; i < numNFTs; ) {
            IERC721(_nft).safeTransferFrom(address(this), nftRecipient, nftIds[i]);
            // Remove from id set
            idSet.remove(nftIds[i]);

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
        {
            address _assetRecipient = getAssetRecipient();
            uint256 numNFTs = nftIds.length;

            // Pull NFTs directly from sender
            for (uint256 i; i < numNFTs; ) {
                IERC721(_nft).safeTransferFrom(msg.sender, _assetRecipient, nftIds[i]);

                unchecked {
                    ++i;
                }
            }
        }
    }

    /** View Functions */

    /**
        @dev Used as read function to query the bonding curve for buy pricing info
        @param nftIds The nftIds to buy from the pair
     */
    function getBuyNFTQuote(uint256[] memory nftIds)
        external
        view
        returns (CurveErrorCodes.Error error, uint256 newSpotPrice, uint256 newDelta, uint256 inputAmount, uint256 protocolFee)
    {
        uint256 currentSpotPrice;
        (error, currentSpotPrice, newDelta, inputAmount, protocolFee) = bondingCurve.getBuyInfo(
            address(this),
            nftIds.length,
            factory.protocolFeeMultiplier()
        );
        newSpotPrice = currentSpotPrice;
    }

    /**
        @dev Used as read function to query the bonding curve for sell pricing info
        @param nftIds The nftIds to buy from the pair
     */
    function getSellNFTQuote(uint256[] memory nftIds)
        external
        view
        returns (CurveErrorCodes.Error error, uint256 newSpotPrice, uint256 newDelta, uint256 outputAmount, uint256 protocolFee)
    {
        uint256 currentSpotPrice;
        (error, currentSpotPrice, newDelta, outputAmount, protocolFee) = bondingCurve.getSellInfo(
            address(this),
            nftIds.length,
            factory.protocolFeeMultiplier()
        );
        newSpotPrice = currentSpotPrice;
    }

    function getAllHeldIds() external view returns (uint256[] memory) {
        uint256 numNFTs = idSet.length();
        uint256[] memory ids = new uint256[](numNFTs);
        for (uint256 i; i < numNFTs; ) {
            ids[i] = idSet.at(i);

            unchecked {
                ++i;
            }
        }
        return ids;
    }

    function pairVariant() public pure override returns (ISeacowsPairFactoryLike.PairVariant) {
        return ISeacowsPairFactoryLike.PairVariant.ERC721_ERC20;
    }

    /**
     * @notice get reserves in the pool, only available for trade pair
     */
    function getReserve() external view override returns (uint256 nftReserve, uint256 tokenReserve) {
        // nft balance
        nftReserve = IERC721(nft).balanceOf(address(this));
        // token balance
        tokenReserve = token.balanceOf(address(this));
    }

    /**
        @dev When safeTransfering an ERC721 in, we add ID to the idSet
        if it's the same collection used by pool. (As it doesn't auto-track because no ERC721Enumerable)
     */
    function onERC721Received(address, address, uint256 id, bytes memory) public virtual returns (bytes4) {
        IERC721 _nft = IERC721(nft);
        // If it's from the pair's NFT, add the ID to ID set
        if (msg.sender == address(_nft)) {
            idSet.add(id);
        }
        return this.onERC721Received.selector;
    }

    /** Mutative Functions */

    /**
        @notice Sends token to the pair in exchange for any `numNFTs` NFTs
        @dev To compute the amount of token to send, call bondingCurve.getBuyInfo.
        This swap function is meant for users who are ID agnostic
        @param numNFTs The number of NFTs to purchase
        @param maxExpectedTokenInput The maximum acceptable cost from the sender. If the actual
        amount is greater than this value, the transaction will be reverted.
        @param nftRecipient The recipient of the NFTs
        @return inputAmount The amount of token used for purchase
     */
    function swapTokenForAnyNFTs(uint256 numNFTs, uint256 maxExpectedTokenInput, address nftRecipient)
        external
        payable
        virtual
        nonReentrant
        returns (uint256 inputAmount)
    {
        // Input validation
        {
            require(poolType == PoolType.NFT || poolType == PoolType.TRADE, "Wrong Pool type");
            require(numNFTs > 0, "Invalid nft amount");
        }
        // Call bonding curve for pricing information
        uint256 protocolFee;
        (protocolFee, inputAmount) = _calculateBuyInfoAndUpdatePoolParams(new uint256[](numNFTs), maxExpectedTokenInput, bondingCurve, factory);
        _pullTokenInputAndPayProtocolFee(inputAmount, factory, protocolFee);
        _sendAnyNFTsToRecipient(nft, nftRecipient, numNFTs);
        _refundTokenToSender(inputAmount);

        emit SwapNFTOutPair();
    }

    /**
        @notice Sends a set of NFTs to the pair in exchange for token
        @dev To compute the amount of token to that will be received, call bondingCurve.getSellInfo.
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
            require(poolType == PoolType.TOKEN || poolType == PoolType.TRADE, "Wrong Pool type");
            require(nftIds.length > 0, "Must ask for > 0 NFTs");
        }

        // Call bonding curve for pricing information
        uint256 protocolFee;
        (protocolFee, outputAmount) = _calculateSellInfoAndUpdatePoolParams(nftIds, minExpectedTokenOutput, bondingCurve, factory);

        _sendTokenOutput(tokenRecipient, outputAmount);

        _payProtocolFeeFromPair(factory, protocolFee);

        _takeNFTsFromSender(nft, nftIds);

        emit SwapNFTInPair();
    }

    /**
        @notice Sends token to the pair in exchange for a specific set of NFTs
        @dev To compute the amount of token to send, call bondingCurve.getBuyInfo
        This swap is meant for users who want specific IDs. Also higher chance of
        reverting if some of the specified IDs leave the pool before the swap goes through.
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
            require(poolType == PoolType.NFT || poolType == PoolType.TRADE, "Wrong Pool type");
            require((nftIds.length > 0), "Must ask for > 0 NFTs");
        }

        // Call bonding curve for pricing information
        uint256 protocolFee;
        (protocolFee, inputAmount) = _calculateBuyInfoAndUpdatePoolParams(nftIds, maxExpectedTokenInput, bondingCurve, factory);

        _pullTokenInputAndPayProtocolFee(inputAmount, factory, protocolFee);

        _sendSpecificNFTsToRecipient(nft, nftRecipient, nftIds);

        _refundTokenToSender(inputAmount);

        emit SwapNFTOutPair();
    }

    function withdrawERC721(uint256[] calldata nftIds) external onlyOwner {
        IERC721 _nft = IERC721(nft);
        uint256 numNFTs = nftIds.length;

        // Otherwise, withdraw and also remove the ID from the ID set
        for (uint256 i; i < numNFTs; ) {
            _nft.safeTransferFrom(address(this), msg.sender, nftIds[i]);
            idSet.remove(nftIds[i]);

            unchecked {
                ++i;
            }
        }

        emit WithdrawERC721(msg.sender, nftIds);
    }

    /** 
      @dev Used to deposit NFTs into a pair after creation and emit an event for indexing 
      (if recipient is indeed a pair)
    */
    function depositERC721(uint256[] calldata ids) external {
        require(owner() == msg.sender, "Not a pair owner");
        require(poolType == SeacowsPairTrade.PoolType.NFT, "Not a nft pair");

        // transfer NFTs from caller to recipient
        uint256 numNFTs = ids.length;
        for (uint256 i; i < numNFTs; ) {
            IERC721(nft).safeTransferFrom(msg.sender, address(this), ids[i]);

            unchecked {
                ++i;
            }
        }
        emit ERC721Deposit(msg.sender, ids);
    }
}
