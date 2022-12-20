/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Contract, Signer, utils } from "ethers";
import { Provider } from "@ethersproject/providers";
import type {
  IUniswapPriceOracle,
  IUniswapPriceOracleInterface,
} from "../IUniswapPriceOracle";

const _abi = [
  {
    inputs: [],
    name: "ORACLE_PRECISION",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "token",
        type: "address",
      },
    ],
    name: "getPrice",
    outputs: [
      {
        internalType: "uint128",
        name: "",
        type: "uint128",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
];

export class IUniswapPriceOracle__factory {
  static readonly abi = _abi;
  static createInterface(): IUniswapPriceOracleInterface {
    return new utils.Interface(_abi) as IUniswapPriceOracleInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): IUniswapPriceOracle {
    return new Contract(address, _abi, signerOrProvider) as IUniswapPriceOracle;
  }
}
