// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { ISeacowsPairFactoryLike } from "./interfaces/ISeacowsPairFactoryLike.sol";
import { SeacowsPair } from "./SeacowsPair.sol";
import { ICurve } from "./bondingcurve/ICurve.sol";
import { CurveErrorCodes } from "./bondingcurve/CurveErrorCodes.sol";

/**
    @title An NFT/Token pair for an NFT that implements ERC721Enumerable
    Inspired by 0xmons; Modified from https://github.com/sudoswap/lssvm
 */
contract SeacowsPairERC1155 is SeacowsPair {
    using SafeERC20 for ERC20;

    uint256[] public nftIds;
    uint256 public nftAmount;

    uint256 internal constant IMMUTABLE_PARAMS_LENGTH = 81;

    event WithdrawERC1155(address indexed recipient, uint256[] ids, uint256[] amounts);

    /** View Functions */

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
        @notice Returns the ERC1155 ids
     */
    function getNFTIds() public view returns (uint256[] memory) {
        return nftIds;
    }

    /**
        @dev check if nft id is valid or not
        @param _id ERC1155 token id
     */
    function isValidNFTID(uint256 _id) public view returns (bool) {
        if (nftIds.length == 0) return true;

        for (uint256 i; i < nftIds.length; ) {
            if (_id == nftIds[i]) {
                return true;
            }

            unchecked {
                ++i;
            }
        }

        return false;
    }

    /**
     * @notice get reserves in the pool, only available for trade pair
     */
    function getReserve() external view override returns (uint256 nftReserve, uint256 tokenReserve) {
        // nft balance
        nftReserve = nftAmount;
        // token balance
        tokenReserve = token().balanceOf(address(this));
    }

    /** Internal Functions */

    function _sendNFTsToRecipient(address _nft, address nftRecipient, uint256[] memory _nftIds, uint256[] memory _amounts) internal {
        require(_nftIds.length == _amounts.length, "Invalid amounts");

        // Send NFTs to recipient
        for (uint256 i; i < _nftIds.length; ) {
            IERC1155(_nft).safeTransferFrom(address(this), nftRecipient, _nftIds[i], _amounts[i], "");
            unchecked {
                ++i;
            }
        }
    }

    /**
        @notice Takes NFTs from the caller and sends them into the pair's asset recipient
        @dev This is used by the SeacowsPair's swapNFTForToken function.
        @param _nft The NFT collection to take from
        @param _nftIds The specific NFT IDs to take, we just need the length of IDs, no need the values in it
        @param _amounts The amount for each ID
     */
    function _takeNFTsFromSender(address _nft, uint256[] memory _nftIds, uint256[] memory _amounts, ISeacowsPairFactoryLike _factory) internal {
        require(_nftIds.length == _amounts.length, "Invalid amounts");

        address _assetRecipient = getAssetRecipient();
        // Pull NFTs directly from sender
        for (uint256 i; i < _nftIds.length; ) {
            IERC1155(_nft).safeTransferFrom(msg.sender, _assetRecipient, _nftIds[i], _amounts[i], "");
            unchecked {
                ++i;
            }
        }
    }

    /**
        @notice Calculates the amount needed to be sent into the pair for a buy and adjusts spot price or delta if necessary
        @param numOfNFTs The number of nfts
        @param maxExpectedTokenInput The maximum acceptable cost from the sender. If the actual
        amount is greater than this value, the transaction will be reverted.
        @param protocolFee The percentage of protocol fee to be taken, as a percentage
        @return protocolFee The amount of tokens to send as protocol fee
        @return inputAmount The amount of tokens total tokens receive
     */
    function _calculateBuyInfoAndUpdatePoolParams(
        uint256 numOfNFTs,
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
            emit SpotPriceUpdate(newSpotPrice);
        }

        // Emit delta update if it has been updated
        if (currentDelta != newDelta) {
            emit DeltaUpdate(newDelta);
        }
    }

    /**
        @notice Calculates the amount needed to be sent by the pair for a sell and adjusts spot price or delta if necessary
        @param numOfNFTs The number of nfts
        @param minExpectedTokenOutput The minimum acceptable token received by the sender. If the actual
        amount is less than this value, the transaction will be reverted.
        @param protocolFee The percentage of protocol fee to be taken, as a percentage
        @return protocolFee The amount of tokens to send as protocol fee
        @return outputAmount The amount of tokens total tokens receive
     */
    function _calculateSellInfoAndUpdatePoolParams(
        uint256 numOfNFTs,
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

        (error, newSpotPrice, newDelta, outputAmount, protocolFee) = _bondingCurve.getSellInfo(
            address(this),
            numOfNFTs,
            _factory.protocolFeeMultiplier()
        );

        _updateSpotPrice(error, outputAmount, minExpectedTokenOutput, currentDelta, newDelta, currentSpotPrice, newSpotPrice);
    }

    /** Mutative Functions */

    function withdrawERC1155(address _recipient, uint256[] memory _nftIds, uint256[] memory _amounts) external onlyWithdrawable {
        require(poolType() == PoolType.NFT || poolType() == PoolType.TRADE, "Invalid pool type");
        require(_nftIds.length == _amounts.length, "Invalid amounts");

        uint256 totalAmount;
        for (uint256 i; i < _nftIds.length; ) {
            require(isValidNFTID(_nftIds[i]), "Invalid nft id");
            IERC1155(nft()).safeTransferFrom(address(this), _recipient, _nftIds[i], _amounts[i], "");
            totalAmount += _amounts[i];
            unchecked {
                ++i;
            }
        }

        emit WithdrawERC1155(_recipient, _nftIds, _amounts);
    }

    /**
        @notice Sends token to the pair in exchange for NFTs
        @dev To compute the amount of token to send, call bondingCurve.getBuyInfo.
        This swap function is meant for users who are ID agnostic
        @param _nftIds The ERC1155 NFT Ids
        @param _amounts The amount of NFTs for each ID
        @param maxExpectedTokenInput The maximum acceptable cost from the sender. If the actual
        amount is greater than this value, the transaction will be reverted.
        @param nftRecipient The recipient of the NFTs
        @return inputAmount The amount of token used for purchase
     */
    function swapTokenForNFTs(uint256[] memory _nftIds, uint256[] memory _amounts, uint256 maxExpectedTokenInput, address nftRecipient)
        external
        nonReentrant
        returns (uint256 inputAmount)
    {
        // Store locally to remove extra calls
        ISeacowsPairFactoryLike _factory = factory();
        ICurve _bondingCurve = bondingCurve();
        address _nft = nft();

        uint256 totalAmount;
        for (uint256 i; i < _amounts.length; ) {
            totalAmount += _amounts[i];
            unchecked {
                ++i;
            }
        }

        // Input validation
        {
            PoolType _poolType = poolType();
            require(_poolType == PoolType.NFT || _poolType == PoolType.TRADE, "Wrong Pool type");
            require(_nftIds.length > 0 && _nftIds.length == _amounts.length, "Invalid nft ids");
            require(totalAmount > 0, "Invalid nft amount");
        }

        // Call bonding curve for pricing information
        uint256 protocolFee;
        (protocolFee, inputAmount) = _calculateBuyInfoAndUpdatePoolParams(totalAmount, maxExpectedTokenInput, _bondingCurve, _factory);
        _pullTokenInputAndPayProtocolFee(inputAmount, _factory, protocolFee);
        _sendNFTsToRecipient(_nft, nftRecipient, _nftIds, _amounts);
        _refundTokenToSender(inputAmount);

        // decrease total nft balance
        nftAmount -= totalAmount;

        emit SwapNFTOutPair();
    }

    /**
        @notice Sends a set of NFTs to the pair in exchange for token
        @dev To compute the amount of token to that will be received, call bondingCurve.getSellInfo.
        @param _nftIds The ERC1155 NFT Ids
        @param _amounts The amount of NFTs for each ID
        @param minExpectedTokenOutput The minimum acceptable token received by the sender. If the actual
        amount is less than this value, the transaction will be reverted.
        @param tokenRecipient The recipient of the token output
        @return outputAmount The amount of token received
     */
    function swapNFTsForToken(uint256[] memory _nftIds, uint256[] memory _amounts, uint256 minExpectedTokenOutput, address payable tokenRecipient)
        external
        nonReentrant
        returns (uint256 outputAmount)
    {
        // Store locally to remove extra calls
        ISeacowsPairFactoryLike _factory = factory();
        ICurve _bondingCurve = bondingCurve();

        uint256 totalAmount;
        for (uint256 i; i < _amounts.length; ) {
            totalAmount += _amounts[i];
            unchecked {
                ++i;
            }
        }

        // Input validation
        {
            PoolType _poolType = poolType();
            require(_poolType == PoolType.TOKEN || _poolType == PoolType.TRADE, "Wrong Pool type");
            require(nftIds.length > 0 && _nftIds.length == _amounts.length, "Invalid amounts");
            require(totalAmount > 0, "Must ask for > 0 NFTs");
        }

        // Call bonding curve for pricing information
        uint256 protocolFee;
        (protocolFee, outputAmount) = _calculateSellInfoAndUpdatePoolParams(totalAmount, minExpectedTokenOutput, _bondingCurve, _factory);

        _sendTokenOutput(tokenRecipient, outputAmount);

        _payProtocolFeeFromPair(_factory, protocolFee);

        _takeNFTsFromSender(nft(), _nftIds, _amounts, _factory);

        // increase total nft balance
        nftAmount += totalAmount;

        emit SwapNFTInPair();
    }

    /**
     * @dev set ERC1155 nft ids
     * @param _nftIds ERC1155 ids
     */
    function setNFTIds(uint256[] memory _nftIds) external onlyFactory {
        nftIds = _nftIds;
    }

    /**
     * @dev Add new NFTs to the pool
     * @param _nftAmount total amount of nfts
     */
    function addNFTAmount(uint256 _nftAmount) external onlyFactory {
        nftAmount += _nftAmount;
    }

    /**
     * @dev Remove NFTs from the pool
     * @param _nftAmount total amount of nfts
     */
    function removeNFTAmount(uint256 _nftAmount) external onlyFactory {
        nftAmount -= _nftAmount;
    }
}
