// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ISeacowsPair } from "./ISeacowsPair.sol";

interface ISeacowsPairMissingEnumerable is ISeacowsPair {
    function getAllHeldIds() external view returns (uint256[] memory);

    function onERC721Received(address, address, uint256 id, bytes memory) external returns (bytes4);

    function withdrawERC721(IERC721 a, uint256[] calldata nftIds) external;
}
