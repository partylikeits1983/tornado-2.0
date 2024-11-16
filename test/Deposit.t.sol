// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {Test, console} from "forge-std/Test.sol";
import {CryptoTools} from "../src/CryptoTools.sol";

import {BinaryIMTData} from "../src/libraries/InternalBinaryIMT.sol";
import {PoseidonT2} from "../src/libraries/PoseidonT2.sol";
import {PoseidonT3} from "../src/libraries/PoseidonT3.sol";

import {UltraVerifier as DepositVerifier} from "../../circuits/deposit/target/contract.sol";

import {ConvertBytes32ToString} from "../src/libraries/Bytes32ToString.sol";

import {Vault} from "../src/Vault.sol";

contract CryptographyTest is Test, ConvertBytes32ToString {
    CryptoTools public hasher;
    DepositVerifier public depositVerifier;

    Vault vault;

    function setUp() public {
        hasher = new CryptoTools();
        depositVerifier = new DepositVerifier();
        vault = new Vault(address(depositVerifier));
    }

    function test_deposit_write_output() public {
        vm.writeFile("data/deposit_secret.txt", "");
        vm.writeFile("data/deposit_nullifier.txt", "");
        vm.writeFile("data/deposit_nullifier_hash.txt", "");
        vm.writeFile("data/deposit_asset.txt", "");
        vm.writeFile("data/deposit_liquidity.txt", "");
        vm.writeFile("data/deposit_timestamp.txt", "");
        vm.writeFile("data/deposit_leaf.txt", "");

        // private inputs
        uint256 secret = 123;
        uint256 nullifier = 123;

        // public inputs
        uint256 asset = uint256(uint160(address(1)));
        uint256 liquidity = 1000;
        uint256 timestamp = 3; // block.timestamp;

        uint nullifier_hash = PoseidonT2.hash([nullifier]); 

        // computed inside circuit as well
        uint256 hash_0 = PoseidonT3.hash([secret, nullifier]);
        uint256 hash_1 = PoseidonT3.hash([asset, liquidity]);
        uint256 hash_2 = PoseidonT3.hash([hash_0, hash_1]);
        uint256 leaf = PoseidonT3.hash([hash_2, timestamp]);

        vm.writeFile("data/deposit_secret.txt", bytes32ToString(bytes32(secret)));
        vm.writeFile("data/deposit_nullifier.txt", bytes32ToString(bytes32(nullifier)));
        vm.writeFile("data/deposit_nullifier_hash.txt", bytes32ToString(bytes32(nullifier_hash)));
        vm.writeFile("data/deposit_asset.txt", bytes32ToString(bytes32(asset)));
        vm.writeFile("data/deposit_liquidity.txt", bytes32ToString(bytes32(liquidity)));
        vm.writeFile("data/deposit_timestamp.txt", bytes32ToString(bytes32(timestamp)));
        vm.writeFile("data/deposit_leaf.txt", bytes32ToString(bytes32(leaf)));
    }

    function test_deposit_proof() public {
        // private inputs
        string memory secret = vm.readLine("./data/deposit_secret.txt");
        string memory nullifier = vm.readLine("./data/deposit_nullifier.txt");

        // public inputs
        string memory asset = vm.readLine("./data/deposit_asset.txt");
        string memory liquidity = vm.readLine("./data/deposit_liquidity.txt");
        string memory timestamp = vm.readLine("./data/deposit_timestamp.txt");
        string memory leaf = vm.readLine("./data/deposit_leaf.txt");

        console.log("HERE");
        console.log(asset);
        console.log(liquidity);
        console.log(timestamp);
        console.log(leaf);

        // proof
        string memory proof = vm.readLine("./data/deposit_proof.txt");
        bytes memory proofBytes = vm.parseBytes(proof);

        // public inputs
        bytes32[] memory publicInputs = new bytes32[](4);
        publicInputs[0] = stringToBytes32(asset);
        publicInputs[1] = stringToBytes32(liquidity);
        publicInputs[2] = stringToBytes32(timestamp);
        publicInputs[3] = stringToBytes32(leaf);

        depositVerifier.verify(proofBytes, publicInputs);
    }

    function test_deposit_proof_vault() public {
        // private inputs
        string memory secret = vm.readLine("./data/deposit_secret.txt");
        string memory nullifier = vm.readLine("./data/deposit_nullifier.txt");

        // public inputs
        string memory asset = vm.readLine("./data/deposit_input_0.txt");
        string memory liquidityStr = vm.readLine("./data/deposit_input_1.txt");
        string memory timestamp = vm.readLine("./data/deposit_input_2.txt");
        string memory leaf = vm.readLine("./data/deposit_input_3.txt");

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

        vault.deposit{value: liquidity}(proofBytes, publicInputs);

        uint256 vaultBalance = address(vault).balance;
        assert(vaultBalance == liquidity);
    }
}
