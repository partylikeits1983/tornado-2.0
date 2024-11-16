// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {Test, console} from "forge-std/Test.sol";
import {CryptoTools} from "../src/CryptoTools.sol";

import {BinaryIMTData} from "../src/libraries/InternalBinaryIMT.sol";
import {PoseidonT2} from "../src/libraries/PoseidonT2.sol";
import {PoseidonT3} from "../src/libraries/PoseidonT3.sol";

import {UltraVerifier as DepositVerifier} from "../../circuits/deposit/target/contract.sol";
import {UltraVerifier as WithdrawVerifier} from "../../circuits/withdraw/target/contract.sol";



import {ConvertBytes32ToString} from "../src/libraries/Bytes32ToString.sol";

import {Vault} from "../src/Vault.sol";

contract CryptographyTest is Test, ConvertBytes32ToString {
    CryptoTools public hasher;

    DepositVerifier public depositVerifier;
    WithdrawVerifier public withdrawVerifier;
    Vault public vault;


    function setUp() public {
        hasher = new CryptoTools();
        depositVerifier = new DepositVerifier();
        withdrawVerifier = new WithdrawVerifier();
        vault = new Vault(address(depositVerifier));
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


    function test_deposit_proof_vault_generate_data() public {
        // public inputs
        string memory asset = vm.readLine("./data/deposit_asset.txt");
        string memory liquidityStr = vm.readLine("./data/deposit_liquidity.txt");
        string memory timestamp = vm.readLine("./data/deposit_timestamp.txt");
        string memory leaf = vm.readLine("./data/deposit_leaf.txt");

        // proof
        string memory proof = vm.readLine("./data/deposit_proof.txt");
        bytes memory proofBytes = vm.parseBytes(proof);

        // public inputs
        bytes32[] memory publicInputs = new bytes32[](4);
        publicInputs[0] = stringToBytes32(asset);
        publicInputs[1] = stringToBytes32(liquidityStr);
        publicInputs[2] = stringToBytes32(timestamp);
        publicInputs[3] = stringToBytes32(leaf);

        uint256 liquidity = uint256(stringToBytes32(liquidityStr));

        uint256 currentTimestamp = 1731646446; // Fri Nov 15 2024 04:54:06 GMT+0000
        vm.warp(currentTimestamp);

        uint256 leafIndex = vault.deposit{value: liquidity}(proofBytes, publicInputs);

        (, uint256 root,,) = vault.binaryIMTData();

        // Generate Data for Withdraw Proof
        (uint256[] memory proofSiblings, uint8[] memory proofPathIndices) = vault.createProof(leafIndex);

        vm.writeFile("data/root.txt", bytes32ToString(bytes32(root)));
        // vm.writeFile("data/leaf.txt", bytes32ToString(stringToBytes32(leaf)));

        for (uint256 i = 0; i < proofSiblings.length; i++) {
            string memory path = "data/proof_siblings.txt";
            vm.writeLine(path, bytes32ToString(bytes32(proofSiblings[i])));
        }

        for (uint256 i = 0; i < proofPathIndices.length; i++) {
            string memory path = "data/proof_path_indices.txt";
            vm.writeLine(path, bytes32ToString(bytes32(uint256(proofPathIndices[i]))));
        }
    }


    /*     function test_IMT_proof() public {
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
    } */
}
