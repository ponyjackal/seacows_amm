// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract SeacowsPositionManager is ERC1155 {

    // Token ID starts from 1.
    uint256 public nextTokenId;

    // address => 0 means pair is not initialized in this contract
    mapping(address => uint256) public pairTokenIds;

    constructor() ERC1155("") {
        nextTokenId = 1;
    }

    function uri(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return "";
        // return
        //     NFTRenderer.render(
        //         NFTRenderer.RenderParams({
        //             owner: address(this),
        //             lowerTick: -24,
        //             upperTick: -24,
        //             fee: 500
        //         })
        //     );
    }

    function _createNewPositionToken(address _pair) internal returns (uint256) {
        pairTokenIds[_pair] = nextTokenId;
        nextTokenId++;
        return pairTokenIds[_pair];
    }
  
}
