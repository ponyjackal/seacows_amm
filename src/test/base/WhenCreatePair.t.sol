// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "forge-std/Test.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ICurve } from "../../bondingcurve/ICurve.sol";
import { SeacowsPairERC20 } from "../../SeacowsPairERC20.sol";
import { SeacowsPairFactory } from "../../SeacowsPairFactory.sol";
import { SeacowsPair } from "../../SeacowsPair.sol";
import { TestWETH } from "../../TestCollectionToken/TestWETH.sol";
import { TestERC20 } from "../../TestCollectionToken/TestERC20.sol";
import { TestERC721 } from "../../TestCollectionToken/TestERC721.sol";
import { TestERC721Enumerable } from "../../TestCollectionToken/TestERC721Enumerable.sol";
import { BaseFactorySetup } from "./BaseFactorySetup.t.sol";
import { BaseCurveSetup } from "./BaseCurveSetup.t.sol";
import { BaseSetup } from "./BaseSetup.t.sol";

/// @dev See the "Writing Tests" section in the Foundry Book if this is your first time with Forge.
/// https://book.getfoundry.sh/forge/writing-tests
contract WhenCreatePair is BaseFactorySetup, BaseCurveSetup, BaseSetup {
    function setUp() public virtual override(BaseFactorySetup, BaseCurveSetup, BaseSetup) {
        BaseSetup.setUp();
        BaseFactorySetup.setUp();
        BaseCurveSetup.setUp();
    }

    function createTradePair(
        IERC20 _token,
        IERC721 _nft,
        ICurve _bondingCurve,
        uint128 _delta,
        uint96 _fee,
        uint128 _spotPrice,
        uint256[] memory _initialNFTIDs,
        uint256 _initialTokenBalance
    ) public returns (SeacowsPairERC20 pair) {
        _token.approve(address(seacowsPairFactory), _initialTokenBalance);
        _nft.setApprovalForAll(address(seacowsPairFactory), true);
        SeacowsPairFactory.CreateERC20PairParams memory params = SeacowsPairFactory.CreateERC20PairParams(
            _token,
            _nft,
            _bondingCurve,
            payable(address(0)),
            SeacowsPair.PoolType.TRADE,
            _delta,
            _fee,
            _spotPrice,
            _initialNFTIDs,
            _initialTokenBalance
        );
        pair = seacowsPairFactory.createPairERC20(params);
    }

    function createTradePairETH(
        IERC721 _nft,
        ICurve _bondingCurve,
        uint128 _delta,
        uint96 _fee,
        uint128 _spotPrice,
        uint256[] memory _initialNFTIDs,
        uint256 _initialETHBalance
    ) public returns (SeacowsPairERC20 pair) {
        _nft.setApprovalForAll(address(seacowsPairFactory), true);
        pair = seacowsPairFactory.createPairETH{ value: _initialETHBalance }(
            _nft,
            _bondingCurve,
            payable(address(0)),
            SeacowsPair.PoolType.TRADE,
            _delta,
            _fee,
            _spotPrice,
            _initialNFTIDs
        );
    }

    function createTokenPair(
        IERC20 _token,
        IERC721 _nft,
        ICurve _bondingCurve,
        address payable _assetRecipient,
        uint128 _delta,
        uint128 _spotPrice,
        uint256[] memory _initialNFTIDs,
        uint256 _initialTokenBalance
    ) public returns (SeacowsPairERC20 pair) {
        _token.approve(address(seacowsPairFactory), _initialTokenBalance);
        _nft.setApprovalForAll(address(seacowsPairFactory), true);
        SeacowsPairFactory.CreateERC20PairParams memory params = SeacowsPairFactory.CreateERC20PairParams(
            _token,
            _nft,
            _bondingCurve,
            _assetRecipient,
            SeacowsPair.PoolType.TOKEN,
            _delta,
            0, // Must be 0 for TOKEN Pool
            _spotPrice,
            _initialNFTIDs,
            _initialTokenBalance
        );
        pair = seacowsPairFactory.createPairERC20(params);
    }

    function createTokenPairETH(
        IERC721 _nft,
        ICurve _bondingCurve,
        address payable _assetRecipient,
        uint128 _delta,
        uint128 _spotPrice,
        uint256[] memory _initialNFTIDs
    ) public payable returns (SeacowsPairERC20 pair) {
        _nft.setApprovalForAll(address(seacowsPairFactory), true);
        pair = seacowsPairFactory.createPairETH{ value: msg.value }(
            _nft,
            _bondingCurve,
            _assetRecipient,
            SeacowsPair.PoolType.TOKEN,
            _delta,
            0, // Must be 0 for TOKEN Pool
            _spotPrice,
            _initialNFTIDs
        );
    }

    function createNFTPair(
        IERC20 _token,
        IERC721 _nft,
        ICurve _bondingCurve,
        address payable _assetRecipient,
        uint128 _delta,
        uint128 _spotPrice,
        uint256[] memory _initialNFTIDs,
        uint256 _initialTokenBalance
    ) public returns (SeacowsPairERC20 pair) {
        _token.approve(address(seacowsPairFactory), _initialTokenBalance);
        _nft.setApprovalForAll(address(seacowsPairFactory), true);
        SeacowsPairFactory.CreateERC20PairParams memory params = SeacowsPairFactory.CreateERC20PairParams(
            _token,
            _nft,
            _bondingCurve,
            _assetRecipient,
            SeacowsPair.PoolType.NFT,
            _delta,
            0, // Must be 0 for TOKEN Pool
            _spotPrice,
            _initialNFTIDs,
            _initialTokenBalance
        );
        pair = seacowsPairFactory.createPairERC20(params);
    }

    function createNFTPairETH(
        IERC721 _nft,
        ICurve _bondingCurve,
        address payable _assetRecipient,
        uint128 _delta,
        uint128 _spotPrice,
        uint256[] memory _initialNFTIDs
    ) public payable returns (SeacowsPairERC20 pair) {
        _nft.setApprovalForAll(address(seacowsPairFactory), true);
        pair = seacowsPairFactory.createPairETH{ value: msg.value }(
            _nft,
            _bondingCurve,
            _assetRecipient,
            SeacowsPair.PoolType.NFT,
            _delta,
            0, // Must be 0 for TOKEN Pool
            _spotPrice,
            _initialNFTIDs
        );
    }
    
}
