/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Contract, Signer, utils } from "ethers";
import { Provider } from "@ethersproject/providers";
import type {
  IOwnershipTransferCallback,
  IOwnershipTransferCallbackInterface,
} from "../IOwnershipTransferCallback";

const _abi = [
  {
    inputs: [
      {
        internalType: "address",
        name: "oldOwner",
        type: "address",
      },
    ],
    name: "onOwnershipTransfer",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
];

export class IOwnershipTransferCallback__factory {
  static readonly abi = _abi;
  static createInterface(): IOwnershipTransferCallbackInterface {
    return new utils.Interface(_abi) as IOwnershipTransferCallbackInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): IOwnershipTransferCallback {
    return new Contract(
      address,
      _abi,
      signerOrProvider
    ) as IOwnershipTransferCallback;
  }
}
