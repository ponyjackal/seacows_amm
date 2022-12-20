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

interface ISeacowsPairFactoryLikeInterface extends ethers.utils.Interface {
  functions: {
    "callAllowed(address)": FunctionFragment;
    "initializePairERC20FromOracle(address,address,address,address,uint128,uint96,uint128,uint256[],uint256)": FunctionFragment;
    "initializePairETHFromOracle(address,address,address,uint128,uint96,uint128,uint256[])": FunctionFragment;
    "isPair(address,uint8)": FunctionFragment;
    "priceOracleRegistry()": FunctionFragment;
    "protocolFeeMultiplier()": FunctionFragment;
    "protocolFeeRecipient()": FunctionFragment;
    "routerStatus(address)": FunctionFragment;
  };

  encodeFunctionData(functionFragment: "callAllowed", values: [string]): string;
  encodeFunctionData(
    functionFragment: "initializePairERC20FromOracle",
    values: [
      string,
      string,
      string,
      string,
      BigNumberish,
      BigNumberish,
      BigNumberish,
      BigNumberish[],
      BigNumberish
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "initializePairETHFromOracle",
    values: [
      string,
      string,
      string,
      BigNumberish,
      BigNumberish,
      BigNumberish,
      BigNumberish[]
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "isPair",
    values: [string, BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "priceOracleRegistry",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "protocolFeeMultiplier",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "protocolFeeRecipient",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "routerStatus",
    values: [string]
  ): string;

  decodeFunctionResult(
    functionFragment: "callAllowed",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "initializePairERC20FromOracle",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "initializePairETHFromOracle",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "isPair", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "priceOracleRegistry",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "protocolFeeMultiplier",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "protocolFeeRecipient",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "routerStatus",
    data: BytesLike
  ): Result;

  events: {};
}

export class ISeacowsPairFactoryLike extends BaseContract {
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

  interface: ISeacowsPairFactoryLikeInterface;

  functions: {
    callAllowed(target: string, overrides?: CallOverrides): Promise<[boolean]>;

    initializePairERC20FromOracle(
      pair: string,
      _token: string,
      _nft: string,
      _assetRecipient: string,
      _delta: BigNumberish,
      _fee: BigNumberish,
      _spotPrice: BigNumberish,
      _initialNFTIDs: BigNumberish[],
      _initialTokenBalance: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    initializePairETHFromOracle(
      pair: string,
      _nft: string,
      _assetRecipient: string,
      _delta: BigNumberish,
      _fee: BigNumberish,
      _spotPrice: BigNumberish,
      _initialNFTIDs: BigNumberish[],
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    isPair(
      potentialPair: string,
      variant: BigNumberish,
      overrides?: CallOverrides
    ): Promise<[boolean]>;

    priceOracleRegistry(overrides?: CallOverrides): Promise<[string]>;

    protocolFeeMultiplier(overrides?: CallOverrides): Promise<[BigNumber]>;

    protocolFeeRecipient(overrides?: CallOverrides): Promise<[string]>;

    routerStatus(
      router: string,
      overrides?: CallOverrides
    ): Promise<
      [boolean, boolean] & { allowed: boolean; wasEverAllowed: boolean }
    >;
  };

  callAllowed(target: string, overrides?: CallOverrides): Promise<boolean>;

  initializePairERC20FromOracle(
    pair: string,
    _token: string,
    _nft: string,
    _assetRecipient: string,
    _delta: BigNumberish,
    _fee: BigNumberish,
    _spotPrice: BigNumberish,
    _initialNFTIDs: BigNumberish[],
    _initialTokenBalance: BigNumberish,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  initializePairETHFromOracle(
    pair: string,
    _nft: string,
    _assetRecipient: string,
    _delta: BigNumberish,
    _fee: BigNumberish,
    _spotPrice: BigNumberish,
    _initialNFTIDs: BigNumberish[],
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  isPair(
    potentialPair: string,
    variant: BigNumberish,
    overrides?: CallOverrides
  ): Promise<boolean>;

  priceOracleRegistry(overrides?: CallOverrides): Promise<string>;

  protocolFeeMultiplier(overrides?: CallOverrides): Promise<BigNumber>;

  protocolFeeRecipient(overrides?: CallOverrides): Promise<string>;

  routerStatus(
    router: string,
    overrides?: CallOverrides
  ): Promise<
    [boolean, boolean] & { allowed: boolean; wasEverAllowed: boolean }
  >;

  callStatic: {
    callAllowed(target: string, overrides?: CallOverrides): Promise<boolean>;

    initializePairERC20FromOracle(
      pair: string,
      _token: string,
      _nft: string,
      _assetRecipient: string,
      _delta: BigNumberish,
      _fee: BigNumberish,
      _spotPrice: BigNumberish,
      _initialNFTIDs: BigNumberish[],
      _initialTokenBalance: BigNumberish,
      overrides?: CallOverrides
    ): Promise<void>;

    initializePairETHFromOracle(
      pair: string,
      _nft: string,
      _assetRecipient: string,
      _delta: BigNumberish,
      _fee: BigNumberish,
      _spotPrice: BigNumberish,
      _initialNFTIDs: BigNumberish[],
      overrides?: CallOverrides
    ): Promise<void>;

    isPair(
      potentialPair: string,
      variant: BigNumberish,
      overrides?: CallOverrides
    ): Promise<boolean>;

    priceOracleRegistry(overrides?: CallOverrides): Promise<string>;

    protocolFeeMultiplier(overrides?: CallOverrides): Promise<BigNumber>;

    protocolFeeRecipient(overrides?: CallOverrides): Promise<string>;

    routerStatus(
      router: string,
      overrides?: CallOverrides
    ): Promise<
      [boolean, boolean] & { allowed: boolean; wasEverAllowed: boolean }
    >;
  };

  filters: {};

  estimateGas: {
    callAllowed(target: string, overrides?: CallOverrides): Promise<BigNumber>;

    initializePairERC20FromOracle(
      pair: string,
      _token: string,
      _nft: string,
      _assetRecipient: string,
      _delta: BigNumberish,
      _fee: BigNumberish,
      _spotPrice: BigNumberish,
      _initialNFTIDs: BigNumberish[],
      _initialTokenBalance: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    initializePairETHFromOracle(
      pair: string,
      _nft: string,
      _assetRecipient: string,
      _delta: BigNumberish,
      _fee: BigNumberish,
      _spotPrice: BigNumberish,
      _initialNFTIDs: BigNumberish[],
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    isPair(
      potentialPair: string,
      variant: BigNumberish,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    priceOracleRegistry(overrides?: CallOverrides): Promise<BigNumber>;

    protocolFeeMultiplier(overrides?: CallOverrides): Promise<BigNumber>;

    protocolFeeRecipient(overrides?: CallOverrides): Promise<BigNumber>;

    routerStatus(router: string, overrides?: CallOverrides): Promise<BigNumber>;
  };

  populateTransaction: {
    callAllowed(
      target: string,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    initializePairERC20FromOracle(
      pair: string,
      _token: string,
      _nft: string,
      _assetRecipient: string,
      _delta: BigNumberish,
      _fee: BigNumberish,
      _spotPrice: BigNumberish,
      _initialNFTIDs: BigNumberish[],
      _initialTokenBalance: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    initializePairETHFromOracle(
      pair: string,
      _nft: string,
      _assetRecipient: string,
      _delta: BigNumberish,
      _fee: BigNumberish,
      _spotPrice: BigNumberish,
      _initialNFTIDs: BigNumberish[],
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    isPair(
      potentialPair: string,
      variant: BigNumberish,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    priceOracleRegistry(
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    protocolFeeMultiplier(
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    protocolFeeRecipient(
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    routerStatus(
      router: string,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;
  };
}
