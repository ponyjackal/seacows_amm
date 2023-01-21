// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "forge-std/Test.sol";
import { LinearCurve } from "../bondingcurve/LinearCurve.sol";
import { CPMMCurve } from "../bondingcurve/CPMMCurve.sol";

/// @dev See the "Writing Tests" section in the Foundry Book if this is your first time with Forge.
/// https://book.getfoundry.sh/forge/writing-tests
contract BaseCurveSetup is Test {

    CPMMCurve internal cpmmCurve;
    LinearCurve internal linearCurve;

    function setUp() public virtual {
        cpmmCurve = new CPMMCurve();
        linearCurve = new LinearCurve();
    }
}
