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
        vault = new Vault(address(depositVerifier), address(withdrawVerifier));
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

    function test_write_recipient() public {
        // string memory
    }

    function test_write_nullifier() public {
        // generate nullifier_hash from nullifier

        // Path to the Prover.toml file
        string memory filePath = "circuits/deposit/Prover.toml";

        // Read the entire file content
        string memory fileContent = vm.readFile(filePath);

        // Define the key we're looking for
        string memory key = "nullifier = \"";
        bytes memory keyBytes = bytes(key);

        // Convert file content to bytes for processing
        bytes memory contentBytes = bytes(fileContent);

        // Find the starting index of the key
        uint256 startIndex = findSubstring(contentBytes, keyBytes, 0);
        require(startIndex != type(uint256).max, "nullifier key not found");

        // Calculate the starting position of the value
        uint256 valueStart = startIndex + keyBytes.length;
        require(valueStart < contentBytes.length, "Invalid file format");

        // Find the closing quote of the value
        uint256 valueEnd = valueStart;
        while (valueEnd < contentBytes.length && contentBytes[valueEnd] != '"') {
            valueEnd++;
        }
        require(valueEnd < contentBytes.length, "Closing quote not found");

        // Extract the nullifier value
        bytes memory nullifierBytes = new bytes(valueEnd - valueStart);
        for (uint256 i = 0; i < valueEnd - valueStart; i++) {
            nullifierBytes[i] = contentBytes[valueStart + i];
        }
        uint256 nullifier = stringToUint(string(nullifierBytes));

        // Output the nullifier value
        console.log("Nullifier:", nullifier);

        bytes32 nullifier_hash = bytes32(PoseidonT2.hash([nullifier]));

        vm.writeFile("data/withdraw_nullifier_hash.txt", bytes32ToString(nullifier_hash));
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

        vm.writeFile("data/proof_siblings.txt", "");
        vm.writeFile("data/proof_path_indices.txt", "");

        for (uint256 i = 0; i < proofSiblings.length; i++) {
            string memory path = "data/proof_siblings.txt";
            vm.writeLine(path, bytes32ToString(bytes32(proofSiblings[i])));
        }

        for (uint256 i = 0; i < proofPathIndices.length; i++) {
            string memory path = "data/proof_path_indices.txt";
            vm.writeLine(path, bytes32ToString(bytes32(uint256(proofPathIndices[i]))));
        }
    }

    function test_withdraw_proof() public view {
        string memory proof = vm.readLine("./data/withdraw_proof.txt");
        bytes memory proofBytes = vm.parseBytes(proof);

        string memory recipient = vm.readLine("./data/withdraw_recipient.txt");
        string memory current_timestamp = vm.readLine("./data/withdraw_current_timestamp.txt");
        string memory asset = vm.readLine("./data/withdraw_asset.txt");
        string memory liquidity = vm.readLine("./data/withdraw_liquidity.txt");
        string memory root = vm.readLine("./data/withdraw_root.txt");
        string memory nullifier_hash = vm.readLine("./data/withdraw_nullifier_hash.txt");

        console.log("recipient", recipient);
        console.log(current_timestamp);
        console.log(asset);
        console.log(liquidity);
        console.log(root);
        console.log(nullifier_hash);

        bytes32[] memory publicInputs = new bytes32[](6);
        publicInputs[0] = stringToBytes32(recipient);
        publicInputs[1] = stringToBytes32(current_timestamp);
        publicInputs[2] = stringToBytes32(asset);
        publicInputs[3] = stringToBytes32(liquidity);
        publicInputs[4] = stringToBytes32(root);
        publicInputs[5] = stringToBytes32(nullifier_hash);

        console.log("checking zk proof");
        withdrawVerifier.verify(proofBytes, publicInputs);
        console.log("verified");
    }

    function test_deposit_withdraw() public {
        // public inputs
        string memory deposit_asset = vm.readLine("./data/deposit_asset.txt");
        string memory deposit_liquidityStr = vm.readLine("./data/deposit_liquidity.txt");
        string memory deposit_timestamp = vm.readLine("./data/deposit_timestamp.txt");
        string memory deposit_leaf = vm.readLine("./data/deposit_leaf.txt");

        // proof
        string memory deposit_proof = vm.readLine("./data/deposit_proof.txt");
        bytes memory deposit_proofBytes = vm.parseBytes(deposit_proof);

        // public inputs
        bytes32[] memory deposit_publicInputs = new bytes32[](4);
        deposit_publicInputs[0] = stringToBytes32(deposit_asset);
        deposit_publicInputs[1] = stringToBytes32(deposit_liquidityStr);
        deposit_publicInputs[2] = stringToBytes32(deposit_timestamp);
        deposit_publicInputs[3] = stringToBytes32(deposit_leaf);

        uint256 deposit_liquidity = uint256(stringToBytes32(deposit_liquidityStr));

        uint256 currentTimestamp = 1731646446; // Fri Nov 15 2024 04:54:06 GMT+0000
        vm.warp(currentTimestamp);

        depositVerifier.verify(deposit_proofBytes, deposit_publicInputs);

        // Simulate deposit from an address
        address depositor = vm.addr(1);
        vm.deal(depositor, 1e18);
        vm.startPrank(depositor);

        vault.deposit{value: deposit_liquidity}(deposit_proofBytes, deposit_publicInputs);
        vm.stopPrank();

        uint256 vaultBalance = address(vault).balance;
        assert(vaultBalance == deposit_liquidity);

        string memory withdraw_proof = vm.readLine("./data/withdraw_proof.txt");
        bytes memory withdraw_proofBytes = vm.parseBytes(withdraw_proof);

        string memory withdraw_recipient = vm.readLine("./data/withdraw_recipient.txt");
        string memory withdraw_current_timestamp = vm.readLine("./data/withdraw_current_timestamp.txt");
        string memory withdraw_asset = vm.readLine("./data/withdraw_asset.txt");
        string memory withdraw_liquidity = vm.readLine("./data/withdraw_liquidity.txt");
        string memory withdraw_root = vm.readLine("./data/withdraw_root.txt");
        string memory withdraw_nullifier_hash = vm.readLine("./data/withdraw_nullifier_hash.txt");

        console.log(withdraw_recipient);
        console.log(withdraw_current_timestamp);
        console.log(withdraw_asset);
        console.log(withdraw_liquidity);
        console.log(withdraw_root);
        console.log(withdraw_nullifier_hash);

        bytes32[] memory publicInputs = new bytes32[](6);
        publicInputs[0] = stringToBytes32(withdraw_recipient);
        publicInputs[1] = stringToBytes32(withdraw_current_timestamp);
        publicInputs[2] = stringToBytes32(withdraw_asset);
        publicInputs[3] = stringToBytes32(withdraw_liquidity);
        publicInputs[4] = stringToBytes32(withdraw_root);
        publicInputs[5] = stringToBytes32(withdraw_nullifier_hash);

        uint256 timestamp = 1731747190; // Sat Nov 16 2024 08:53:10 GMT+0000
        vm.warp(timestamp);

        console.log("checking zk proof");
        withdrawVerifier.verify(withdraw_proofBytes, publicInputs);
        console.log("verified");

        // Simulate withdrawal from another address
        address withdrawer = vm.addr(2);
        vm.startPrank(withdrawer);
        vault.withdraw(withdraw_proofBytes, publicInputs);
        vm.stopPrank();

        // assert recipient balance is equal to withdraw liquidity amount
        assert(address(uint160(uint256(stringToBytes32(withdraw_recipient)))).balance == uint(stringToBytes32(withdraw_liquidity)));
    }
}
