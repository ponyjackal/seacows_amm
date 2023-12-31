// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { ISeacowsPair } from "./ISeacowsPair.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISeacowsPairFactoryLike {
    enum PairVariant {
        ERC721_ERC20,
        ERC1155_ERC20
    }

    function protocolFeeMultiplier() external view returns (uint256);

    function protocolFeeRecipient() external view returns (address payable);
}
