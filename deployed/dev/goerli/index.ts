import weth from "./weth.json";
import exponential from "./exponentialCurve.json";
import linear from "./linearCurve.json";

export default {
  cureve: {
    exponential: exponential.address,
    linear: linear.address,
  },
  weth: weth.address,
};
