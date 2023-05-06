// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TestERC721 is ERC721, Ownable {
    uint256 public totalSupply;

    constructor() ERC721("TestERC721", "Test ERC721") {}

    function safeMint(address to, uint256 amount) public {
        uint256 _id = totalSupply;
        for (uint256 i; i < amount; ) {
            _safeMint(to, _id + i);

            unchecked {
                ++i;
            }
        }
        totalSupply = _id + amount;
    }
}
