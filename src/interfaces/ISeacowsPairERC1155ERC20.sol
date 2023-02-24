// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import { ISeacowsPair } from "./ISeacowsPair.sol";

interface ISeacowsPairERC1155ERC20 is ISeacowsPair {
    function tokenId() external pure returns (uint256 _tokenId);

    function withdrawERC1155(address _recipient, uint256 _amount) external;

    function getReserve() external view returns (uint256 nftReserve, uint256 tokenReserve);
}
