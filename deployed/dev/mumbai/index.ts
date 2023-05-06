import weth from "./weth.json";
import exponential from "./exponentialCurve.json";
import linear from "./linearCurve.json";
import routerV1 from "./routerV1.json";
import erc721Factory from "./erc721Factory.json";
import pairERC721Template from "./pairERC721Template.json";

export default {
  cureve: {
    exponential: exponential.address,
    linear: linear.address,
  },
  weth: weth.address,
  routerV1: routerV1.address,
  erc721Factory: erc721Factory.address,
  pairERC721Template: pairERC721Template.address,
};
