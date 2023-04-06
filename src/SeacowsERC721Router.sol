// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { SeacowsPairERC721 } from "./pairs/SeacowsPairERC721.sol";
import { ISeacowsPairERC721 } from "./interfaces/ISeacowsPairERC721.sol";
import { IWETH } from "./interfaces/IWETH.sol";

contract SeacowsERC721Router {
    struct PairSwapAny {
        ISeacowsPairERC721 pair;
        uint256 numItems;
    }

    struct PairSwapSpecific {
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
    function swapNFTsForToken(PairSwapSpecific calldata _swap, uint256 _minOutput, address payable _recipient)
        external
        returns (uint256 outputAmount)
    {
        outputAmount = _swap.pair.swapNFTsForToken(_swap.nftIds, _minOutput, _recipient);
    }

    /**
        @notice Buy specific NFTs in ERC20 token
        @param _swapList ERC721 pair swap list
        @param _tokenAmount ERC20 token amount to swap
        @param _recipient NFT recipient address
     */
    function swapTokenForSpecificNFTs(PairSwapSpecific[] calldata _swapList, uint256 _tokenAmount, address _recipient)
        external
        returns (uint256 remainingValue)
    {
        remainingValue = _swapTokenForSpecificNFTs(_swapList, _tokenAmount, _recipient);
    }

    /**
        @notice Buy specific NFTs in ETH
        @param _swapList ERC721 pair swap list
        @param _tokenAmount ERC20 token amount to swap
        @param _recipient NFT recipient address
     */
    function swapTokenForSpecificNFTsETH(PairSwapSpecific[] calldata _swapList, uint256 _tokenAmount, address _recipient)
        external
        payable
        returns (uint256 remainingValue)
    {
        IWETH(weth).deposit{ value: msg.value }();

        remainingValue = _swapTokenForSpecificNFTs(_swapList, _tokenAmount, _recipient);
    }

    /**
        @notice Buy specific NFTs in ERC20 token
        @param _swapList ERC721 pair swap list
        @param _tokenAmount ERC20 token amount to swap
        @param _recipient NFT recipient address
     */
    function swapTokenForAnyNFTs(PairSwapAny[] calldata _swapList, uint256 _tokenAmount, address _recipient)
        external
        returns (uint256 remainingValue)
    {
        remainingValue = _swapTokenForAnyNFTs(_swapList, _tokenAmount, _recipient);
    }

    /**
        @notice Buy specific NFTs in ETH
        @param _swapList ERC721 pair swap list
        @param _tokenAmount ERC20 token amount to swap
        @param _recipient NFT recipient address
     */
    function swapTokenForAnyNFTsETH(PairSwapAny[] calldata _swapList, uint256 _tokenAmount, address _recipient)
        external
        payable
        returns (uint256 remainingValue)
    {
        IWETH(weth).deposit{ value: msg.value }();

        remainingValue = _swapTokenForAnyNFTs(_swapList, _tokenAmount, _recipient);
    }

    /** Internal functions */

    /**
        @dev Internal function for swapTokenForSpecificNFTs
        @notice Buy specific NFTs in ERC20 token
        @param _swapList ERC721 pair swap list
        @param _tokenAmount ERC20 token amount to swap
        @param _recipient NFT recipient address
     */
    function _swapTokenForSpecificNFTs(PairSwapSpecific[] calldata _swapList, uint256 _tokenAmount, address _recipient)
        internal
        returns (uint256 remainingValue)
    {
        remainingValue = _tokenAmount;
        uint256 numOfSwap = _swapList.length;

        for (uint256 i; i < numOfSwap; ) {
            remainingValue -= _swapList[i].pair.swapTokenForSpecificNFTs(_swapList[i].nftIds, _tokenAmount, _recipient);
            unchecked {
                ++i;
            }
        }
    }

    /**
        @dev Internal function for swapTokenForAnyNFTs
        @notice Buy any NFTs in ERC20 token
        @param _swapList ERC721 pair swap list
        @param _tokenAmount ERC20 token amount to swap
        @param _recipient NFT recipient address
     */
    function _swapTokenForAnyNFTs(PairSwapAny[] calldata _swapList, uint256 _tokenAmount, address _recipient)
        internal
        returns (uint256 remainingValue)
    {
        remainingValue = _tokenAmount;
        uint256 numOfSwap = _swapList.length;

        for (uint256 i; i < numOfSwap; ) {
            remainingValue -= _swapList[i].pair.swapTokenForAnyNFTs(_swapList[i].numItems, _tokenAmount, _recipient);
            unchecked {
                ++i;
            }
        }
    }
}
