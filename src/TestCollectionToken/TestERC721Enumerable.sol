// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TestERC721Enumerable is ERC721Enumerable, Ownable {
    constructor() ERC721("TestERC721Enumerable", "Test ERC721Enumerable") {}

    function safeMint(address to) public {
        _safeMint(to, totalSupply());
    }
}
