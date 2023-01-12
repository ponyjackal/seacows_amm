// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

// @dev Solmate's ERC20 is used instead of OZ's ERC20 so we can use safeTransferLib for cheaper safeTransfers for
// ETH and ERC20 tokens
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";

import { SeacowsPair } from "./SeacowsPair.sol";
import { SeacowsRouter } from "./SeacowsRouter.sol";
import { SeacowsPairETH } from "./SeacowsPairETH.sol";
import { ICurve } from "./bondingcurve/ICurve.sol";
import { SeacowsPairERC20 } from "./SeacowsPairERC20.sol";
import { SeacowsPairCloner } from "./lib/SeacowsPairCloner.sol";
import { SeacowsPairEnumerableETH } from "./SeacowsPairEnumerableETH.sol";
import { SeacowsPairEnumerableERC20 } from "./SeacowsPairEnumerableERC20.sol";
import { SeacowsPairMissingEnumerableETH } from "./SeacowsPairMissingEnumerableETH.sol";
import { SeacowsPairMissingEnumerableERC20 } from "./SeacowsPairMissingEnumerableERC20.sol";
import { SeacowsPairERC1155ETH } from "./SeacowsPairERC1155ETH.sol";
import { SeacowsPairERC1155ERC20 } from "./SeacowsPairERC1155ERC20.sol";
import { ChainlinkAggregator } from "./priceoracle/ChainlinkAggregator.sol";
import { UniswapPriceOracle } from "./priceoracle/UniswapPriceOracle.sol";

import { ISeacowsPairETH } from "./interfaces/ISeacowsPairETH.sol";
import { ISeacowsPairFactoryLike } from "./interfaces/ISeacowsPairFactoryLike.sol";
import { ISeacowsPairERC20 } from "./interfaces/ISeacowsPairERC20.sol";

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
    SeacowsPairERC1155ETH public immutable erc1155ETHTemplate;
    SeacowsPairERC1155ERC20 public immutable erc1155ERC20Template;
    address payable public override protocolFeeRecipient;

    // Price oracles
    ChainlinkAggregator public immutable chainlinkAggregator;
    UniswapPriceOracle public immutable uniswapPriceOracle;

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
        SeacowsPairERC1155ETH _erc1155ETHTemplate,
        SeacowsPairERC1155ERC20 _erc1155ERC20Template,
        address payable _protocolFeeRecipient,
        uint256 _protocolFeeMultiplier,
        address _priceOracleRegistry,
        ChainlinkAggregator _chainlinkAggregator,
        UniswapPriceOracle _uniswapPriceOracle
    ) {
        enumerableETHTemplate = _enumerableETHTemplate;
        missingEnumerableETHTemplate = _missingEnumerableETHTemplate;
        enumerableERC20Template = _enumerableERC20Template;
        missingEnumerableERC20Template = _missingEnumerableERC20Template;
        erc1155ETHTemplate = _erc1155ETHTemplate;
        erc1155ERC20Template = _erc1155ERC20Template;
        protocolFeeRecipient = _protocolFeeRecipient;

        require(_protocolFeeMultiplier <= MAX_PROTOCOL_FEE, "Fee too large");
        protocolFeeMultiplier = _protocolFeeMultiplier;
        priceOracleRegistry = _priceOracleRegistry;
        chainlinkAggregator = _chainlinkAggregator;
        uniswapPriceOracle = _uniswapPriceOracle;
    }

    /**
     * Modifiers
     */
    modifier onlyChainlinkAggregator() {
        require(msg.sender == address(chainlinkAggregator), "Not a chainlink aggregator");
        _;
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

        pair = SeacowsPairETH(payable(template.cloneETHPair(this, _bondingCurve, address(_nft), uint8(_poolType))));

        // mint LP tokens if trade pair
        if (_poolType == SeacowsPair.PoolType.TRADE) {
            pair.mintLPToken(msg.sender, _initialNFTIDs.length);
        }

        _initializePairETH(
            ISeacowsPairETH(address(pair)),
            _nft,
            _assetRecipient,
            _delta,
            _fee,
            _spotPrice,
            _initialNFTIDs
        );
        emit NewPair(address(pair));
    }

    /**
        @notice Creates an erc1155 pair contract using EIP-1167.
        @param _nft The NFT contract of the collection the pair trades
        @param _tokenId The ERC1155 token id
        @param _bondingCurve The bonding curve for the pair to price NFTs, must be whitelisted
        @param _amounts the initial amounts of erc1155 tokens
        @param _fee The initial % fee taken, if this is a trade pair 
        @return pair The new pair
     */
    function createPairERC1155ETH(IERC1155 _nft, uint256 _tokenId, ICurve _bondingCurve, uint256 _amounts, uint96 _fee)
        external
        payable
        returns (SeacowsPairETH pair)
    {
        // TODO; only CPMM can be used here for _bondingCurve
        address template = address(erc1155ETHTemplate);
        // create a pair
        pair = SeacowsPairETH(
            payable(
                template.cloneERC1155ETHPair(
                    this,
                    _bondingCurve,
                    address(_nft),
                    uint8(SeacowsPair.PoolType.TRADE),
                    _tokenId
                )
            )
        );

        // mint LP tokens
        pair.mintLPToken(msg.sender, _amounts);

        _initializePairETHERC1155(ISeacowsPairETH(address(pair)), _nft, _tokenId, _amounts, _fee);
        emit NewPair(address(pair));
    }

    /**
        @notice Creates a pair contract using price oracle
        @param _nft The NFT contract of the collection the pair trades
        @param _bondingCurve The bonding curve for the pair to price NFTs, must be whitelisted
        @param _assetRecipient The address that will receive the assets traders give during trades.
                              If set to address(0), assets will be sent to the pool address.
                              Not available to TRADE pools. 
        @param _poolType TOKEN, NFT, or TRADE
        @param _delta The delta value used by the bonding curve. The meaning of delta depends
        on the specific curve.
        @param _fee The fee taken by the LP in each trade. Can only be non-zero if _poolType is Trade.
        @param _initialNFTIDs The list of IDs of NFTs to transfer from the sender to the pair
        @return pair The new pair
     */
    function createPairETHWithPriceOracle(
        IERC721 _nft,
        ICurve _bondingCurve,
        address payable _assetRecipient,
        SeacowsPair.PoolType _poolType,
        uint128 _delta,
        uint96 _fee,
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

        pair = SeacowsPairETH(payable(template.cloneETHPair(this, _bondingCurve, address(_nft), uint8(_poolType))));

        // request floor price from chainlink
        chainlinkAggregator.requestCryptoPriceETH(
            ISeacowsPairETH(address(pair)),
            _nft,
            _assetRecipient,
            _delta,
            _fee,
            _initialNFTIDs
        );

        emit NewPair(address(pair));
    }

    /**
     * @dev callback from ChainlinkAggregator
     */
    function initializePairETHFromOracle(
        ISeacowsPairETH pair,
        IERC721 _nft,
        address payable _assetRecipient,
        uint128 _delta,
        uint96 _fee,
        uint128 _spotPrice,
        uint256[] calldata _initialNFTIDs
    ) external override onlyChainlinkAggregator {
        _initializePairETH(pair, _nft, _assetRecipient, _delta, _fee, _spotPrice, _initialNFTIDs);
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
        IERC20 token;
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
                template.cloneERC20Pair(
                    this,
                    params.bondingCurve,
                    address(params.nft),
                    uint8(params.poolType),
                    params.token
                )
            )
        );

        // mint LP tokens if trade pair
        if (params.poolType == SeacowsPair.PoolType.TRADE) {
            pair.mintLPToken(msg.sender, params.initialNFTIDs.length);
        }

        _initializePairERC20(
            ISeacowsPairERC20(address(pair)),
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
        @notice Creates an erc1155 pair contract using EIP-1167.
        @param _nft The NFT contract of the collection the pair trades
        @param _tokenId The ERC1155 token id
        @param _bondingCurve The bonding curve for the pair to price NFTs, must be whitelisted
        @param _amounts the initial amounts of erc1155 tokens
        @param _token ERC20 token
        @param _tokenAmount ERC20 token amount
        @param _fee The initial % fee taken, if this is a trade pair 
        @return pair The new pair
     */
    function createPairERC1155ERC20(
        IERC1155 _nft,
        uint256 _tokenId,
        ICurve _bondingCurve,
        uint256 _amounts,
        IERC20 _token,
        uint256 _tokenAmount,
        uint96 _fee
    ) external payable returns (SeacowsPairETH pair) {
        address template = address(erc1155ETHTemplate);
        // create a pair
        pair = SeacowsPairETH(
            payable(
                template.cloneERC1155ERC20Pair(
                    this,
                    _bondingCurve,
                    address(_nft),
                    uint8(SeacowsPair.PoolType.TRADE),
                    _token,
                    _tokenId
                )
            )
        );

        // mint LP tokens
        pair.mintLPToken(msg.sender, _amounts);

        _initializePairERC20ERC1155(
            ISeacowsPairETH(address(pair)),
            _nft,
            _tokenId,
            _amounts,
            _token,
            _tokenAmount,
            _fee
        );
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
    struct CreateERC20PairParamsWithPriceOracle {
        IERC20 token;
        IERC721 nft;
        ICurve bondingCurve;
        address payable assetRecipient;
        SeacowsPair.PoolType poolType;
        uint128 delta;
        uint96 fee;
        uint256[] initialNFTIDs;
        uint256 initialTokenBalance;
    }

    function createPairERC20WithPriceOracle(CreateERC20PairParamsWithPriceOracle calldata params)
        external
        returns (SeacowsPairERC20 pair)
    {
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
                template.cloneERC20Pair(
                    this,
                    params.bondingCurve,
                    address(params.nft),
                    uint8(params.poolType),
                    params.token
                )
            )
        );

        // request floor price from chainlink
        chainlinkAggregator.requestCryptoPriceERC20(
            ISeacowsPairERC20(address(pair)),
            params.token,
            params.nft,
            params.assetRecipient,
            params.delta,
            params.fee,
            params.initialNFTIDs,
            params.initialTokenBalance
        );

        emit NewPair(address(pair));
    }

    /**
     * @dev callback from ChainlinkAggregator
     */
    function initializePairERC20FromOracle(
        ISeacowsPairERC20 pair,
        IERC20 _token,
        IERC721 _nft,
        address payable _assetRecipient,
        uint128 _delta,
        uint96 _fee,
        uint128 _spotPrice,
        uint256[] calldata _initialNFTIDs,
        uint256 _initialTokenBalance
    ) external override onlyChainlinkAggregator {
        // get erc20 price in eth from uniswap price oracle
        uint128 tokenPrice = (uniswapPriceOracle.getPrice(address(_token)) * _spotPrice) / 10**18;

        _initializePairERC20(
            pair,
            _token,
            _nft,
            _assetRecipient,
            _delta,
            _fee,
            tokenPrice,
            _initialNFTIDs,
            _initialTokenBalance
        );
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
        ISeacowsPairETH _pair,
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

    function _initializePairETHERC1155(
        ISeacowsPairETH _pair,
        IERC1155 _nft,
        uint256 _tokenId,
        uint256 _amounts,
        uint96 _fee
    ) internal {
        uint128 initSpotPrice = (uint128)(msg.value / _amounts);

        // initialize pair,
        _pair.initialize(msg.sender, payable(address(0)), 0, _fee, initSpotPrice);

        // transfer initial ETH to pair
        payable(address(_pair)).safeTransferETH(msg.value);

        // transfer nfts to the pair
        _nft.safeTransferFrom(msg.sender, address(_pair), _tokenId, _amounts, "");
    }

    function _initializePairERC20(
        ISeacowsPairERC20 _pair,
        IERC20 _token,
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
        _token.transferFrom(msg.sender, address(_pair), _initialTokenBalance);

        // transfer initial NFTs from sender to pair
        uint256 numNFTs = _initialNFTIDs.length;
        for (uint256 i; i < numNFTs; ) {
            _nft.safeTransferFrom(msg.sender, address(_pair), _initialNFTIDs[i]);

            unchecked {
                ++i;
            }
        }
    }

    function _initializePairERC20ERC1155(
        ISeacowsPairETH _pair,
        IERC1155 _nft,
        uint256 _tokenId,
        uint256 _amounts,
        IERC20 _token,
        uint256 _tokenAmount,
        uint96 _fee
    ) internal {
        uint128 initSpotPrice = (uint128)(_tokenAmount / _amounts);

        // initialize pair,
        _pair.initialize(msg.sender, payable(address(0)), 0, _fee, initSpotPrice);

        // transfer initial tokens to pair
        _token.transferFrom(msg.sender, address(_pair), _tokenAmount);

        // transfer initial ETH to pair
        payable(address(_pair)).safeTransferETH(msg.value);

        // transfer nfts to the pair
        _nft.safeTransferFrom(msg.sender, address(_pair), _tokenId, _amounts, "");
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

    /** Liquidity functions */

    /**
     * @dev add ERC20 liquidity into trading pair
     * @param _nftIDs NFT ids
     * @param _amount ERC20 token amount
     */
    function addLiquidityERC20(SeacowsPairERC20 _pair, uint256[] calldata _nftIDs, uint256 _amount) external {
        uint256 numNFTs = _nftIDs.length;

        require(_pair.poolType() == SeacowsPair.PoolType.TRADE, "Not a trade pair");
        require(numNFTs > 0, "Invalid NFT amount");
        require(numNFTs * _pair.spotPrice() <= _amount, "Insufficient token amount");

        // transfer tokens to pair
        _pair.token().safeTransferFrom(msg.sender, address(_pair), _amount);

        // transfer NFTs from sender to pair
        for (uint256 i; i < numNFTs; ) {
            IERC721(_pair.nft()).safeTransferFrom(msg.sender, address(_pair), _nftIDs[i]);

            unchecked {
                ++i;
            }
        }

        // mint LP tokens
        _pair.mintLPToken(msg.sender, numNFTs);
    }

    /**
     * @dev add ERC20 liquidity into ERC1155 trading pair
     * @param _amount ERC20 token amount
     * @param _tokenAmount ERC20 token amount
     */
    function addLiquidityERC20ERC1155(SeacowsPairERC1155ERC20 _pair, uint256 _amount, uint256 _tokenAmount) external {
        require(_pair.poolType() == SeacowsPair.PoolType.TRADE, "Not a trade pair");
        require(
            _pair.pairVariant() == ISeacowsPairFactoryLike.PairVariant.ERC1155_ERC20,
            "Not a ERC1155/ERC20 trade pair"
        );
        require(_amount > 0, "Invalid NFT amount");
        require(_amount * _pair.spotPrice() <= _amount, "Insufficient token amount");

        // transfer tokens to pair
        _pair.token().safeTransferFrom(msg.sender, address(_pair), _tokenAmount);

        // transfer NFTs from sender to pair
        IERC1155(_pair.nft()).safeTransferFrom(msg.sender, address(_pair), _pair.tokenId(), _amount, "");

        // mint LP tokens
        _pair.mintLPToken(msg.sender, _amount);
    }

    /**
     * @dev add ETH liquidity into trading pair
     * @param _nftIDs NFT ids
     */
    function addLiquidityETH(SeacowsPairETH _pair, uint256[] calldata _nftIDs) external payable {
        uint256 numNFTs = _nftIDs.length;

        require(_pair.poolType() == SeacowsPair.PoolType.TRADE, "Not a trade pair");
        require(numNFTs > 0, "Invalid NFT amount");
        require(numNFTs * _pair.spotPrice() <= msg.value, "Insufficient token amount");

        // transfer NFTs from sender to pair
        for (uint256 i; i < numNFTs; ) {
            IERC721(_pair.nft()).safeTransferFrom(msg.sender, address(_pair), _nftIDs[i]);

            unchecked {
                ++i;
            }
        }

        // transfer eth to the pair
        payable(_pair).safeTransferETH(msg.value);

        // mint LP tokens
        _pair.mintLPToken(msg.sender, numNFTs);
    }

    /**
     * @dev add ETH liquidity into ERC1155 trading pair
     * @param _amount NFT amount
     */
    function addLiquidityETHERC1155(SeacowsPairERC1155ETH _pair, uint256 _amount) external payable {
        require(_pair.poolType() == SeacowsPair.PoolType.TRADE, "Not a trade pair");
        require(_pair.pairVariant() == ISeacowsPairFactoryLike.PairVariant.ERC1155_ETH, "Not a ERC1155/ETH trade pair");
        require(_amount > 0, "Invalid NFT amount");
        require(_amount * _pair.spotPrice() <= msg.value, "Insufficient token amount");

        // transfer NFTs from sender to pair
        IERC1155(_pair.nft()).safeTransferFrom(msg.sender, address(_pair), _pair.tokenId(), _amount, "");

        // transfer eth to the pair
        payable(_pair).safeTransferETH(msg.value);

        // mint LP tokens
        _pair.mintLPToken(msg.sender, _amount);
    }

    /**
     * @dev remove ERC20 liquidity from trading pair
     * @param _amount lp token amount to remove
     * @param _nftIDs NFT ids to withdraw
     */
    function removeLiquidityERC20(SeacowsPairERC20 _pair, uint256 _amount, uint256[] calldata _nftIDs) external {
        uint256 numNFTs = _nftIDs.length;

        require(_pair.poolType() == SeacowsPair.PoolType.TRADE, "Not a trade pair");
        require(_amount > 0, "Invalid amount");
        require(_amount == numNFTs, "Invalid NFT amount");

        // burn LP token; we check if the user has engouh LP token in the function below
        _pair.burnLPToken(msg.sender, _amount);

        // transfer tokens to the user
        uint256 tokenAmount = _amount * _pair.spotPrice();
        _pair.token().safeTransferFrom(address(_pair), msg.sender, tokenAmount);

        // transfer NFTs from sender to pair
        for (uint256 i; i < numNFTs; ) {
            IERC721(_pair.nft()).safeTransferFrom(address(_pair), msg.sender, _nftIDs[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev remove ERC20 liquidity from ERC1155 trading pair
     * @param _amount lp token amount to remove
     */
    function removeLiquidityERC20ERC1155(SeacowsPairERC1155ERC20 _pair, uint256 _amount) external {
        require(_pair.poolType() == SeacowsPair.PoolType.TRADE, "Not a trade pair");
        require(
            _pair.pairVariant() == ISeacowsPairFactoryLike.PairVariant.ERC1155_ERC20,
            "Not a ERC1155/ERC20 trade pair"
        );
        require(_amount > 0, "Invalid amount");

        // burn LP token; we check if the user has engouh LP token in the function below
        _pair.burnLPToken(msg.sender, _amount);

        // transfer tokens to the user
        uint256 tokenAmount = _amount * _pair.spotPrice();
        _pair.token().safeTransferFrom(address(_pair), msg.sender, tokenAmount);

        // transfer NFTs from sender to pair
        IERC1155(_pair.nft()).safeTransferFrom(address(_pair), msg.sender, _pair.tokenId(), _amount, "");
    }

    /**
     * @dev remove ETH liquidity from trading pair
     * @param _amount lp token amount to remove
     * @param _nftIDs NFT ids to withdraw
     */
    function removeLiquidityETH(SeacowsPairETH _pair, uint256 _amount, uint256[] calldata _nftIDs) external {
        uint256 numNFTs = _nftIDs.length;

        require(_pair.poolType() == SeacowsPair.PoolType.TRADE, "Not a trade pair");
        require(_amount > 0, "Invalid amount");
        require(_amount == numNFTs, "Invalid NFT amount");

        // burn LP token; we check if the user has engouh LP token in the function below
        _pair.burnLPToken(msg.sender, _amount);

        uint256 ethAmount = _amount * _pair.spotPrice();
        _pair.removeLPETH(msg.sender, ethAmount);

        // transfer NFTs from sender to pair
        for (uint256 i; i < numNFTs; ) {
            IERC721(_pair.nft()).safeTransferFrom(address(_pair), msg.sender, _nftIDs[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev remove ETH liquidity from ERC1155 trading pair
     * @param _amount lp token amount to remove
     */
    function removeLiquidityETH(SeacowsPairERC1155ETH _pair, uint256 _amount) external {
        require(_pair.poolType() == SeacowsPair.PoolType.TRADE, "Not a trade pair");
        require(_pair.pairVariant() == ISeacowsPairFactoryLike.PairVariant.ERC1155_ETH, "Not a ERC1155/ETH trade pair");
        require(_amount > 0, "Invalid amount");

        // burn LP token; we check if the user has engouh LP token in the function below
        _pair.burnLPToken(msg.sender, _amount);

        uint256 ethAmount = _amount * _pair.spotPrice();
        _pair.removeLPETH(msg.sender, ethAmount);

        // transfer NFTs from sender to pair
        IERC1155(_pair.nft()).safeTransferFrom(address(_pair), msg.sender, _pair.tokenId(), _amount, "");
    }
}
