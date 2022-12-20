/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Contract, Signer, utils } from "ethers";
import { Provider } from "@ethersproject/providers";
import type {
  ISeacowsPairETH,
  ISeacowsPairETHInterface,
} from "../ISeacowsPairETH";

const _abi = [
  {
    inputs: [],
    name: "bondingCurve",
    outputs: [
      {
        internalType: "contract ICurve",
        name: "_bondingCurve",
        type: "address",
      },
    ],
    stateMutability: "pure",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address payable",
        name: "target",
        type: "address",
      },
      {
        internalType: "bytes",
        name: "data",
        type: "bytes",
      },
    ],
    name: "call",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address payable",
        name: "newRecipient",
        type: "address",
      },
    ],
    name: "changeAssetRecipient",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint128",
        name: "newDelta",
        type: "uint128",
      },
    ],
    name: "changeDelta",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint96",
        name: "newFee",
        type: "uint96",
      },
    ],
    name: "changeFee",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint128",
        name: "newSpotPrice",
        type: "uint128",
      },
    ],
    name: "changeSpotPrice",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "factory",
    outputs: [
      {
        internalType: "contract ISeacowsPairFactoryLike",
        name: "_factory",
        type: "address",
      },
    ],
    stateMutability: "pure",
    type: "function",
  },
  {
    inputs: [],
    name: "getAllHeldIds",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "getAssetRecipient",
    outputs: [
      {
        internalType: "address payable",
        name: "_assetRecipient",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256[]",
        name: "nftIds",
        type: "uint256[]",
      },
      {
        components: [
          {
            internalType: "uint256",
            name: "groupId",
            type: "uint256",
          },
          {
            internalType: "bytes32[]",
            name: "merkleProof",
            type: "bytes32[]",
          },
        ],
        internalType: "struct SeacowsRouter.NFTDetail[]",
        name: "details",
        type: "tuple[]",
      },
    ],
    name: "getBuyNFTQuote",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256[]",
        name: "nftIds",
        type: "uint256[]",
      },
      {
        components: [
          {
            internalType: "uint256",
            name: "groupId",
            type: "uint256",
          },
          {
            internalType: "bytes32[]",
            name: "merkleProof",
            type: "bytes32[]",
          },
        ],
        internalType: "struct SeacowsRouter.NFTDetail[]",
        name: "details",
        type: "tuple[]",
      },
    ],
    name: "getSellNFTQuote",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_owner",
        type: "address",
      },
      {
        internalType: "address payable",
        name: "_assetRecipient",
        type: "address",
      },
      {
        internalType: "uint128",
        name: "_delta",
        type: "uint128",
      },
      {
        internalType: "uint96",
        name: "_fee",
        type: "uint96",
      },
      {
        internalType: "uint128",
        name: "_spotPrice",
        type: "uint128",
      },
    ],
    name: "initialize",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes[]",
        name: "calls",
        type: "bytes[]",
      },
      {
        internalType: "bool",
        name: "revertOnFail",
        type: "bool",
      },
    ],
    name: "multicall",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "nft",
    outputs: [
      {
        internalType: "contract IERC721",
        name: "_nft",
        type: "address",
      },
    ],
    stateMutability: "pure",
    type: "function",
  },
  {
    inputs: [],
    name: "pairVariant",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "poolType",
    outputs: [
      {
        internalType: "enum ISeacowsPair.PoolType",
        name: "_poolType",
        type: "uint8",
      },
    ],
    stateMutability: "pure",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256[]",
        name: "nftIds",
        type: "uint256[]",
      },
      {
        components: [
          {
            internalType: "uint256",
            name: "groupId",
            type: "uint256",
          },
          {
            internalType: "bytes32[]",
            name: "merkleProof",
            type: "bytes32[]",
          },
        ],
        internalType: "struct SeacowsRouter.NFTDetail[]",
        name: "details",
        type: "tuple[]",
      },
      {
        internalType: "uint256",
        name: "minExpectedTokenOutput",
        type: "uint256",
      },
      {
        internalType: "address payable",
        name: "tokenRecipient",
        type: "address",
      },
      {
        internalType: "bool",
        name: "isRouter",
        type: "bool",
      },
      {
        internalType: "address",
        name: "routerCaller",
        type: "address",
      },
    ],
    name: "swapNFTsForToken",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "numNFTs",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "maxExpectedTokenInput",
        type: "uint256",
      },
      {
        internalType: "address",
        name: "nftRecipient",
        type: "address",
      },
      {
        internalType: "bool",
        name: "isRouter",
        type: "bool",
      },
      {
        internalType: "address",
        name: "routerCaller",
        type: "address",
      },
    ],
    name: "swapTokenForAnyNFTs",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256[]",
        name: "nftIds",
        type: "uint256[]",
      },
      {
        components: [
          {
            internalType: "uint256",
            name: "groupId",
            type: "uint256",
          },
          {
            internalType: "bytes32[]",
            name: "merkleProof",
            type: "bytes32[]",
          },
        ],
        internalType: "struct SeacowsRouter.NFTDetail[]",
        name: "details",
        type: "tuple[]",
      },
      {
        internalType: "uint256",
        name: "maxExpectedTokenInput",
        type: "uint256",
      },
      {
        internalType: "address",
        name: "nftRecipient",
        type: "address",
      },
      {
        internalType: "bool",
        name: "isRouter",
        type: "bool",
      },
      {
        internalType: "address",
        name: "routerCaller",
        type: "address",
      },
    ],
    name: "swapTokenForSpecificNFTs",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "withdrawAllETH",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "contract IERC1155",
        name: "a",
        type: "address",
      },
      {
        internalType: "uint256[]",
        name: "ids",
        type: "uint256[]",
      },
      {
        internalType: "uint256[]",
        name: "amounts",
        type: "uint256[]",
      },
    ],
    name: "withdrawERC1155",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "contract ERC20",
        name: "a",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    name: "withdrawERC20",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "contract IERC721",
        name: "a",
        type: "address",
      },
      {
        internalType: "uint256[]",
        name: "nftIds",
        type: "uint256[]",
      },
    ],
    name: "withdrawERC721",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    name: "withdrawETH",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
];

export class ISeacowsPairETH__factory {
  static readonly abi = _abi;
  static createInterface(): ISeacowsPairETHInterface {
    return new utils.Interface(_abi) as ISeacowsPairETHInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): ISeacowsPairETH {
    return new Contract(address, _abi, signerOrProvider) as ISeacowsPairETH;
  }
}