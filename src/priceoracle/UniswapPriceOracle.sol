// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import { IUniswapV2Factory, IUniswapV2Pair } from "../interfaces/IUniswapPriceOracle.sol";
import { IERC20 } from "../interfaces/IERC20.sol";

contract UniswapPriceOracle {
    // Uniswap constants
    address public constant UNISWAP_V2_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f; // goerli
    address public constant WETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6; // goerli weth
    uint256 private constant ORACLE_PRECISION = 10**18;
    // erc20 => uniswapV2Pair, we use weth => erc20 pairs
    mapping(address => address) public uniswapV2Pairs;

    function getPrice(address token) external returns (uint256) {
        require(token != address(0), "Invalid token address");

        if (uniswapV2Pairs[token] == address(0)) {
            uniswapV2Pairs[token] = IUniswapV2Factory(UNISWAP_V2_FACTORY).getPair(WETH, token);
        }

        require(uniswapV2Pairs[token] != address(0), "No pair found");

        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(uniswapV2Pairs[token]).getReserves();

        uint256 decimalDiff = IERC20(WETH).decimals() / IERC20(token).decimals();

        return (reserve0 * ORACLE_PRECISION) / decimalDiff / reserve1;
    }
}
