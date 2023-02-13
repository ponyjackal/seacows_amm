// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface IWETH {
    function balanceOf(address account) external returns (uint256);

    function allowance(address src, address guy) external returns (uint256);

    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address guy, uint256 wad) external returns (bool);

    function withdraw(uint256) external;
}
