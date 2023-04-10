// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { SeacowsPairERC721 } from "../pairs/SeacowsPairERC721.sol";
import { ISeacowsPairFactoryLike } from "../interfaces/ISeacowsPairFactoryLike.sol";
import { ISeacowsPairERC721 } from "../interfaces/ISeacowsPairERC721.sol";
import { IWETH } from "../interfaces/IWETH.sol";

contract SeacowsERC721Router {
    struct PairSwapAny {
        ISeacowsPairERC721 pair;
        uint256 numItems;
    }

    struct PairSwapSpecific {
        ISeacowsPairERC721 pair;
        uint256[] nftIds;
    }

    ISeacowsPairFactoryLike public factory;

    address public weth;

    constructor(ISeacowsPairFactoryLike _factory, address _weth) {
        require(_weth != address(0), "Invalid weht address");

        weth = _weth;
        factory = _factory;
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
        outputAmount = _swap.pair.swapNFTsForToken(_swap.nftIds, _minOutput, _recipient, true, msg.sender);
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

    /**
        @dev Allows a pair contract to transfer ERC721 NFTs directly from
        the sender, in order to minimize the number of token transfers. Only callable by a pair.
        @param nft The ERC721 NFT to transfer
        @param from The address to transfer tokens from
        @param to The address to transfer tokens to
        @param id The ID of the NFT to transfer
     */
    function pairTransferNFTFrom(IERC721 nft, address from, address to, uint256 id) external {
        // verify caller is a trusted pair contract
        require(factory.pairStatus(msg.sender), "Not pair");

        // transfer NFTs to pair
        nft.safeTransferFrom(from, to, id);
    }

    /**
        @dev Allows an ERC20 pair contract to transfer ERC20 tokens directly from
        the sender, in order to minimize the number of token transfers. Only callable by an ERC20 pair.
        @param token The ERC20 token to transfer
        @param from The address to transfer tokens from
        @param to The address to transfer tokens to
        @param amount The amount of tokens to transfer
     */
    function pairTransferERC20From(IERC20 token, address from, address to, uint256 amount) external {
        // verify caller is a trusted pair contract
        require(factory.pairStatus(msg.sender), "Not pair");
        //TODO; need a validation

        // transfer tokens to pair
        token.transferFrom(from, to, amount);
    }

    /**
        @dev Allows an WETH pair contract to transfer WETH directly from
        the sender, in order to minimize the number of token transfers. Only callable by an WETH pair.
        @param to The address to transfer tokens to
        @param amount The amount of tokens to transfer
     */
    function pairTransferETHFrom(address to, uint256 amount) external {
        // verify caller is a trusted pair contract
        require(factory.pairStatus(msg.sender), "Not pair");
        //TODO; need a validation

        // transfer tokens to pair
        IWETH(weth).transfer(to, amount);
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
            remainingValue -= _swapList[i].pair.swapTokenForSpecificNFTs(_swapList[i].nftIds, _tokenAmount, _recipient, true, msg.sender);
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
            remainingValue -= _swapList[i].pair.swapTokenForAnyNFTs(_swapList[i].numItems, _tokenAmount, _recipient, true, msg.sender);
            unchecked {
                ++i;
            }
        }
    }
}
