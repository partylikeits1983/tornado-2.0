// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {PoseidonT2} from "./libraries/PoseidonT2.sol";
import {PoseidonT3} from "./libraries/PoseidonT3.sol";
import {InternalBinaryIMT, BinaryIMTData} from "./libraries/InternalBinaryIMT.sol";

contract CryptoTools {
    uint256 public leafCount;

    BinaryIMTData public binaryIMTData;

    constructor() {
        InternalBinaryIMT._init(binaryIMTData, 32, 0);
    }

    function lastSubtrees(uint256 index) public view returns (uint256[2] memory) {
        return binaryIMTData.lastSubtrees[index];
    }

    function hash1(uint256 x) public pure returns (uint256) {
        uint256[1] memory input = [x];
        return PoseidonT2.hash(input);
    }

    function hash2(uint256 x, uint256 y) public pure returns (uint256) {
        uint256[2] memory input = [x, y];
        return PoseidonT3.hash(input);
    }

    // @dev this is used for the frontend
    // DO NOT USE IN PRODUCTION, only for hackathon
    function generateLeaf(uint256 secret, uint256 nullifier, uint256 asset, uint256 liquidity, uint256 depositTimestamp)
        public
        pure
        returns (uint256)
    {
        uint256 hash_0 = PoseidonT3.hash([secret, nullifier]);
        uint256 hash_1 = PoseidonT3.hash([asset, liquidity]);
        uint256 hash_2 = PoseidonT3.hash([hash_0, hash_1]);
        uint256 leaf = PoseidonT3.hash([hash_2, depositTimestamp]);

        return leaf;
    }

    function insert(uint256 leaf) public {
        InternalBinaryIMT._insert(binaryIMTData, leaf);
        leafCount++;
    }

    function verify(uint256 leaf, uint256[] calldata proofSiblings, uint8[] calldata proofPathIndices)
        public
        view
        returns (bool)
    {
        return InternalBinaryIMT._verify(binaryIMTData, leaf, proofSiblings, proofPathIndices);
    }

    function createProof(uint256 leafIndex)
        public
        view
        returns (uint256[] memory proofSiblings, uint8[] memory proofPathIndices)
    {
        return InternalBinaryIMT._createProof(binaryIMTData, leafIndex);
    }
}
