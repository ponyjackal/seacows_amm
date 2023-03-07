// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "forge-std/Test.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SeacowsRouter } from "../../SeacowsRouter.sol";
import { SeacowsPair } from "../../SeacowsPair.sol";
import { TestSeacowsSFT } from "../../TestCollectionToken/TestSeacowsSFT.sol";
import { TestERC20 } from "../../TestCollectionToken/TestERC20.sol";
import { SeacowsPairERC1155ERC20 } from "../../SeacowsPairERC1155ERC20.sol";
import { ISeacowsPairERC1155ERC20 } from "../../interfaces/ISeacowsPairERC1155ERC20.sol";
import { WhenCreatePair } from "../base/WhenCreatePair.t.sol";

/// @dev See the "Writing Tests" section in the Foundry Book if this is your first time with Forge.
/// https://book.getfoundry.sh/forge/writing-tests
contract SeacowsPairERC1155ERC20Test is WhenCreatePair {
    TestSeacowsSFT internal testSeacowsSFT;
    ISeacowsPairERC1155ERC20 internal linearPair;
    ISeacowsPairERC1155ERC20 internal exponentialPair;
    TestERC20 internal token;

    function setUp() public override(WhenCreatePair) {
        WhenCreatePair.setUp();

        // deploy sft contract
        testSeacowsSFT = new TestSeacowsSFT();
        testSeacowsSFT.safeMint(owner);
        testSeacowsSFT.safeMint(alice);
        testSeacowsSFT.safeMint(bob);

        token = new TestERC20();
        token.mint(owner, 1e18);
        token.mint(alice, 1e18);
        token.mint(bob, 1e18);

        /** Approve Bonding Curve */
        seacowsPairFactory.setBondingCurveAllowed(linearCurve, true);
        seacowsPairFactory.setBondingCurveAllowed(exponentialCurve, true);

        // create a pair
        vm.startPrank(owner);
        token.approve(address(seacowsPairFactory), 1000000);
        testSeacowsSFT.setApprovalForAll(address(seacowsPairFactory), true);
        SeacowsPair _linearPair = createERC1155ERC20TradePair(testSeacowsSFT, 1, payable(owner), 1000, token, 100000, 10);
        linearPair = ISeacowsPairERC1155ERC20(address(_linearPair));
        vm.stopPrank();

        vm.startPrank(alice);
        token.approve(address(seacowsPairFactory), 1000000);
        testSeacowsSFT.setApprovalForAll(address(seacowsPairFactory), true);
        vm.stopPrank();

        vm.startPrank(bob);
        token.approve(address(seacowsPairFactory), 1000000);
        testSeacowsSFT.setApprovalForAll(address(seacowsPairFactory), true);
        vm.stopPrank();
    }

    function test_create_erc20_pair() public {
        address nft = linearPair.nft();
        assertEq(nft, address(testSeacowsSFT));

        uint256 tokenId = linearPair.tokenId();
        assertEq(tokenId, 1);

        uint256 spotPrice = linearPair.spotPrice();
        assertEq(spotPrice, 100);

        ERC20 _token = linearPair.token();
        assertEq(address(_token), address(token));

        SeacowsPair.PoolType poolType = linearPair.poolType();
        assertEq(uint256(poolType), uint256(SeacowsPair.PoolType.TRADE));

        uint256 lpBalance = linearPair.balanceOf(owner, 1);
        assertEq(lpBalance, 1000);
    }
}
