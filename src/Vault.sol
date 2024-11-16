// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {CryptoTools} from "./CryptoTools.sol";
import {UltraVerifier as DepositVerifier} from "../../circuits/deposit/target/contract.sol";

import {Test, console} from "forge-std/Test.sol";

contract Vault is CryptoTools {
    DepositVerifier depositVerifier;

    constructor(address _depositVerifier) CryptoTools() {
        depositVerifier = DepositVerifier(_depositVerifier);
    }

    function deposit(bytes memory proof, bytes32[] memory publicInputs) public payable returns (uint256 leafIndex) {
        // Convert the first public input to an address
        address asset = address(uint160(uint256(publicInputs[0])));
        uint256 liquidity = uint256(publicInputs[1]);
        uint256 timestamp = uint256(publicInputs[2]);
        uint256 leaf = uint256(publicInputs[3]);

        require(asset == address(0), "only ETH supported atm");
        require(msg.value == liquidity, "invalid amount");

        // Log the public inputs
        console.log("Asset address:", asset);
        console.log("Liquidity:", liquidity);
        console.log("Timestamp:", timestamp);
        console.log("Leaf:", leaf);

        // Ensure that the current block.timestamp is less than the provided timestamp
        require(block.timestamp < timestamp, "deposit timestamp >= block.timestamp");

        // Verify the proof with the given public inputs
        depositVerifier.verify(proof, publicInputs);

        // Insert the leaf into the cryptographic tree
        CryptoTools.insert(leaf);

        // Return the new leaf index
        return CryptoTools.leafCount - 1;
    }
}
