// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ISeacowsPair } from "./ISeacowsPair.sol";

interface ISeacowsPairEnumerable is ISeacowsPair {
    function getAllHeldIds() external view override returns (uint256[] memory);

    function onERC721Received(address, address, uint256, bytes memory) external virtual returns (bytes4);

    function withdrawERC721(IERC721 a, uint256[] calldata nftIds) external override;
}
