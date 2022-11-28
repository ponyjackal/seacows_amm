// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface IChainlinkAggregator {
    function requestCryptoPrice(uint256 lotteryId, string memory tokenId) external returns (bytes32);
}
