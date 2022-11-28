// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { ISeacowsPairFactoryLike } from "../ISeacowsPairFactoryLike.sol";
import { SeacowsPairETH } from "../SeacowsPairETH.sol";

contract ChainlinkAggregator is ChainlinkClient {
    using Chainlink for Chainlink.Request;

    uint256 private constant ORACLE_PRECISION = 1000000000000000000;
    uint256 private constant ORACLE_PAYMENT = 1 * 10**17; // solium-disable-line zeppelin/no-arithmetic-operations
    // Do not allow the oracle to submit times any further forward into the future than this constant.
    uint256 public constant ORACLE_FUTURE_LIMIT = 10 minutes;

    ISeacowsPairFactoryLike public factory;
    bytes32 public oracleJobId;

    struct Request {
        SeacowsPairETH pair;
        IERC721 nft;
        address payable assetRecipient;
        uint128 delta;
        uint96 fee;
        uint256[] initialNFTIDs;
        uint256 timestamp;
    }
    // request id => Request info
    mapping(bytes32 => Request) private requests;
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

    modifier validateTimestamp(bytes32 _requestId) {
        require(requests[_requestId].timestamp > block.timestamp - ORACLE_FUTURE_LIMIT, "Request has expired");
        _;
    }

    /**
     * @notice Initiatiate a price request via chainlink. Provide both the
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
    function requestCryptoPrice(
        SeacowsPairETH _pair,
        IERC721 _nft,
        address payable _assetRecipient,
        uint128 _delta,
        uint96 _fee,
        uint256[] calldata _initialNFTIDs
    ) external onlyFactory returns (bytes32) {
        Chainlink.Request memory req = buildChainlinkRequest(oracleJobId, address(this), this.fulfill.selector);
        string memory requestURL = string(
            abi.encodePacked(
                "https://api.reservoir.tools/oracle/collections/floor-ask/v4?collection=",
                Strings.toHexString(address(_nft))
            )
        );
        req.add("get", requestURL);

        req.add("path", "price");

        req.addInt("times", int256(ORACLE_PRECISION));

        bytes32 requestId = sendChainlinkRequest(req, ORACLE_PAYMENT);
        requests[requestId] = Request(_pair, _nft, _assetRecipient, _delta, _fee, _initialNFTIDs, block.timestamp);

        return requestId;
    }

    function fulfill(bytes32 _requestId, uint256 _price)
        public
        validateTimestamp(_requestId)
        recordChainlinkFulfillment(_requestId)
    {
        Request memory request = requests[_requestId];
        factory.initializePairETHFromOracle(
            request.pair,
            request.nft,
            request.assetRecipient,
            request.delta,
            request.fee,
            uint128(_price),
            request.initialNFTIDs
        );
        delete requests[_requestId];
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
