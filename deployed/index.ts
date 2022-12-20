export enum Environment {
  DEV = "DEV",
  STAGING = "STAGING",
  PRODUCTION = "PRODUCTION",
}

export enum SupportedChain {
  MAINNET = 1,
  // ROPSTEN = 3,
  // RINKEBY = 4,
  GÖRLI = 5,
  SHIBUYA = 81,
  // KOVAN = 42,
  POLYGON = 137,
  MUMBAI = 80001,
  // FANTOM = 250,
  // FANTOM_TESTNET = 4002,
  // XDAI = 100,
  BSC = 56,
  BSC_TESTNET = 97,
  // ARBITRUM = 42161,
  // ARBITRUM_TESTNET = 79377087078960,
  // MOONBEAM_TESTNET = 1287,
  // AVALANCHE = 43114,
  // AVALANCHE_TESTNET = 43113,
  // HECO = 128,
  // HECO_TESTNET = 256,
  // HARMONY = 1666600000,
  // HARMONY_TESTNET = 1666700000,
  // OKEX = 66,
  // OKEX_TESTNET = 65,
  // CELO = 42220,
  // PALM = 11297108109,
  // PALM_TESTNET = 11297108099,
  // MOONRIVER = 1285,
  // FUSE = 122,
  // TELOS = 40,
}

export const addresses = {
  [Environment.DEV]: {
    [SupportedChain.GÖRLI]: {},
    [SupportedChain.MUMBAI]: {},
  },
  [Environment.PRODUCTION]: {
    [SupportedChain.MAINNET]: {},
    [SupportedChain.POLYGON]: {},
  },
};
