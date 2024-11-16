// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import {Vault} from "../src/Vault.sol";
import {UltraVerifier as DepositVerifier} from "../../circuits/deposit/target/contract.sol";
import {UltraVerifier as WithdrawVerifier} from "../../circuits/withdraw/target/contract.sol";

contract Vault_Deploy is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // Deploy verifiers
        DepositVerifier depositVerifier = new DepositVerifier();
        WithdrawVerifier withdrawVerifier = new WithdrawVerifier();

        // Set the maximum gas price for the next transaction (Vault deployment)
        uint256 maxGasPrice = 1e18; // Adjust this value as needed
        vm.txGasPrice(maxGasPrice);

        // Deploy the Vault contract with the specified gas price
        Vault vault = new Vault(address(depositVerifier), address(withdrawVerifier));

        console.log("Vault deployed at:", address(vault));
        console.log("DepositVerifier deployed at:", address(depositVerifier));
        console.log("WithdrawVerifier deployed at:", address(withdrawVerifier));

        vm.stopBroadcast();
    }
}
