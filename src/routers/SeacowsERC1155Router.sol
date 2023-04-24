// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { SeacowsPairERC1155 } from "../pairs/SeacowsPairERC1155.sol";
import { ISeacowsPairERC1155 } from "../interfaces/ISeacowsPairERC1155.sol";
import { IWETH } from "../interfaces/IWETH.sol";

contract SeacowsERC1155Router {
    struct PairSwap {
        ISeacowsPairERC1155 pair;
        uint256[] nftIds;
        uint256[] amounts;
    }

    address public weth;

    constructor(address _weth) {
        require(_weth != address(0), "Invalid weht address");

        weth = _weth;
    }

    /** Swap functions */

    /**
        @notice Sell NFTs for ERC20 token
        @param _swap ERC1155 pair swap param
        @param _minOutput The minimum expected ERC20 token amount
        @param _recipient Token recipient address
     */
    function swapNFTsForToken(PairSwap calldata _swap, uint256 _minOutput, address payable _recipient) external returns (uint256 outputAmount) {
        // we will need to transfer nfts to the pair before swap
        uint256 numOfNfts = _swap.nftIds.length;
        IERC1155 nft = IERC1155(_swap.pair.nft());
        for (uint256 i; i < numOfNfts; ) {
            nft.safeTransferFrom(msg.sender, address(_swap.pair), _swap.nftIds[i], _swap.amounts[i], "");
            unchecked {
                ++i;
            }
        }

        outputAmount = _swap.pair.swapNFTsForToken(_swap.nftIds, _swap.amounts, _minOutput, _recipient);
    }

    /**
        @notice Buy NFTs in ERC20 token
        @param _swapList ERC1155 pair swap list
        @param _tokenAmount ERC20 token amount to swap
        @param _recipient NFT recipient address
     */
    function swapTokenForNFTs(PairSwap[] calldata _swapList, uint256 _tokenAmount, address _recipient) external returns (uint256 remainingValue) {
        remainingValue = _swapTokenForNFTs(_swapList, _tokenAmount, _recipient, msg.sender);
    }

    /**
        @notice Buy NFTs in ETH
        @param _swapList ERC1155 pair swap list
        @param _recipient NFT recipient address
     */
    function swapTokenForNFTsETH(PairSwap[] calldata _swapList, address _recipient) external payable returns (uint256 remainingValue) {
        // convert eth to weth
        IWETH(weth).deposit{ value: msg.value }();

        remainingValue = _swapTokenForNFTs(_swapList, msg.value, _recipient, address(this));

        _refundEth(remainingValue);
    }

    /** Internal functions */

    /**
        @dev Internal function for swapTokenForNFTs
        @notice Buy NFTs in ERC20 token
        @param _swapList ERC1155 pair swap list
        @param _tokenAmount ERC20 token amount to swap
        @param _recipient NFT recipient address
        @param _from Token owner
     */
    function _swapTokenForNFTs(PairSwap[] calldata _swapList, uint256 _tokenAmount, address _recipient, address _from)
        internal
        returns (uint256 remainingValue)
    {
        remainingValue = _tokenAmount;
        uint256 numOfSwaps = _swapList.length;
        for (uint256 i; i < numOfSwaps; ) {
            uint256 buyNftAmount;
            for (uint256 j; j < _swapList[i].nftIds.length; ) {
                buyNftAmount += _swapList[i].amounts[j];
                unchecked {
                    ++j;
                }
            }

            // transfer tokens to the pair
            (, , , uint256 inputAmount, ) = _swapList[i].pair.getBuyNFTQuote(buyNftAmount);
            _swapList[i].pair.token().transferFrom(_from, address(_swapList[i].pair), inputAmount);

            remainingValue -= _swapList[i].pair.swapTokenForNFTs(_swapList[i].nftIds, _swapList[i].amounts, _tokenAmount, _recipient);
            unchecked {
                ++i;
            }
        }
    }

    function _refundEth(uint256 amount) internal {
        // we refund the remaining eth
        IWETH(weth).withdraw(amount);
        (bool sent, ) = msg.sender.call{ value: amount }("");
        require(sent, "Failed to send Ether");
    }

    receive() external payable {}
}
