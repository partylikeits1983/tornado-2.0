// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

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

    function hash(uint256 x, uint256 y) public pure returns (uint256) {
        uint256[2] memory input = [x, y];
        return PoseidonT3.hash(input);
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
