// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {Test, console} from "forge-std/Test.sol";
import {CryptoTools} from "../src/CryptoTools.sol";

import {BinaryIMTData} from "../src/libraries/InternalBinaryIMT.sol";
import {PoseidonT2} from "../src/libraries/PoseidonT2.sol";
import {PoseidonT3} from "../src/libraries/PoseidonT3.sol";

import {UltraVerifier as IMTVerifier} from "../../circuits/imt/target/contract.sol";

import {ConvertBytes32ToString} from "../src/libraries/Bytes32ToString.sol";

contract CryptographyTest is Test, ConvertBytes32ToString {
    CryptoTools public hasher;

    IMTVerifier public verifier;

    function setUp() public {
        hasher = new CryptoTools();
        verifier = new IMTVerifier();
    }

    function test_hash() public view {
        uint256 result = hasher.hash(1, 2);
        console.log("result: %d", result);

        bytes32 value = bytes32(result);
        console.logBytes32(value);
    }

    function test_IMTinsert() public {
        (uint256 depth, uint256 root, uint256 numberOfLeaves,) = hasher.binaryIMTData();

        console.log("root: %d", root);
        console.log("depth: %d", depth);
        console.log("numberOfLeaves: %d", numberOfLeaves);
        hasher.insert(1);

        (depth, root, numberOfLeaves,) = hasher.binaryIMTData();
        console.log("root: %d", root);
        console.log("depth: %d", depth);
        console.log("numberOfLeaves: %d", numberOfLeaves);
    }

    function test_IMT_insertVerify() public {
        (uint256 depth, uint256 root, uint256 numberOfLeaves,) = hasher.binaryIMTData();
        console.log("Initial state - depth: %d, numberOfLeaves: %d", depth, numberOfLeaves);

        uint256 leafValue = 1;
        hasher.insert(leafValue);

        (depth, root, numberOfLeaves,) = hasher.binaryIMTData();
        console.log("After insertion - depth: %d, numberOfLeaves: %d", depth, numberOfLeaves);

        (uint256[] memory proofSiblings, uint8[] memory proofPathIndices) = hasher.createProof(0);

        console.log("leafValue: %d", leafValue);

        console.log("root: %d", root);

        console.log("Proof siblings:");
        for (uint256 i = 0; i < proofSiblings.length; i++) {
            console.logBytes32(bytes32(proofSiblings[i]));
        }

        console.log("Proof path indices:");
        for (uint256 i = 0; i < proofPathIndices.length; i++) {
            console.logBytes32(bytes32(uint256(proofPathIndices[i])));
        }

        require(hasher.verify(leafValue, proofSiblings, proofPathIndices), "failed");
        console.log("Leaf %d verified successfully.", leafValue);
    }

    function test_IMT_writeOutput() public {
        vm.writeFile("data/root.txt", "");
        vm.writeFile("data/commitment_hash.txt", "");
        vm.writeFile("data/nulifier_hash.txt", "");
        vm.writeFile("data/proof_siblings.txt", "");
        vm.writeFile("data/proof_path_indices.txt", "");
        vm.writeFile("data/nullifier.txt", "");
        vm.writeFile("data/secret.txt", "");

        // private inputs
        uint256 nullifier = 0;
        uint256 secret = 0;

        // calculated inside circuit
        uint256 commitmentHash = PoseidonT3.hash([nullifier, secret]);
        uint256 nullifierHash = PoseidonT2.hash([nullifier]);

        hasher.insert(commitmentHash);

        (, uint256 root,,) = hasher.binaryIMTData();

        (uint256[] memory proofSiblings, uint8[] memory proofPathIndices) = hasher.createProof(0);

        vm.writeFile("data/root.txt", bytes32ToString(bytes32(root)));
        vm.writeFile("data/commitment_hash.txt", bytes32ToString(bytes32(commitmentHash)));
        vm.writeFile("data/nullifier_hash.txt", bytes32ToString(bytes32(nullifierHash)));
        vm.writeFile("data/nullifier.txt", bytes32ToString(bytes32(nullifier)));
        vm.writeFile("data/secret.txt", bytes32ToString(bytes32(secret)));

        for (uint256 i = 0; i < proofSiblings.length; i++) {
            string memory path = "data/proof_siblings.txt";
            vm.writeLine(path, bytes32ToString(bytes32(proofSiblings[i])));
        }

        console.log("Proof path indices:");
        for (uint256 i = 0; i < proofPathIndices.length; i++) {
            string memory path = "data/proof_path_indices.txt";
            vm.writeLine(path, bytes32ToString(bytes32(uint256(proofPathIndices[i]))));
        }

        require(hasher.verify(commitmentHash, proofSiblings, proofPathIndices), "failed");
    }

    function test_IMT_proof() public {
        // private inputs
        uint256 nullifier = 0;
        uint256 secret = 0;

        uint256 commitmentHash = PoseidonT3.hash([nullifier, secret]);
        uint256 nulifierHash = PoseidonT2.hash([nullifier]);

        string memory proof = vm.readLine("./data/proof.txt");
        bytes memory proofBytes = vm.parseBytes(proof);

        string memory input_0 = vm.readLine("./data/input_0.txt");
        string memory input_1 = vm.readLine("./data/input_1.txt");

        bytes32[] memory publicInputs = new bytes32[](2);
        publicInputs[0] = stringToBytes32(input_0);
        publicInputs[1] = stringToBytes32(input_1);

        console.log("checking zk proof");
        verifier.verify(proofBytes, publicInputs);
        console.log("verified");
    }
}
