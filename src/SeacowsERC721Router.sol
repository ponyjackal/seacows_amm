// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { SeacowsPairERC721 } from "./pairs/SeacowsPairERC721.sol";
import { ISeacowsPairERC721 } from "./interfaces/ISeacowsPairERC721.sol";

contract SeacowsERC721Router {
    /**
        @notice Swap NFTs for Token
        @param _pair ERC721 pair
        @param _nftIds ERC721 nft ids
        @param _minOutput The minimum expected erc20 token amount
        @param _recipient Token recipient address
     */
    function swapNFTsForToken(ISeacowsPairERC721 _pair, uint256[] calldata _nftIds, uint256 _minOutput, address payable _recipient)
        external
        returns (uint256 outputAmount)
    {
        outputAmount = _pair.swapNFTsForToken(_nftIds, _minOutput, _recipient);
    }
}
