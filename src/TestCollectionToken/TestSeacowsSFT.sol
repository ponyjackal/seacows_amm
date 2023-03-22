// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TestSeacowsSFT is ERC1155, Ownable {
    constructor() ERC1155("") {}

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _mint(to, tokenId, 10_000, "");
    }
}
