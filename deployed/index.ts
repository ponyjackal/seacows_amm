import dev from "./dev";
import { Environment, SupportedChain } from "./enums";

const addresses = {
  [Environment.DEV]: dev,
  [Environment.PRODUCTION]: {},
};

export { Environment, SupportedChain, addresses };
