// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

// @dev Solmate's ERC20 is used instead of OZ's ERC20 so we can use safeTransferLib for cheaper safeTransfers for
// ETH and ERC20 tokens
import { ERC20 } from "./solmate/ERC20.sol";
import { SafeTransferLib } from "./solmate/SafeTransferLib.sol";

import { SeacowsPair } from "./SeacowsPair.sol";
import { SeacowsRouter } from "./SeacowsRouter.sol";
import { SeacowsPairETH } from "./SeacowsPairETH.sol";
import { ICurve } from "./bondingcurve/ICurve.sol";
import { SeacowsPairERC20 } from "./SeacowsPairERC20.sol";
import { SeacowsPairCloner } from "./lib/SeacowsPairCloner.sol";
import { ISeacowsPairFactoryLike } from "./ISeacowsPairFactoryLike.sol";
import { SeacowsPairEnumerableETH } from "./SeacowsPairEnumerableETH.sol";
import { SeacowsPairEnumerableERC20 } from "./SeacowsPairEnumerableERC20.sol";
import { SeacowsPairMissingEnumerableETH } from "./SeacowsPairMissingEnumerableETH.sol";
import { SeacowsPairMissingEnumerableERC20 } from "./SeacowsPairMissingEnumerableERC20.sol";

///Inspired by 0xmons; Modified from https://github.com/sudoswap/lssvm
contract SeacowsPairFactory is Ownable, ISeacowsPairFactoryLike {
    using SeacowsPairCloner for address;
    using SafeTransferLib for address payable;
    using SafeTransferLib for ERC20;

    bytes4 private constant INTERFACE_ID_ERC721_ENUMERABLE = type(IERC721Enumerable).interfaceId;

    uint256 internal constant MAX_PROTOCOL_FEE = 0.10e18; // 10%, must <= 1 - MAX_FEE

    SeacowsPairEnumerableETH public immutable enumerableETHTemplate;
    SeacowsPairMissingEnumerableETH public immutable missingEnumerableETHTemplate;
    SeacowsPairEnumerableERC20 public immutable enumerableERC20Template;
    SeacowsPairMissingEnumerableERC20 public immutable missingEnumerableERC20Template;
    address payable public override protocolFeeRecipient;

    // Units are in base 1e18
    uint256 public override protocolFeeMultiplier;

    address public override priceOracleRegistry;

    mapping(ICurve => bool) public bondingCurveAllowed;
    mapping(address => bool) public override callAllowed;
    struct RouterStatus {
        bool allowed;
        bool wasEverAllowed;
    }
    mapping(SeacowsRouter => RouterStatus) public override routerStatus;

    event NewPair(address poolAddress);
    event TokenDeposit(address poolAddress);
    event NFTDeposit(address poolAddress);
    event PriceOracleRegistryUpdate(address poolAddress);
    event ProtocolFeeRecipientUpdate(address recipientAddress);
    event ProtocolFeeMultiplierUpdate(uint256 newMultiplier);
    event BondingCurveStatusUpdate(ICurve bondingCurve, bool isAllowed);
    event CallTargetStatusUpdate(address target, bool isAllowed);
    event RouterStatusUpdate(SeacowsRouter router, bool isAllowed);

    constructor(
        SeacowsPairEnumerableETH _enumerableETHTemplate,
        SeacowsPairMissingEnumerableETH _missingEnumerableETHTemplate,
        SeacowsPairEnumerableERC20 _enumerableERC20Template,
        SeacowsPairMissingEnumerableERC20 _missingEnumerableERC20Template,
        address payable _protocolFeeRecipient,
        uint256 _protocolFeeMultiplier,
        address _priceOracleRegistry
    ) {
        enumerableETHTemplate = _enumerableETHTemplate;
        missingEnumerableETHTemplate = _missingEnumerableETHTemplate;
        enumerableERC20Template = _enumerableERC20Template;
        missingEnumerableERC20Template = _missingEnumerableERC20Template;
        protocolFeeRecipient = _protocolFeeRecipient;

        require(_protocolFeeMultiplier <= MAX_PROTOCOL_FEE, "Fee too large");
        protocolFeeMultiplier = _protocolFeeMultiplier;
        priceOracleRegistry = _priceOracleRegistry;
    }

    /**
     * External functions
     */

    /**
        @notice Creates a pair contract using EIP-1167.
        @param _nft The NFT contract of the collection the pair trades
        @param _bondingCurve The bonding curve for the pair to price NFTs, must be whitelisted
        @param _assetRecipient The address that will receive the assets traders give during trades.
                              If set to address(0), assets will be sent to the pool address.
                              Not available to TRADE pools. 
        @param _poolType TOKEN, NFT, or TRADE
        @param _delta The delta value used by the bonding curve. The meaning of delta depends
        on the specific curve.
        @param _fee The fee taken by the LP in each trade. Can only be non-zero if _poolType is Trade.
        @param _spotPrice The initial selling spot price
        @param _initialNFTIDs The list of IDs of NFTs to transfer from the sender to the pair
        @return pair The new pair
     */
    function createPairETH(
        IERC721 _nft,
        ICurve _bondingCurve,
        address payable _assetRecipient,
        SeacowsPair.PoolType _poolType,
        uint128 _delta,
        uint96 _fee,
        uint128 _spotPrice,
        uint256[] calldata _initialNFTIDs
    ) external payable returns (SeacowsPairETH pair) {
        require(bondingCurveAllowed[_bondingCurve], "Bonding curve not whitelisted");

        // Check to see if the NFT supports Enumerable to determine which template to use
        address template;
        try IERC165(address(_nft)).supportsInterface(INTERFACE_ID_ERC721_ENUMERABLE) returns (bool isEnumerable) {
            template = isEnumerable ? address(enumerableETHTemplate) : address(missingEnumerableETHTemplate);
        } catch {
            template = address(missingEnumerableETHTemplate);
        }

        pair = SeacowsPairETH(payable(template.cloneETHPair(this, _bondingCurve, _nft, uint8(_poolType))));

        // mint LP tokens if trade pair
        if (_poolType == SeacowsPair.PoolType.TRADE) {
            pair.mintLPToken(msg.sender, _initialNFTIDs.length);
        }

        _initializePairETH(pair, _nft, _assetRecipient, _delta, _fee, _spotPrice, _initialNFTIDs);
        emit NewPair(address(pair));
    }

    /**
        @notice Creates a pair contract using EIP-1167.
        @param _nft The NFT contract of the collection the pair trades
        @param _bondingCurve The bonding curve for the pair to price NFTs, must be whitelisted
        @param _assetRecipient The address that will receive the assets traders give during trades.
                                If set to address(0), assets will be sent to the pool address.
                                Not available to TRADE pools.
        @param _poolType TOKEN, NFT, or TRADE
        @param _delta The delta value used by the bonding curve. The meaning of delta depends
        on the specific curve.
        @param _fee The fee taken by the LP in each trade. Can only be non-zero if _poolType is Trade.
        @param _spotPrice The initial selling spot price, in ETH
        @param _initialNFTIDs The list of IDs of NFTs to transfer from the sender to the pair
        @param _initialTokenBalance The initial token balance sent from the sender to the new pair
        @return pair The new pair
     */
    struct CreateERC20PairParams {
        ERC20 token;
        IERC721 nft;
        ICurve bondingCurve;
        address payable assetRecipient;
        SeacowsPair.PoolType poolType;
        uint128 delta;
        uint96 fee;
        uint128 spotPrice;
        uint256[] initialNFTIDs;
        uint256 initialTokenBalance;
    }

    function createPairERC20(CreateERC20PairParams calldata params) external returns (SeacowsPairERC20 pair) {
        require(bondingCurveAllowed[params.bondingCurve], "Bonding curve not whitelisted");

        // Check to see if the NFT supports Enumerable to determine which template to use
        address template;
        try IERC165(address(params.nft)).supportsInterface(INTERFACE_ID_ERC721_ENUMERABLE) returns (bool isEnumerable) {
            template = isEnumerable ? address(enumerableERC20Template) : address(missingEnumerableERC20Template);
        } catch {
            template = address(missingEnumerableERC20Template);
        }

        pair = SeacowsPairERC20(
            payable(
                template.cloneERC20Pair(this, params.bondingCurve, params.nft, uint8(params.poolType), params.token)
            )
        );

        // mint LP tokens if trade pair
        if (params.poolType == SeacowsPair.PoolType.TRADE) {
            pair.mintLPToken(msg.sender, params.initialNFTIDs.length);
        }

        _initializePairERC20(
            pair,
            params.token,
            params.nft,
            params.assetRecipient,
            params.delta,
            params.fee,
            params.spotPrice,
            params.initialNFTIDs,
            params.initialTokenBalance
        );
        emit NewPair(address(pair));
    }

    /**
        @notice Checks if an address is a SeacowsPair. Uses the fact that the pairs are EIP-1167 minimal proxies.
        @param potentialPair The address to check
        @param variant The pair variant (NFT is enumerable or not, pair uses ETH or ERC20)
        @return True if the address is the specified pair variant, false otherwise
     */
    function isPair(address potentialPair, PairVariant variant) public view override returns (bool) {
        if (variant == PairVariant.ENUMERABLE_ERC20) {
            return SeacowsPairCloner.isERC20PairClone(address(this), address(enumerableERC20Template), potentialPair);
        } else if (variant == PairVariant.MISSING_ENUMERABLE_ERC20) {
            return
                SeacowsPairCloner.isERC20PairClone(
                    address(this),
                    address(missingEnumerableERC20Template),
                    potentialPair
                );
        } else if (variant == PairVariant.ENUMERABLE_ETH) {
            return SeacowsPairCloner.isETHPairClone(address(this), address(enumerableETHTemplate), potentialPair);
        } else if (variant == PairVariant.MISSING_ENUMERABLE_ETH) {
            return
                SeacowsPairCloner.isETHPairClone(address(this), address(missingEnumerableETHTemplate), potentialPair);
        } else {
            // invalid input
            return false;
        }
    }

    /**
        @notice Allows receiving ETH in order to receive protocol fees
     */
    receive() external payable {}

    /**
     * Admin functions
     */

    /**
        @notice Withdraws the ETH balance to the protocol fee recipient.
        Only callable by the owner.
     */
    function withdrawETHProtocolFees() external onlyOwner {
        protocolFeeRecipient.safeTransferETH(address(this).balance);
    }

    /**
        @notice Withdraws ERC20 tokens to the protocol fee recipient. Only callable by the owner.
        @param token The token to transfer
        @param amount The amount of tokens to transfer
     */
    function withdrawERC20ProtocolFees(ERC20 token, uint256 amount) external onlyOwner {
        token.safeTransfer(protocolFeeRecipient, amount);
    }

    /**
        @notice Changes the protocol fee recipient address. Only callable by the owner.
        @param _protocolFeeRecipient The new fee recipient
     */
    function changeProtocolFeeRecipient(address payable _protocolFeeRecipient) external onlyOwner {
        require(_protocolFeeRecipient != address(0), "0 address");
        protocolFeeRecipient = _protocolFeeRecipient;
        emit ProtocolFeeRecipientUpdate(_protocolFeeRecipient);
    }

    /**
        @notice Changes the price oracle registry address. Only callable by the owner.
        @param _priceOracleRegistry The new fee recipient
     */
    function changePriceOracleRegistry(address _priceOracleRegistry) external onlyOwner {
        require(_priceOracleRegistry != address(0), "0 address");
        priceOracleRegistry = _priceOracleRegistry;
        emit PriceOracleRegistryUpdate(_priceOracleRegistry);
    }

    /**
        @notice Changes the protocol fee multiplier. Only callable by the owner.
        @param _protocolFeeMultiplier The new fee multiplier, 18 decimals
     */
    function changeProtocolFeeMultiplier(uint256 _protocolFeeMultiplier) external onlyOwner {
        require(_protocolFeeMultiplier <= MAX_PROTOCOL_FEE, "Fee too large");
        protocolFeeMultiplier = _protocolFeeMultiplier;
        emit ProtocolFeeMultiplierUpdate(_protocolFeeMultiplier);
    }

    /**
        @notice Sets the whitelist status of a bonding curve contract. Only callable by the owner.
        @param bondingCurve The bonding curve contract
        @param isAllowed True to whitelist, false to remove from whitelist
     */
    function setBondingCurveAllowed(ICurve bondingCurve, bool isAllowed) external onlyOwner {
        bondingCurveAllowed[bondingCurve] = isAllowed;
        emit BondingCurveStatusUpdate(bondingCurve, isAllowed);
    }

    /**
        @notice Sets the whitelist status of a contract to be called arbitrarily by a pair.
        Only callable by the owner.
        @param target The target contract
        @param isAllowed True to whitelist, false to remove from whitelist
     */
    function setCallAllowed(address payable target, bool isAllowed) external onlyOwner {
        // ensure target is not / was not ever a router
        if (isAllowed) {
            require(!routerStatus[SeacowsRouter(target)].wasEverAllowed, "Can't call router");
        }

        callAllowed[target] = isAllowed;
        emit CallTargetStatusUpdate(target, isAllowed);
    }

    /**
        @notice Updates the router whitelist. Only callable by the owner.
        @param _router The router
        @param isAllowed True to whitelist, false to remove from whitelist
     */
    function setRouterAllowed(SeacowsRouter _router, bool isAllowed) external onlyOwner {
        // ensure target is not arbitrarily callable by pairs
        if (isAllowed) {
            require(!callAllowed[address(_router)], "Can't call router");
        }
        routerStatus[_router] = RouterStatus({ allowed: isAllowed, wasEverAllowed: true });

        emit RouterStatusUpdate(_router, isAllowed);
    }

    /**
     * Internal functions
     */

    function _initializePairETH(
        SeacowsPairETH _pair,
        IERC721 _nft,
        address payable _assetRecipient,
        uint128 _delta,
        uint96 _fee,
        uint128 _spotPrice,
        uint256[] calldata _initialNFTIDs
    ) internal {
        // initialize pair
        _pair.initialize(msg.sender, _assetRecipient, _delta, _fee, _spotPrice);

        // transfer initial ETH to pair
        payable(address(_pair)).safeTransferETH(msg.value);

        // transfer initial NFTs from sender to pair
        uint256 numNFTs = _initialNFTIDs.length;
        for (uint256 i; i < numNFTs; ) {
            _nft.safeTransferFrom(msg.sender, address(_pair), _initialNFTIDs[i]);

            unchecked {
                ++i;
            }
        }
    }

    function _initializePairERC20(
        SeacowsPairERC20 _pair,
        ERC20 _token,
        IERC721 _nft,
        address payable _assetRecipient,
        uint128 _delta,
        uint96 _fee,
        uint128 _spotPrice,
        uint256[] calldata _initialNFTIDs,
        uint256 _initialTokenBalance
    ) internal {
        // initialize pair
        _pair.initialize(msg.sender, _assetRecipient, _delta, _fee, _spotPrice);

        // transfer initial tokens to pair
        _token.safeTransferFrom(msg.sender, address(_pair), _initialTokenBalance);

        // transfer initial NFTs from sender to pair
        uint256 numNFTs = _initialNFTIDs.length;
        for (uint256 i; i < numNFTs; ) {
            _nft.safeTransferFrom(msg.sender, address(_pair), _initialNFTIDs[i]);

            unchecked {
                ++i;
            }
        }
    }

    /** 
      @dev Used to deposit NFTs into a pair after creation and emit an event for indexing (if recipient is indeed a pair)
    */
    function depositNFTs(IERC721 _nft, uint256[] calldata ids, address recipient) external {
        // transfer NFTs from caller to recipient
        uint256 numNFTs = ids.length;
        for (uint256 i; i < numNFTs; ) {
            _nft.safeTransferFrom(msg.sender, recipient, ids[i]);

            unchecked {
                ++i;
            }
        }
        if (
            isPair(recipient, PairVariant.ENUMERABLE_ERC20) ||
            isPair(recipient, PairVariant.ENUMERABLE_ETH) ||
            isPair(recipient, PairVariant.MISSING_ENUMERABLE_ERC20) ||
            isPair(recipient, PairVariant.MISSING_ENUMERABLE_ETH)
        ) {
            emit NFTDeposit(recipient);
        }
    }

    /**
      @dev Used to deposit ERC20s into a pair after creation and emit an event for indexing (if recipient is indeed an ERC20 pair and the token matches)
     */
    function depositERC20(ERC20 token, address recipient, uint256 amount) external {
        token.safeTransferFrom(msg.sender, recipient, amount);
        if (
            isPair(recipient, PairVariant.ENUMERABLE_ERC20) || isPair(recipient, PairVariant.MISSING_ENUMERABLE_ERC20)
        ) {
            if (token == SeacowsPairERC20(recipient).token()) {
                emit TokenDeposit(recipient);
            }
        }
    }
}
