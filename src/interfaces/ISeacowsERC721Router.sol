// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ISeacowsERC721Router {
    function pairTransferNFTFrom(IERC721 nft, address from, address to, uint256 id) external;
}
