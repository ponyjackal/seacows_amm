// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "forge-std/Test.sol";

contract BaseSetup is Test {

    address internal owner;
    address internal alice;
    address internal bob;
    address internal carol;

    function setUp() public virtual {
        owner = vm.addr(1);
        alice = vm.addr(2);
        bob = vm.addr(3);
        carol = vm.addr(4);

        vm.deal(owner, 1000 ether);
        vm.deal(alice, 1000 ether);
        vm.deal(bob, 1000 ether);
        vm.deal(carol, 1000 ether);
    }
}
