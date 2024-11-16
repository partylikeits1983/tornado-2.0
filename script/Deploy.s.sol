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

        // deploy verifiers
        DepositVerifier depositVerifier = new DepositVerifier();
        WithdrawVerifier withdrawVerifier = new WithdrawVerifier();

        Vault vault = new Vault(address(depositVerifier), address(withdrawVerifier));

        console.log(address(vault));

        vm.stopBroadcast();
    }
}
