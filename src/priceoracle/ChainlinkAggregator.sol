// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import { ChainlinkClient, Chainlink } from "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ISeacowsPairFactoryLike } from "../interfaces/ISeacowsPairFactoryLike.sol"; 
import { ISeacowsPairERC20 } from "../interfaces/ISeacowsPairERC20.sol";

contract ChainlinkAggregator is ChainlinkClient, Ownable {
    using Chainlink for Chainlink.Request;

    uint256 private constant ORACLE_PRECISION = 10**18;
    uint256 private constant ORACLE_PAYMENT = 1 * 10**17; // solium-disable-line zeppelin/no-arithmetic-operations
    // Do not allow the oracle to submit times any further forward into the future than this constant.
    uint256 public constant ORACLE_FUTURE_LIMIT = 10 minutes;

    ISeacowsPairFactoryLike public factory;
    bytes32 public oracleJobId;
 
    struct ERC20Request {
        ISeacowsPairERC20 pair;
        IERC20 token;
        IERC721 nft;
        address payable assetRecipient;
        uint128 delta;
        uint96 fee;
        uint256[] initialNFTIDs;
        uint256 initialTokenBalance;
        uint256 timestamp;
    }

    // request id => ERC20Request info
    mapping(bytes32 => ERC20Request) private erc20Requests;
    // spot prices
    mapping(address => uint256) public spotPrices;

    constructor(
        ISeacowsPairFactoryLike _factory,
        // Chainlink requirementss
        address _chainlinkToken,
        address _chainlinkOracle,
        string memory _chainlinkJobId
    ) {
        factory = _factory;
        // Setup Chainlink props
        setChainlinkToken(_chainlinkToken);
        setChainlinkOracle(_chainlinkOracle);
        oracleJobId = stringToBytes32(_chainlinkJobId);
    }

    /** MODIFIER */
    modifier onlyFactory() {
        require(msg.sender == address(factory), "Not a factory");
        _;
    }

    modifier validateERC20Timestamp(bytes32 _requestId) {
        require(erc20Requests[_requestId].timestamp > block.timestamp - ORACLE_FUTURE_LIMIT, "Request has expired");
        _;
    }

    /** SETTER FUNCTIONS */
    function updateSeacowsPairFactory(ISeacowsPairFactoryLike _factory) external onlyOwner {
        require(address(_factory) != address(0), "Invalid SeacowsPairFactory address");
        factory = _factory;
    }

    /**
     * @notice Initiatiate a price request via chainlink for erc20 pair. 
       @param _pair The NFT contract of the collection the pair trades
       @param _nft The NFT contract of the collection the pair trades
       @param _assetRecipient The address that will receive the assets traders give during trades.
                            If set to address(0), assets will be sent to the pool address.
                              Not available to TRADE pools. 
       @param _delta The delta value used by the bonding curve. The meaning of delta depends
        on the specific curve.
       @param _fee The fee taken by the LP in each trade. Can only be non-zero if _poolType is Trade.
       @param _initialNFTIDs The list of IDs of NFTs to transfer from the sender to the pair
     */
    function requestCryptoPriceERC20(
        ISeacowsPairERC20 _pair,
        IERC20 _token,
        IERC721 _nft,
        address payable _assetRecipient,
        uint128 _delta,
        uint96 _fee,
        uint256[] calldata _initialNFTIDs,
        uint256 _initialTokenBalance
    ) external onlyFactory returns (bytes32) {
        Chainlink.Request memory req = buildChainlinkRequest(oracleJobId, address(this), this.fulfillERC20.selector);
        string memory requestURL = string(
            abi.encodePacked("https://api.reservoir.tools/oracle/collections/floor-ask/v4?collection=", Strings.toHexString(address(_nft)))
        );
        req.add("get", requestURL);

        req.add("path", "price");

        req.addInt("times", int256(ORACLE_PRECISION));

        bytes32 requestId = sendChainlinkRequest(req, ORACLE_PAYMENT);
        erc20Requests[requestId] = ERC20Request(
            _pair,
            _token,
            _nft,
            _assetRecipient,
            _delta,
            _fee,
            _initialNFTIDs,
            _initialTokenBalance,
            block.timestamp
        );

        return requestId;
    }

    function fulfillERC20(bytes32 _requestId, uint256 _price) public validateERC20Timestamp(_requestId) recordChainlinkFulfillment(_requestId) {
        ERC20Request memory request = erc20Requests[_requestId];
        factory.initializePairERC20FromOracle(
            request.pair,
            request.token,
            request.nft,
            request.assetRecipient,
            request.delta,
            request.fee,
            uint128(_price),
            request.initialNFTIDs,
            request.initialTokenBalance
        );
        delete erc20Requests[_requestId];
    }

    function stringToBytes32(string memory source) private pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            // solhint-disable-line no-inline-assembly
            result := mload(add(source, 32))
        }
    }
}
