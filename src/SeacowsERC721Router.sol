// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { SeacowsPairERC721 } from "./pairs/SeacowsPairERC721.sol";

contract SeacowsERC721Router {
    function swapNFTsForToken(SeacowsPairERC721 _pair, uint256[] calldata _nftIds, uint256 _minOutput, address payable _recipient)
        external
        returns (uint256 outputAmount)
    {
        outputAmount = _pair.swapNFTsForToken(_nftIds, _minOutput, _recipient);
    }
}
