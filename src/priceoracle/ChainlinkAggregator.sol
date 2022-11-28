// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

contract ChainlinkAggregator is ChainlinkClient {
    using Chainlink for Chainlink.Request;

    uint256 private constant ORACLE_PRECISION = 1000000000000000000;
    uint256 private constant ORACLE_PAYMENT = 1 * 10**17; // solium-disable-line zeppelin/no-arithmetic-operations
    // Do not allow the oracle to submit times any further forward into the future than this constant.
    uint256 public constant ORACLE_FUTURE_LIMIT = 10 minutes;

    address internal factory;
    bytes32 public oracleJobId;

    struct Request {
        uint256 timestamp;
        address collection;
    }
    // request id => Request info
    mapping(bytes32 => Request) private requests;
    // spot prices
    mapping(address => uint256) public spotPrices;

    constructor(
        address _factory,
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
        require(msg.sender == factory, "Not a factory");
        _;
    }

    modifier validateTimestamp(bytes32 _requestId) {
        require(requests[_requestId].timestamp > block.timestamp - ORACLE_FUTURE_LIMIT, "Request has expired");
        _;
    }

    /**
     * @notice Initiatiate a price request via chainlink. Provide both the
     * @param collection nft collection address
     */
    function requestCryptoPrice(address collection) external onlyFactory returns (bytes32) {
        Chainlink.Request memory req = buildChainlinkRequest(oracleJobId, address(this), this.fulfill.selector);
        string memory requestURL = string(
            abi.encodePacked("https://api.reservoir.tools/oracle/collections/floor-ask/v4?collection=", collection)
        );
        req.add("get", requestURL);

        req.add("path", "price");

        req.addInt("times", int256(ORACLE_PRECISION));

        bytes32 requestId = sendChainlinkRequest(req, ORACLE_PAYMENT);
        requests[requestId] = Request(block.timestamp, collection);

        return requestId;
    }

    function fulfill(bytes32 _requestId, uint256 _price)
        public
        validateTimestamp(_requestId)
        recordChainlinkFulfillment(_requestId)
    {
        spotPrices[requests[_requestId].collection] = _price;

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
