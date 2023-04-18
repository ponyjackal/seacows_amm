// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";

// @dev Solmate's ERC20 is used instead of OZ's ERC20 so we can use safeTransferLib for cheaper safeTransfers for
// ETH and ERC20 tokens
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { SeacowsPair } from "../pairs/SeacowsPair.sol";
import { ICurve } from "../bondingcurve/ICurve.sol";
import { SeacowsPairERC1155 } from "../pairs/SeacowsPairERC1155.sol";

import { IWETH } from "../interfaces/IWETH.sol";
import { ISeacowsPairFactoryLike } from "../interfaces/ISeacowsPairFactoryLike.sol";
import { ISeacowsPair } from "../interfaces/ISeacowsPair.sol";
import { ISeacowsPairERC1155 } from "../interfaces/ISeacowsPairERC1155.sol";

///Inspired by 0xmons; Modified from https://github.com/sudoswap/lssvm
contract SeacowsPairERC1155Factory is Ownable, ISeacowsPairFactoryLike {
    using Clones for address;
    using SafeTransferLib for address payable;
    using SafeERC20 for ERC20;

    uint256 internal constant MAX_PROTOCOL_FEE = 0.10e18; // 10%, must <= 1 - MAX_FEE

    SeacowsPairERC1155 public immutable erc1155Template;
    address payable public override protocolFeeRecipient;
    address public weth;

    // Units are in base 1e18
    uint256 public override protocolFeeMultiplier;

    // used for bondingCurve validation
    mapping(ICurve => bool) public bondingCurveAllowed;

    struct CreateERC1155ERC20PairParams {
        IERC20 token;
        IERC1155 nft;
        ICurve bondingCurve;
        address payable assetRecipient;
        SeacowsPair.PoolType poolType;
        uint128 delta;
        uint96 fee;
        uint128 spotPrice;
        uint256 tokenAmount;
        uint256[] nftIds;
        uint256[] nftAmounts;
    }

    struct CreateERC1155ETHPairParams {
        IERC1155 nft;
        ICurve bondingCurve;
        address payable assetRecipient;
        SeacowsPair.PoolType poolType;
        uint128 delta;
        uint96 fee;
        uint128 spotPrice;
        uint256[] nftIds;
        uint256[] nftAmounts;
    }

    event NewPair(address poolAddress);
    event ProtocolFeeRecipientUpdate(address recipientAddress);
    event ProtocolFeeMultiplierUpdate(uint256 newMultiplier);
    event BondingCurveStatusUpdate(ICurve bondingCurve, bool isAllowed);
    event CallTargetStatusUpdate(address target, bool isAllowed);
    event ProtocolFeeDisabled(address pair, bool isDisabled);

    constructor(address _weth, SeacowsPairERC1155 _erc1155Template, address payable _protocolFeeRecipient, uint256 _protocolFeeMultiplier) {
        weth = _weth;
        erc1155Template = _erc1155Template;
        protocolFeeRecipient = _protocolFeeRecipient;

        require(_protocolFeeMultiplier <= MAX_PROTOCOL_FEE, "Fee too large");
        protocolFeeMultiplier = _protocolFeeMultiplier;
    }

    /**
     * External functions
     */

    /**
        @notice Creates an erc1155 pair contract using EIP-1167.
        @param params CreateERC1155ETHPairParams params
        @return pair The new pair
     */
    function createPairERC1155ETH(CreateERC1155ETHPairParams calldata params) external payable returns (SeacowsPair) {
        IWETH(weth).deposit{ value: msg.value }();
        (SeacowsPair pair, uint256 totalAmount) = _createPairERC1155ERC20(params.nft, params.poolType, params.nftIds, params.nftAmounts);

        SeacowsPair.PairInitializeParams memory initParams = SeacowsPair.PairInitializeParams(
            this,
            params.bondingCurve,
            address(params.nft),
            params.poolType,
            IERC20(weth),
            msg.sender,
            params.assetRecipient,
            params.delta,
            params.fee,
            params.spotPrice,
            weth
        );
        // initialize pair
        pair.initialize(initParams);

        // transfer WETH from this contract to pair
        IERC20(weth).transferFrom(address(this), address(pair), msg.value);
        // set nft amount and whitelisted ids
        ISeacowsPairERC1155(address(pair)).setNFTIds(params.nftIds);
        ISeacowsPairERC1155(address(pair)).addNFTAmount(totalAmount);

        emit NewPair(address(pair));

        return pair;
    }

    /**
        @notice Creates an erc1155 pair contract using EIP-1167.
        @param params CreateERC1155ERC20PairParams params
        @return pair The new pair
     */
    function createPairERC1155ERC20(CreateERC1155ERC20PairParams calldata params) external payable returns (SeacowsPair) {
        (SeacowsPair pair, uint256 totalAmount) = _createPairERC1155ERC20(params.nft, params.poolType, params.nftIds, params.nftAmounts);

        SeacowsPair.PairInitializeParams memory initParams = SeacowsPair.PairInitializeParams(
            this,
            params.bondingCurve,
            address(params.nft),
            params.poolType,
            params.token,
            msg.sender,
            params.assetRecipient,
            params.delta,
            params.fee,
            params.spotPrice,
            weth
        );
        // initialize pair
        pair.initialize(initParams);

        // transfer initial tokens to pair
        params.token.transferFrom(msg.sender, address(pair), params.tokenAmount);
        // set nft amount and whitelisted ids
        ISeacowsPairERC1155(address(pair)).setNFTIds(params.nftIds);
        ISeacowsPairERC1155(address(pair)).addNFTAmount(totalAmount);

        emit NewPair(address(pair));

        return pair;
    }

    /**
        @notice Allows receiving ETH in order to receive protocol fees
     */
    receive() external payable {}

    /**
     * Admin functions
     */

    /**
        @notice Withdraws the ETH balance to the protocol fee recipient.
        Only callable by the owner.
     */
    function withdrawETHProtocolFees() external onlyOwner {
        protocolFeeRecipient.safeTransferETH(address(this).balance);
    }

    /**
        @notice Withdraws ERC20 tokens to the protocol fee recipient. Only callable by the owner.
        @param token The token to transfer
        @param amount The amount of tokens to transfer
     */
    function withdrawERC20ProtocolFees(ERC20 token, uint256 amount) external onlyOwner {
        token.safeTransfer(protocolFeeRecipient, amount);
    }

    /**
        @notice Changes the protocol fee recipient address. Only callable by the owner.
        @param _protocolFeeRecipient The new fee recipient
     */
    function changeProtocolFeeRecipient(address payable _protocolFeeRecipient) external onlyOwner {
        require(_protocolFeeRecipient != address(0), "0 address");
        protocolFeeRecipient = _protocolFeeRecipient;
        emit ProtocolFeeRecipientUpdate(_protocolFeeRecipient);
    }

    /**
        @notice Changes the protocol fee multiplier. Only callable by the owner.
        @param _protocolFeeMultiplier The new fee multiplier, 18 decimals
     */
    function changeProtocolFeeMultiplier(uint256 _protocolFeeMultiplier) external onlyOwner {
        require(_protocolFeeMultiplier <= MAX_PROTOCOL_FEE, "Fee too large");
        protocolFeeMultiplier = _protocolFeeMultiplier;
        emit ProtocolFeeMultiplierUpdate(_protocolFeeMultiplier);
    }

    /**
        @notice Sets the whitelist status of a bonding curve contract. Only callable by the owner.
        @param bondingCurve The bonding curve contract
        @param isAllowed True to whitelist, false to remove from whitelist
     */
    function setBondingCurveAllowed(ICurve bondingCurve, bool isAllowed) external onlyOwner {
        bondingCurveAllowed[bondingCurve] = isAllowed;
        emit BondingCurveStatusUpdate(bondingCurve, isAllowed);
    }

    /**
        @notice Enable/disable a protocol fee in the pair
        @param _pair The pair contract
        @param _isProtocolFeeDisabled True to disable, false to enable protocol fee
     */
    function disableProtocolFee(SeacowsPair _pair, bool _isProtocolFeeDisabled) external onlyOwner {
        _pair.disableProtocolFee(_isProtocolFeeDisabled);

        emit ProtocolFeeDisabled(address(_pair), _isProtocolFeeDisabled);
    }

    /**
     * Internal functions
     */
    function _createPairERC1155ERC20(IERC1155 nft, SeacowsPair.PoolType poolType, uint256[] memory nftIds, uint256[] memory nftAmounts)
        internal
        returns (SeacowsPair pair, uint256 totalAmount)
    {
        require(nftIds.length == nftAmounts.length, "Invalid nft ids and amounts");

        address template = address(erc1155Template);
        // create a pair
        pair = SeacowsPair(payable(template.clone()));

        for (uint256 i; i < nftAmounts.length; ) {
            totalAmount += nftAmounts[i];
            // transfer nfts to the pair
            nft.safeTransferFrom(msg.sender, address(pair), nftIds[i], nftAmounts[i], "");

            unchecked {
                ++i;
            }
        }
    }
}
