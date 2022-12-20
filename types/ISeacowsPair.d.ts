/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import {
  ethers,
  EventFilter,
  Signer,
  BigNumber,
  BigNumberish,
  PopulatedTransaction,
  BaseContract,
  ContractTransaction,
  Overrides,
  CallOverrides,
} from "ethers";
import { BytesLike } from "@ethersproject/bytes";
import { Listener, Provider } from "@ethersproject/providers";
import { FunctionFragment, EventFragment, Result } from "@ethersproject/abi";
import type { TypedEventFilter, TypedEvent, TypedListener } from "./common";

interface ISeacowsPairInterface extends ethers.utils.Interface {
  functions: {
    "bondingCurve()": FunctionFragment;
    "call(address,bytes)": FunctionFragment;
    "changeAssetRecipient(address)": FunctionFragment;
    "changeDelta(uint128)": FunctionFragment;
    "changeFee(uint96)": FunctionFragment;
    "changeSpotPrice(uint128)": FunctionFragment;
    "factory()": FunctionFragment;
    "getAllHeldIds()": FunctionFragment;
    "getAssetRecipient()": FunctionFragment;
    "getBuyNFTQuote(uint256[],tuple[])": FunctionFragment;
    "getSellNFTQuote(uint256[],tuple[])": FunctionFragment;
    "initialize(address,address,uint128,uint96,uint128)": FunctionFragment;
    "multicall(bytes[],bool)": FunctionFragment;
    "nft()": FunctionFragment;
    "pairVariant()": FunctionFragment;
    "poolType()": FunctionFragment;
    "swapNFTsForToken(uint256[],tuple[],uint256,address,bool,address)": FunctionFragment;
    "swapTokenForAnyNFTs(uint256,uint256,address,bool,address)": FunctionFragment;
    "swapTokenForSpecificNFTs(uint256[],tuple[],uint256,address,bool,address)": FunctionFragment;
    "withdrawERC1155(address,uint256[],uint256[])": FunctionFragment;
    "withdrawERC20(address,uint256)": FunctionFragment;
    "withdrawERC721(address,uint256[])": FunctionFragment;
  };

  encodeFunctionData(
    functionFragment: "bondingCurve",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "call",
    values: [string, BytesLike]
  ): string;
  encodeFunctionData(
    functionFragment: "changeAssetRecipient",
    values: [string]
  ): string;
  encodeFunctionData(
    functionFragment: "changeDelta",
    values: [BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "changeFee",
    values: [BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "changeSpotPrice",
    values: [BigNumberish]
  ): string;
  encodeFunctionData(functionFragment: "factory", values?: undefined): string;
  encodeFunctionData(
    functionFragment: "getAllHeldIds",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "getAssetRecipient",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "getBuyNFTQuote",
    values: [
      BigNumberish[],
      { groupId: BigNumberish; merkleProof: BytesLike[] }[]
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "getSellNFTQuote",
    values: [
      BigNumberish[],
      { groupId: BigNumberish; merkleProof: BytesLike[] }[]
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "initialize",
    values: [string, string, BigNumberish, BigNumberish, BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "multicall",
    values: [BytesLike[], boolean]
  ): string;
  encodeFunctionData(functionFragment: "nft", values?: undefined): string;
  encodeFunctionData(
    functionFragment: "pairVariant",
    values?: undefined
  ): string;
  encodeFunctionData(functionFragment: "poolType", values?: undefined): string;
  encodeFunctionData(
    functionFragment: "swapNFTsForToken",
    values: [
      BigNumberish[],
      { groupId: BigNumberish; merkleProof: BytesLike[] }[],
      BigNumberish,
      string,
      boolean,
      string
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "swapTokenForAnyNFTs",
    values: [BigNumberish, BigNumberish, string, boolean, string]
  ): string;
  encodeFunctionData(
    functionFragment: "swapTokenForSpecificNFTs",
    values: [
      BigNumberish[],
      { groupId: BigNumberish; merkleProof: BytesLike[] }[],
      BigNumberish,
      string,
      boolean,
      string
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "withdrawERC1155",
    values: [string, BigNumberish[], BigNumberish[]]
  ): string;
  encodeFunctionData(
    functionFragment: "withdrawERC20",
    values: [string, BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "withdrawERC721",
    values: [string, BigNumberish[]]
  ): string;

  decodeFunctionResult(
    functionFragment: "bondingCurve",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "call", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "changeAssetRecipient",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "changeDelta",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "changeFee", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "changeSpotPrice",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "factory", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "getAllHeldIds",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "getAssetRecipient",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "getBuyNFTQuote",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "getSellNFTQuote",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "initialize", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "multicall", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "nft", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "pairVariant",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "poolType", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "swapNFTsForToken",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "swapTokenForAnyNFTs",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "swapTokenForSpecificNFTs",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "withdrawERC1155",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "withdrawERC20",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "withdrawERC721",
    data: BytesLike
  ): Result;

  events: {};
}

export class ISeacowsPair extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  listeners<EventArgsArray extends Array<any>, EventArgsObject>(
    eventFilter?: TypedEventFilter<EventArgsArray, EventArgsObject>
  ): Array<TypedListener<EventArgsArray, EventArgsObject>>;
  off<EventArgsArray extends Array<any>, EventArgsObject>(
    eventFilter: TypedEventFilter<EventArgsArray, EventArgsObject>,
    listener: TypedListener<EventArgsArray, EventArgsObject>
  ): this;
  on<EventArgsArray extends Array<any>, EventArgsObject>(
    eventFilter: TypedEventFilter<EventArgsArray, EventArgsObject>,
    listener: TypedListener<EventArgsArray, EventArgsObject>
  ): this;
  once<EventArgsArray extends Array<any>, EventArgsObject>(
    eventFilter: TypedEventFilter<EventArgsArray, EventArgsObject>,
    listener: TypedListener<EventArgsArray, EventArgsObject>
  ): this;
  removeListener<EventArgsArray extends Array<any>, EventArgsObject>(
    eventFilter: TypedEventFilter<EventArgsArray, EventArgsObject>,
    listener: TypedListener<EventArgsArray, EventArgsObject>
  ): this;
  removeAllListeners<EventArgsArray extends Array<any>, EventArgsObject>(
    eventFilter: TypedEventFilter<EventArgsArray, EventArgsObject>
  ): this;

  listeners(eventName?: string): Array<Listener>;
  off(eventName: string, listener: Listener): this;
  on(eventName: string, listener: Listener): this;
  once(eventName: string, listener: Listener): this;
  removeListener(eventName: string, listener: Listener): this;
  removeAllListeners(eventName?: string): this;

  queryFilter<EventArgsArray extends Array<any>, EventArgsObject>(
    event: TypedEventFilter<EventArgsArray, EventArgsObject>,
    fromBlockOrBlockhash?: string | number | undefined,
    toBlock?: string | number | undefined
  ): Promise<Array<TypedEvent<EventArgsArray & EventArgsObject>>>;

  interface: ISeacowsPairInterface;

  functions: {
    bondingCurve(
      overrides?: CallOverrides
    ): Promise<[string] & { _bondingCurve: string }>;

    call(
      target: string,
      data: BytesLike,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    changeAssetRecipient(
      newRecipient: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    changeDelta(
      newDelta: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    changeFee(
      newFee: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    changeSpotPrice(
      newSpotPrice: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    factory(
      overrides?: CallOverrides
    ): Promise<[string] & { _factory: string }>;

    getAllHeldIds(
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    getAssetRecipient(
      overrides?: CallOverrides
    ): Promise<[string] & { _assetRecipient: string }>;

    getBuyNFTQuote(
      nftIds: BigNumberish[],
      details: { groupId: BigNumberish; merkleProof: BytesLike[] }[],
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    getSellNFTQuote(
      nftIds: BigNumberish[],
      details: { groupId: BigNumberish; merkleProof: BytesLike[] }[],
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    initialize(
      _owner: string,
      _assetRecipient: string,
      _delta: BigNumberish,
      _fee: BigNumberish,
      _spotPrice: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    multicall(
      calls: BytesLike[],
      revertOnFail: boolean,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    nft(overrides?: CallOverrides): Promise<[string] & { _nft: string }>;

    pairVariant(
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    poolType(
      overrides?: CallOverrides
    ): Promise<[number] & { _poolType: number }>;

    swapNFTsForToken(
      nftIds: BigNumberish[],
      details: { groupId: BigNumberish; merkleProof: BytesLike[] }[],
      minExpectedTokenOutput: BigNumberish,
      tokenRecipient: string,
      isRouter: boolean,
      routerCaller: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    swapTokenForAnyNFTs(
      numNFTs: BigNumberish,
      maxExpectedTokenInput: BigNumberish,
      nftRecipient: string,
      isRouter: boolean,
      routerCaller: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    swapTokenForSpecificNFTs(
      nftIds: BigNumberish[],
      details: { groupId: BigNumberish; merkleProof: BytesLike[] }[],
      maxExpectedTokenInput: BigNumberish,
      nftRecipient: string,
      isRouter: boolean,
      routerCaller: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    withdrawERC1155(
      a: string,
      ids: BigNumberish[],
      amounts: BigNumberish[],
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    withdrawERC20(
      a: string,
      amount: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    withdrawERC721(
      a: string,
      nftIds: BigNumberish[],
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;
  };

  bondingCurve(overrides?: CallOverrides): Promise<string>;

  call(
    target: string,
    data: BytesLike,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  changeAssetRecipient(
    newRecipient: string,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  changeDelta(
    newDelta: BigNumberish,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  changeFee(
    newFee: BigNumberish,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  changeSpotPrice(
    newSpotPrice: BigNumberish,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  factory(overrides?: CallOverrides): Promise<string>;

  getAllHeldIds(
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  getAssetRecipient(overrides?: CallOverrides): Promise<string>;

  getBuyNFTQuote(
    nftIds: BigNumberish[],
    details: { groupId: BigNumberish; merkleProof: BytesLike[] }[],
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  getSellNFTQuote(
    nftIds: BigNumberish[],
    details: { groupId: BigNumberish; merkleProof: BytesLike[] }[],
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  initialize(
    _owner: string,
    _assetRecipient: string,
    _delta: BigNumberish,
    _fee: BigNumberish,
    _spotPrice: BigNumberish,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  multicall(
    calls: BytesLike[],
    revertOnFail: boolean,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  nft(overrides?: CallOverrides): Promise<string>;

  pairVariant(
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  poolType(overrides?: CallOverrides): Promise<number>;

  swapNFTsForToken(
    nftIds: BigNumberish[],
    details: { groupId: BigNumberish; merkleProof: BytesLike[] }[],
    minExpectedTokenOutput: BigNumberish,
    tokenRecipient: string,
    isRouter: boolean,
    routerCaller: string,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  swapTokenForAnyNFTs(
    numNFTs: BigNumberish,
    maxExpectedTokenInput: BigNumberish,
    nftRecipient: string,
    isRouter: boolean,
    routerCaller: string,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  swapTokenForSpecificNFTs(
    nftIds: BigNumberish[],
    details: { groupId: BigNumberish; merkleProof: BytesLike[] }[],
    maxExpectedTokenInput: BigNumberish,
    nftRecipient: string,
    isRouter: boolean,
    routerCaller: string,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  withdrawERC1155(
    a: string,
    ids: BigNumberish[],
    amounts: BigNumberish[],
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  withdrawERC20(
    a: string,
    amount: BigNumberish,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  withdrawERC721(
    a: string,
    nftIds: BigNumberish[],
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  callStatic: {
    bondingCurve(overrides?: CallOverrides): Promise<string>;

    call(
      target: string,
      data: BytesLike,
      overrides?: CallOverrides
    ): Promise<void>;

    changeAssetRecipient(
      newRecipient: string,
      overrides?: CallOverrides
    ): Promise<void>;

    changeDelta(
      newDelta: BigNumberish,
      overrides?: CallOverrides
    ): Promise<void>;

    changeFee(newFee: BigNumberish, overrides?: CallOverrides): Promise<void>;

    changeSpotPrice(
      newSpotPrice: BigNumberish,
      overrides?: CallOverrides
    ): Promise<void>;

    factory(overrides?: CallOverrides): Promise<string>;

    getAllHeldIds(overrides?: CallOverrides): Promise<void>;

    getAssetRecipient(overrides?: CallOverrides): Promise<string>;

    getBuyNFTQuote(
      nftIds: BigNumberish[],
      details: { groupId: BigNumberish; merkleProof: BytesLike[] }[],
      overrides?: CallOverrides
    ): Promise<void>;

    getSellNFTQuote(
      nftIds: BigNumberish[],
      details: { groupId: BigNumberish; merkleProof: BytesLike[] }[],
      overrides?: CallOverrides
    ): Promise<void>;

    initialize(
      _owner: string,
      _assetRecipient: string,
      _delta: BigNumberish,
      _fee: BigNumberish,
      _spotPrice: BigNumberish,
      overrides?: CallOverrides
    ): Promise<void>;

    multicall(
      calls: BytesLike[],
      revertOnFail: boolean,
      overrides?: CallOverrides
    ): Promise<void>;

    nft(overrides?: CallOverrides): Promise<string>;

    pairVariant(overrides?: CallOverrides): Promise<void>;

    poolType(overrides?: CallOverrides): Promise<number>;

    swapNFTsForToken(
      nftIds: BigNumberish[],
      details: { groupId: BigNumberish; merkleProof: BytesLike[] }[],
      minExpectedTokenOutput: BigNumberish,
      tokenRecipient: string,
      isRouter: boolean,
      routerCaller: string,
      overrides?: CallOverrides
    ): Promise<void>;

    swapTokenForAnyNFTs(
      numNFTs: BigNumberish,
      maxExpectedTokenInput: BigNumberish,
      nftRecipient: string,
      isRouter: boolean,
      routerCaller: string,
      overrides?: CallOverrides
    ): Promise<void>;

    swapTokenForSpecificNFTs(
      nftIds: BigNumberish[],
      details: { groupId: BigNumberish; merkleProof: BytesLike[] }[],
      maxExpectedTokenInput: BigNumberish,
      nftRecipient: string,
      isRouter: boolean,
      routerCaller: string,
      overrides?: CallOverrides
    ): Promise<void>;

    withdrawERC1155(
      a: string,
      ids: BigNumberish[],
      amounts: BigNumberish[],
      overrides?: CallOverrides
    ): Promise<void>;

    withdrawERC20(
      a: string,
      amount: BigNumberish,
      overrides?: CallOverrides
    ): Promise<void>;

    withdrawERC721(
      a: string,
      nftIds: BigNumberish[],
      overrides?: CallOverrides
    ): Promise<void>;
  };

  filters: {};

  estimateGas: {
    bondingCurve(overrides?: CallOverrides): Promise<BigNumber>;

    call(
      target: string,
      data: BytesLike,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    changeAssetRecipient(
      newRecipient: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    changeDelta(
      newDelta: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    changeFee(
      newFee: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    changeSpotPrice(
      newSpotPrice: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    factory(overrides?: CallOverrides): Promise<BigNumber>;

    getAllHeldIds(
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    getAssetRecipient(overrides?: CallOverrides): Promise<BigNumber>;

    getBuyNFTQuote(
      nftIds: BigNumberish[],
      details: { groupId: BigNumberish; merkleProof: BytesLike[] }[],
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    getSellNFTQuote(
      nftIds: BigNumberish[],
      details: { groupId: BigNumberish; merkleProof: BytesLike[] }[],
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    initialize(
      _owner: string,
      _assetRecipient: string,
      _delta: BigNumberish,
      _fee: BigNumberish,
      _spotPrice: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    multicall(
      calls: BytesLike[],
      revertOnFail: boolean,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    nft(overrides?: CallOverrides): Promise<BigNumber>;

    pairVariant(
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    poolType(overrides?: CallOverrides): Promise<BigNumber>;

    swapNFTsForToken(
      nftIds: BigNumberish[],
      details: { groupId: BigNumberish; merkleProof: BytesLike[] }[],
      minExpectedTokenOutput: BigNumberish,
      tokenRecipient: string,
      isRouter: boolean,
      routerCaller: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    swapTokenForAnyNFTs(
      numNFTs: BigNumberish,
      maxExpectedTokenInput: BigNumberish,
      nftRecipient: string,
      isRouter: boolean,
      routerCaller: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    swapTokenForSpecificNFTs(
      nftIds: BigNumberish[],
      details: { groupId: BigNumberish; merkleProof: BytesLike[] }[],
      maxExpectedTokenInput: BigNumberish,
      nftRecipient: string,
      isRouter: boolean,
      routerCaller: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    withdrawERC1155(
      a: string,
      ids: BigNumberish[],
      amounts: BigNumberish[],
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    withdrawERC20(
      a: string,
      amount: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    withdrawERC721(
      a: string,
      nftIds: BigNumberish[],
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    bondingCurve(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    call(
      target: string,
      data: BytesLike,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    changeAssetRecipient(
      newRecipient: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    changeDelta(
      newDelta: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    changeFee(
      newFee: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    changeSpotPrice(
      newSpotPrice: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    factory(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    getAllHeldIds(
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    getAssetRecipient(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    getBuyNFTQuote(
      nftIds: BigNumberish[],
      details: { groupId: BigNumberish; merkleProof: BytesLike[] }[],
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    getSellNFTQuote(
      nftIds: BigNumberish[],
      details: { groupId: BigNumberish; merkleProof: BytesLike[] }[],
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    initialize(
      _owner: string,
      _assetRecipient: string,
      _delta: BigNumberish,
      _fee: BigNumberish,
      _spotPrice: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    multicall(
      calls: BytesLike[],
      revertOnFail: boolean,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    nft(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    pairVariant(
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    poolType(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    swapNFTsForToken(
      nftIds: BigNumberish[],
      details: { groupId: BigNumberish; merkleProof: BytesLike[] }[],
      minExpectedTokenOutput: BigNumberish,
      tokenRecipient: string,
      isRouter: boolean,
      routerCaller: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    swapTokenForAnyNFTs(
      numNFTs: BigNumberish,
      maxExpectedTokenInput: BigNumberish,
      nftRecipient: string,
      isRouter: boolean,
      routerCaller: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    swapTokenForSpecificNFTs(
      nftIds: BigNumberish[],
      details: { groupId: BigNumberish; merkleProof: BytesLike[] }[],
      maxExpectedTokenInput: BigNumberish,
      nftRecipient: string,
      isRouter: boolean,
      routerCaller: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    withdrawERC1155(
      a: string,
      ids: BigNumberish[],
      amounts: BigNumberish[],
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    withdrawERC20(
      a: string,
      amount: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    withdrawERC721(
      a: string,
      nftIds: BigNumberish[],
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;
  };
}
