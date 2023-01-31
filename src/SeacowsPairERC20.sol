// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SeacowsPair } from "./SeacowsPair.sol";
import { ISeacowsPairFactoryLike } from "./interfaces/ISeacowsPairFactoryLike.sol";
import { SeacowsRouter } from "./SeacowsRouter.sol";
import { ICurve } from "./bondingcurve/ICurve.sol";
import { CurveErrorCodes } from "./bondingcurve/CurveErrorCodes.sol";

/**
    @title An NFT/Token pair where the token is an ERC20
    Inspired by 0xmons; Modified from https://github.com/sudoswap/lssvm 
 */
abstract contract SeacowsPairERC20 is SeacowsPair {
    using SafeERC20 for ERC20;

    /**
        @notice Returns the ERC20 token associated with the pair
        @dev See SeacowsPairCloner for an explanation on how this works
     */
    function token() public pure returns (ERC20 _token) {
        uint256 paramsLength = _immutableParamsLength();
        assembly {
            _token := shr(0x60, calldataload(add(sub(calldatasize(), paramsLength), 61)))
        }
    }

    /// @inheritdoc SeacowsPair
    function _pullTokenInputAndPayProtocolFee(
        uint256 inputAmount,
        bool isRouter,
        address routerCaller,
        ISeacowsPairFactoryLike _factory,
        uint256 protocolFee
    ) internal override {
        require(msg.value == 0, "ERC20 pair");

        ERC20 _token = token();
        address _assetRecipient = getAssetRecipient();

        if (isRouter) {
            // Verify if router is allowed
            SeacowsRouter router = SeacowsRouter(payable(msg.sender));

            // Locally scoped to avoid stack too deep
            {
                (bool routerAllowed, ) = _factory.routerStatus(router);
                require(routerAllowed, "Not router");
            }

            // Cache state and then call router to transfer tokens from user
            uint256 beforeBalance = _token.balanceOf(_assetRecipient);
            router.pairTransferERC20From(_token, routerCaller, _assetRecipient, inputAmount - protocolFee, pairVariant());

            // Verify token transfer (protect pair against malicious router)
            require(_token.balanceOf(_assetRecipient) - beforeBalance == inputAmount - protocolFee, "ERC20 not transferred in");

            router.pairTransferERC20From(_token, routerCaller, address(_factory), protocolFee, pairVariant());

            // Note: no check for factory balance's because router is assumed to be set by factory owner
            // so there is no incentive to *not* pay protocol fee
        } else {
            // Transfer tokens directly
            _token.transferFrom(msg.sender, _assetRecipient, inputAmount - protocolFee);

            // Take protocol fee (if it exists)
            if (protocolFee > 0) {
                _token.transferFrom(msg.sender, address(_factory), protocolFee);
            }
        }
    }

    /// @inheritdoc SeacowsPair
    function _refundTokenToSender(uint256 inputAmount) internal override {
        // Do nothing since we transferred the exact input amount
    }

    /// @inheritdoc SeacowsPair
    function _payProtocolFeeFromPair(ISeacowsPairFactoryLike _factory, uint256 protocolFee) internal override {
        // Take protocol fee (if it exists)
        if (protocolFee > 0) {
            ERC20 _token = token();

            // Round down to the actual token balance if there are numerical stability issues with the bonding curve calculations
            uint256 pairTokenBalance = _token.balanceOf(address(this));
            if (protocolFee > pairTokenBalance) {
                protocolFee = pairTokenBalance;
            }
            if (protocolFee > 0) {
                _token.safeTransfer(address(_factory), protocolFee);
            }
        }
    }

    /// @inheritdoc SeacowsPair
    function _sendTokenOutput(address payable tokenRecipient, uint256 outputAmount) internal override {
        // Send tokens to caller
        if (outputAmount > 0) {
            token().safeTransfer(tokenRecipient, outputAmount);
        }
    }

    /**
     * @dev withraw erc20 tokens from pair to recipient
     * @param _recipient The address for token withdarw
     * @param _amount The amount of token to withdraw
     */
    function withdrawERC20(address _recipient, uint256 _amount) external virtual {
        // For NFT, TOKEN pairs, only owner can call this function
        // For TRADE pairs, only factory can call this function
        if (poolType() == PoolType.TRADE) {
            require(msg.sender == address(factory()), "Caller should be a factory");
        } else {
            require(msg.sender == owner(), "Caller should be an owner");
        }
        require(_recipient != address(0), "Invalid address");
        require(_amount > 0, "Invalid amount");

        token().safeTransfer(_recipient, _amount);

        // emit event since it is the pair token
        emit TokenWithdrawal(_recipient, _amount);
    }
}
