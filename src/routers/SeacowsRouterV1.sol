// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { SeacowsPairERC721 } from "../pairs/SeacowsPairERC721.sol";
import { ISeacowsPairERC721 } from "../interfaces/ISeacowsPairERC721.sol";
import { IWETH } from "../interfaces/IWETH.sol";

contract SeacowsRouterV1 {
    struct ERC721PairSwap {
        ISeacowsPairERC721 pair;
        uint256[] nftIds;
    }

    address public weth;

    constructor(address _weth) {
        require(_weth != address(0), "Invalid weht address");

        weth = _weth;
    }

    /** Swap functions */

    /**
        @notice Sell NFTs for ERC20 token
        @param _swap ERC721 pair swap param
        @param _minOutput The minimum expected ERC20 token amount
        @param _recipient Token recipient address
     */
    function swapNFTsForTokenERC721(ERC721PairSwap calldata _swap, uint256 _minOutput, address payable _recipient)
        external
        returns (uint256 outputAmount)
    {
        // we will need to transfer nfts to the pair before swap
        uint256 numOfNfts = _swap.nftIds.length;
        IERC721 nft = IERC721(_swap.pair.nft());
        for (uint256 i; i < numOfNfts; ) {
            nft.transferFrom(msg.sender, address(_swap.pair), _swap.nftIds[i]);
            unchecked {
                ++i;
            }
        }

        outputAmount = _swap.pair.swapNFTsForToken(_swap.nftIds, _minOutput, _recipient);
    }

    /**
        @notice Buy specific NFTs in ERC20 token
        @param _swapList ERC721 pair swap list
        @param _tokenAmount ERC20 token amount to swap
        @param _recipient NFT recipient address
     */
    function swapTokenForNFTsERC721(ERC721PairSwap[] calldata _swapList, uint256 _tokenAmount, address _recipient)
        external
        returns (uint256 remainingValue)
    {
        remainingValue = _tokenAmount;
        uint256 numOfSwaps = _swapList.length;
        for (uint256 i; i < numOfSwaps; ) {
            // transfer tokens to the pair
            (, , , uint256 inputAmount, ) = _swapList[i].pair.getBuyNFTQuote(_swapList[i].nftIds.length);
            _swapList[i].pair.token().transferFrom(msg.sender, address(_swapList[i].pair), inputAmount);

            remainingValue -= _swapList[i].pair.swapTokenForNFTs(_swapList[i].nftIds, _tokenAmount, _recipient);
            unchecked {
                ++i;
            }
        }
    }

    /**
        @notice Buy specific NFTs in ETH
        @param _swapList ERC721 pair swap list
        @param _recipient NFT recipient address
     */
    function swapTokenForNFTsETHERC721(ERC721PairSwap[] calldata _swapList, address _recipient) external payable returns (uint256 remainingValue) {
        // convert eth to weth
        IWETH(weth).deposit{ value: msg.value }();

        remainingValue = msg.value;
        uint256 numOfSwaps = _swapList.length;
        for (uint256 i; i < numOfSwaps; ) {
            // transfer tokens to the pair
            (, , , uint256 inputAmount, ) = _swapList[i].pair.getBuyNFTQuote(_swapList[i].nftIds.length);
            _swapList[i].pair.token().transfer(address(_swapList[i].pair), inputAmount);

            remainingValue -= _swapList[i].pair.swapTokenForNFTs(_swapList[i].nftIds, msg.value, _recipient);
            unchecked {
                ++i;
            }
        }

        _refundEth(remainingValue);
    }

    /** Internal functions */

    function _refundEth(uint256 amount) internal {
        // we refund the remaining eth
        IWETH(weth).withdraw(amount);
        (bool sent, ) = msg.sender.call{ value: amount }("");
        require(sent, "Failed to send Ether");
    }

    receive() external payable {}
}
