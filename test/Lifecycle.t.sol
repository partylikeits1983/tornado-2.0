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
        assert(
            address(uint160(uint256(stringToBytes32(withdraw_recipient)))).balance
                == uint256(stringToBytes32(withdraw_liquidity))
        );
    }
}
