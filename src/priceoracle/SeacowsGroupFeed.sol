// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "./AggregatorV2V3Interface.sol";

contract SeacowsGroupFeed is AggregatorV2V3Interface {
    uint256 public constant override version = 0;

    uint8 public override decimals;
    int256 public override latestAnswer;
    uint256 public override latestTimestamp;
    uint256 public override latestRound;

    address public registry;
    address public collection;
    uint256 public groupId;

    mapping(uint256 => int256) public override getAnswer;
    mapping(uint256 => uint256) public override getTimestamp;
    mapping(uint256 => uint256) private getStartedAt;

    constructor() {
        registry = msg.sender;
    }

    function initialize(address _collection, uint256 _groupId) external {
        require(msg.sender == registry, "GroupFeed: FORBIDDEN");
        collection = _collection;
        groupId = _groupId;
    }

    function updateAnswer(int256 _answer) public onlyRegistry {
        latestAnswer = _answer;
        latestTimestamp = block.timestamp;
        latestRound++;
        getAnswer[latestRound] = _answer;
        getTimestamp[latestRound] = block.timestamp;
        getStartedAt[latestRound] = block.timestamp;
    }

    function updateRoundData(uint80 _roundId, int256 _answer, uint256 _timestamp, uint256 _startedAt)
        public
        onlyRegistry
    {
        latestRound = _roundId;
        latestAnswer = _answer;
        latestTimestamp = _timestamp;
        getAnswer[latestRound] = _answer;
        getTimestamp[latestRound] = _timestamp;
        getStartedAt[latestRound] = _startedAt;
    }

    function getRoundData(uint80 _roundId)
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (_roundId, getAnswer[_roundId], getStartedAt[_roundId], getTimestamp[_roundId], _roundId);
    }

    function latestRoundData()
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (
            uint80(latestRound),
            getAnswer[latestRound],
            getStartedAt[latestRound],
            getTimestamp[latestRound],
            uint80(latestRound)
        );
    }

    function description() external view override returns (string memory) {
        return "v0.0.1/GroupFeed.sol";
    }

    modifier onlyRegistry() {
        require(msg.sender == registry, "only registry may call");
        _;
    }
}
