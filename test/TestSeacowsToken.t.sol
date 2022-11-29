// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "forge-std/Test.sol";
import { MyToken } from "../src/TestCollectionToken/TestSeacowsToken.sol";

/// @dev See the "Writing Tests" section in the Foundry Book if this is your first time with Forge.
/// https://book.getfoundry.sh/forge/writing-tests
contract MockERC20Test is Test {
    MyToken internal token;

    uint256 internal ownerPrivateKey;
    uint256 internal spenderPrivateKey;

    address internal owner;
    address internal spender;

    function setUp() public {
        token = new MyToken();

        ownerPrivateKey = 0xA11CE;
        spenderPrivateKey = 0xB0B;

        owner = vm.addr(ownerPrivateKey);
        spender = vm.addr(spenderPrivateKey);

        token.mint(owner, 1e18);
    }

    function test_balance() public {
        uint256 balance = token.balanceOf(owner);
        assertEq(balance, 1e18);

        emit log_named_uint("owner balance", balance);
    }

    function test_approve() public {
        vm.prank(owner);
        token.approve(spender, 1e18);

        uint256 allowance = token.allowance(owner, spender);
        assertEq(allowance, 1e18);

        emit log_named_uint("owner allownace to spender", allowance);
    }
}
