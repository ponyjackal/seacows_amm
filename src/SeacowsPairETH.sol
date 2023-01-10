// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { ERC20 } from "solmate/tokens/ERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";
import { SeacowsPair } from "./SeacowsPair.sol";
import { ISeacowsPairFactoryLike } from "./interfaces/ISeacowsPairFactoryLike.sol";
import { ICurve } from "./bondingcurve/ICurve.sol";

/**
    @title An NFT/Token pair where the token is ETH
    Inspired by 0xmons; Modified from https://github.com/sudoswap/lssvm 
 */
abstract contract SeacowsPairETH is SeacowsPair {
    using SafeTransferLib for address payable;
    using SafeTransferLib for ERC20;

    /// @inheritdoc SeacowsPair
    function _pullTokenInputAndPayProtocolFee(
        uint256 inputAmount,
        bool /*isRouter*/,
        address /*routerCaller*/,
        ISeacowsPairFactoryLike _factory,
        uint256 protocolFee
    ) internal override {
        require(msg.value >= inputAmount, "Sent too little ETH");

        // Transfer inputAmount ETH to assetRecipient if it's been set
        address payable _assetRecipient = getAssetRecipient();
        if (_assetRecipient != address(this)) {
            _assetRecipient.safeTransferETH(inputAmount - protocolFee);
        }

        // Take protocol fee
        if (protocolFee > 0) {
            // Round down to the actual ETH balance if there are numerical stability issues with the bonding curve calculations
            if (protocolFee > address(this).balance) {
                protocolFee = address(this).balance;
            }

            if (protocolFee > 0) {
                payable(address(_factory)).safeTransferETH(protocolFee);
            }
        }
    }

    /// @inheritdoc SeacowsPair
    function _refundTokenToSender(uint256 inputAmount) internal override {
        // Give excess ETH back to caller
        if (msg.value > inputAmount) {
            payable(msg.sender).safeTransferETH(msg.value - inputAmount);
        }
    }

    /// @inheritdoc SeacowsPair
    function _payProtocolFeeFromPair(ISeacowsPairFactoryLike _factory, uint256 protocolFee) internal override {
        // Take protocol fee
        if (protocolFee > 0) {
            // Round down to the actual ETH balance if there are numerical stability issues with the bonding curve calculations
            if (protocolFee > address(this).balance) {
                protocolFee = address(this).balance;
            }

            if (protocolFee > 0) {
                payable(address(_factory)).safeTransferETH(protocolFee);
            }
        }
    }

    /// @inheritdoc SeacowsPair
    function _sendTokenOutput(address payable tokenRecipient, uint256 outputAmount) internal override {
        // Send ETH to caller
        if (outputAmount > 0) {
            tokenRecipient.safeTransferETH(outputAmount);
        }
    }

    /**
        @notice Withdraws all token owned by the pair to the owner address.
        @dev Only callable by the owner.
     */
    function withdrawAllETH() external onlyOwner {
        withdrawETH(address(this).balance);
    }

    /**
        @notice Withdraws a specified amount of token owned by the pair to the owner address.
        @dev Only callable by the owner.
        @param amount The amount of token to send to the owner. If the pair's balance is less than
        this value, the transaction will be reverted.
     */
    function withdrawETH(uint256 amount) public onlyOwner {
        payable(owner()).safeTransferETH(amount);

        // emit event since ETH is the pair token
        emit TokenWithdrawal(amount);
    }

    /**
        @notice Withdraws a specified amount of token owned by the pair to the LP provider.
        @dev Only callable by the factory.
        @param amount The amount of token to send to the owner. If the pair's balance is less than
        this value, the transaction will be reverted.
     */
    function removeLPETH(address recipient, uint256 amount) public onlyFactory {
        payable(recipient).safeTransferETH(amount);
    }

    /**
        @dev All ETH transfers into the pair are accepted. This is the main method
        for the owner to top up the pair's token reserves.
     */
    receive() external payable {
        emit TokenDeposit(msg.value);
    }

    /**
        @dev All ETH transfers into the pair are accepted. This is the main method
        for the owner to top up the pair's token reserves.
     */
    fallback() external payable {
        // Only allow calls without function selector
        require(msg.data.length == _immutableParamsLength());
        emit TokenDeposit(msg.value);
    }

    /**
     * @notice get reserves in the pool, only available for trade pair
     */
    function _getReserve() internal view override onlyTrade returns (uint256 nftReserve, uint256 tokenReserve) {
        // nft balance
        nftReserve = IERC721(nft()).balanceOf(address(this));
        // eth balance
        tokenReserve = address(this).balance;
    }
}
