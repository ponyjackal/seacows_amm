import goerli from "./goerli";
import mumbai from "./mumbai";
import { SupportedChain } from "../enums";

export default {
  [SupportedChain.GÖRLI]: goerli,
  [SupportedChain.MUMBAI]: mumbai,
};
