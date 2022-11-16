// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "./SeacowsGroupFeed.sol";

contract SeacowsCollectionRegistry {
    address public admin;
    mapping(address => mapping(uint256 => address)) public getFeeds;
    mapping(address => bytes32) public getMerkleRoot;
    mapping(address => string) public getMerkleProof;
    address[] public allFeeds;

    event MerkleRootChanged(address collection, bytes32 merkleRoot);
    event FeedCreated(address indexed collection, uint256 groupId, address feed, uint);
    event NewAdmin(address oldAdmin, address newAdmin);

    constructor() public {
        admin = msg.sender;
    }

    function setMerkleRoot(address collection, bytes32 _merkleRoot) public onlyAdmin {
        // require(getMerkleRoot[collection] == bytes32(0), "CollectionRegistry: Merkle root already set");
        getMerkleRoot[collection] = _merkleRoot;
        emit MerkleRootChanged(collection, _merkleRoot);
    }

    function MerkleProofURI(address collection, string memory uri) public onlyAdmin {
        getMerkleProof[collection] = uri;
    }

    function createFeed(address collection, uint256 groupId) public onlyAdmin returns (address feed) {
        require(getFeeds[collection][groupId] == address(0), "CollectionRegistry: FEED_EXISTS");
        feed = address(new SeacowsGroupFeed());
        SeacowsGroupFeed(feed).initialize(collection, groupId);
        getFeeds[collection][groupId] = feed;
        allFeeds.push(feed);
        emit FeedCreated(collection, groupId, feed, allFeeds.length);
    }

    function updateAnswer(address collection, uint256 groupId, int256 _answer) public onlyAdmin {
        _updateAnswer(collection, groupId, _answer);
    }

    function _updateAnswer(address collection, uint256 groupId, int256 _answer) private {
        address feed = getFeeds[collection][groupId];
        if (feed == address(0)) {
            // create feed
            feed = this.createFeed(collection, groupId);
        }
        // require(feed != address(0), 'CollectionRegistry: FEED_NOT_EXISTS');
        SeacowsGroupFeed(feed).updateAnswer(_answer);
    }

    function batchUpdateAnswer(address[] memory collection, uint256[] memory groupId, int256[] memory _answer)
        public
        onlyAdmin
    {
        for (uint j = 0; j < collection.length; j++) {
            _updateAnswer(collection[j], groupId[j], _answer[j]);
        }
    }

    function verifyProof(bytes32 root, bytes32 leaf, bytes32[] memory proof) private pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }

    function getAssetPrice(address collection, uint256 tokenId, uint256 groupId, bytes32[] calldata merkleProof)
        external
        view
        returns (int256)
    {
        address feed = getFeeds[collection][groupId];
        bytes32 merkleRoot = getMerkleRoot[collection];
        require(feed != address(0), "CollectionRegistry: FEED_NOT_EXISTS");
        require(merkleRoot != bytes32(0), "CollectionRegistry: Merkle root not set");
        // verify mapping tokenId -> groupId
        bytes32 leaf = keccak256(abi.encodePacked(tokenId, groupId));
        bool valid = verifyProof(merkleRoot, leaf, merkleProof);
        require(valid, "CollectionRegistry: Valid proof required.");
        return SeacowsGroupFeed(feed).latestAnswer();
    }

    function getGroupPrice(address collection, uint256 groupId) external view returns (int256) {
        address feed = getFeeds[collection][groupId];
        bytes32 merkleRoot = getMerkleRoot[collection];
        require(feed != address(0), "CollectionRegistry: FEED_NOT_EXISTS");
        require(merkleRoot != bytes32(0), "CollectionRegistry: Merkle root not set");
        return SeacowsGroupFeed(feed).latestAnswer();
    }

    function setAdmin(address newAdmin) external onlyAdmin {
        address oldAdmin = admin;
        admin = newAdmin;
        emit NewAdmin(oldAdmin, newAdmin);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin may call");
        _;
    }
}
