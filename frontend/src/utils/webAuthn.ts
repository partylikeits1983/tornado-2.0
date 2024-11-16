// webauthn.ts
import { toast } from 'react-toastify';

import { client, parsers } from '@passwordless-id/webauthn';
import { poseidon2 } from 'poseidon-lite/poseidon2';
import {
    ethers,
    BrowserProvider,
    randomBytes,
    parseEther,
    getBytes,
} from 'ethers';
import { toBeHex } from 'ethers';

const VAULT_ABI = require('../abi/Vault.json').abi;
const vaultAddress = '0xe1Aa25618fA0c7A1CFDab5d6B456af611873b629';

interface AlertFunction {
    (message: string): void;
}

export const authenticateUser = async (username: string) => {
    const credentialId = window.localStorage.getItem(username);
    if (!credentialId) {
        toast.success('User not registered'); // Using toast for success message

        return;
    }

    console.log('Initiating WebAuthn authentication process...');

    try {
        const res = await client.authenticate(
            credentialId ? [credentialId] : [],
            window.crypto.randomUUID(),
            {
                authenticatorType: 'auto',
            },
        );
        console.debug(res);
        return true;
    } catch (error) {
        console.log(error);
        return false;
    }
};

function dedent(strings: TemplateStringsArray, ...values: any[]) {
    // Combine the strings and values into a single string
    let fullString = strings.reduce(
        (acc, str, i) => acc + str + (values[i] || ''),
        '',
    );

    // Split the string into lines
    const lines = fullString.split('\n');

    // Remove any leading/trailing blank lines
    while (lines.length && lines[0].trim() === '') lines.shift();
    while (lines.length && lines[lines.length - 1].trim() === '') lines.pop();

    // Find the minimum indentation (ignoring empty lines)
    const indentLengths = lines
        .filter((line) => line.trim())
        .map((line) => {
            const match = line.match(/^(\s*)/);
            const indent = match ? match[1].length : 0;
            return indent;
        });

    const minIndent = Math.min(...indentLengths);

    // Remove the minimum indentation from each line
    const dedentedLines = lines.map((line) =>
        line.length >= minIndent ? line.slice(minIndent) : line,
    );

    // Return the dedented string
    return dedentedLines.join('\n');
}

export const generateLeaf = async (
    walletProvider: any,
    liquidity_amount: string,
): Promise<string> => {
    try {
        console.log('HERE');

        // Generate random secret and nullifier
        const secretBytes = randomBytes(8);
        const nullifierBytes = randomBytes(8);

        // Convert bytes to BigInt
        const secret = ethers.toBigInt(secretBytes);
        const nullifier = ethers.toBigInt(nullifierBytes);

        // Asset is 0 (assuming ETH)
        const asset = 0;

        // Convert liquidity amount to Wei (BigInt)
        const liquidity = parseEther(liquidity_amount);

        // Current timestamp as BigInt
        const depositTimestamp = BigInt(Math.floor(Date.now() / 1000) + 60); // plus 1 minute into the future

        const ethersProvider = new BrowserProvider(walletProvider);
        const signer = await ethersProvider.getSigner();

        const code = await ethersProvider.getCode(vaultAddress);
        if (code === '0x') {
            throw new Error(`Contract not found at address: ${vaultAddress}`);
        }

        const vault = new ethers.Contract(vaultAddress, VAULT_ABI, signer);
        console.log('HERE bf data');
        console.log(secret, nullifier, asset, liquidity, depositTimestamp);

        // Call generateLeaf function on the contract
        const leafData = await vault.generateLeaf(
            secret,
            nullifier,
            asset,
            liquidity,
            depositTimestamp,
        );

        console.log('Leaf Data:', leafData);

        // Convert leafData to hex uint256 format
        const leafHex = toBeHex(leafData, 32);

        // Create Prover.toml content using dedent to remove indentation
        const proverTomlContent = dedent`
      secret = "${secret.toString()}"
      nullifier = "${nullifier.toString()}"
      asset = "${asset.toString()}"
      liquidity = "${liquidity.toString()}"
      timestamp = "${depositTimestamp.toString()}"
      leaf = "${leafHex}"
      `;

        // Return the content
        return proverTomlContent;
    } catch (error) {
        console.error('Error generating leaf:', error);
        return 'Error generating Prover.toml content.';
    }
};

export const getContractBalance = async (
    walletProvider: any,
): Promise<string> => {
    try {
        const ethersProvider = new BrowserProvider(walletProvider);
        const balance = await ethersProvider.getBalance(vaultAddress);
        const balanceInEther = ethers.formatEther(balance);
        return balanceInEther;
    } catch (error) {
        console.error('Error fetching contract balance', error);
        return '0';
    }
};

// webAuthn.ts
export const submitProof = async (
    walletProvider: any,
    proofBytes: string,
    publicInputs: string[],
    ethAmount: string,
) => {
    if (!walletProvider) {
        throw new Error('Wallet provider not available.');
    }

    console.log('submit proof');
    const { ethers } = require('ethers');

    const ethersProvider = new BrowserProvider(walletProvider);
    const signer = await ethersProvider.getSigner();

    // Replace with your contract's ABI and address
    const contract = new ethers.Contract(vaultAddress, VAULT_ABI, signer);

    // Convert proofBytes and publicInputs to the required format
    const proofBytesArray = proofBytes;
    const publicInputsBytes32 = publicInputs.map((input) =>
        ethers.zeroPadValue(input, 32),
    );

    console.log('HERE submit proof');
    console.log(proofBytesArray, publicInputsBytes32);

    try {
        const tx = await contract.deposit(
            proofBytesArray,
            publicInputsBytes32,
            {
                value: parseEther(ethAmount), // Include the ETH amount here
            },
        );
        await tx.wait();
        alert('Proof submitted successfully.');
    } catch (error: any) {
        console.error(error);
        alert('Error submitting proof: ' + error.message);
    }
};

export const parseDepositProof = async (proofFile: File) => {
    const fileBuffer = await proofFile.arrayBuffer();
    const proofData = new Uint8Array(fileBuffer);

    const numPublicInputs = 4; // Adjust as needed
    const publicInputBytes = 32 * numPublicInputs;

    if (proofData.length < publicInputBytes) {
        throw new Error(
            'Proof file is smaller than expected public input size.',
        );
    }

    // Extract public inputs
    const publicInputsBytes = proofData.slice(0, publicInputBytes);
    const publicInputsArray: string[] = [];
    for (let i = 0; i < numPublicInputs; i++) {
        const start = i * 32;
        const end = start + 32;
        const chunk = publicInputsBytes.slice(start, end);
        const hexString =
            '0x' +
            Array.from(chunk)
                .map((b) => b.toString(16).padStart(2, '0'))
                .join('');
        publicInputsArray.push(hexString);
    }

    // Extract proof bytes
    const proofBytesArray = proofData.slice(publicInputBytes);
    const proofHex =
        '0x' +
        Array.from(proofBytesArray)
            .map((b) => b.toString(16).padStart(2, '0'))
            .join('');

    // Return parsed data
    return { publicInputs: publicInputsArray, proofBytes: proofHex };
};

export const parseWithdrawProof = async (proofFile: File) => {
    const fileBuffer = await proofFile.arrayBuffer();
    const proofData = new Uint8Array(fileBuffer);

    const numPublicInputs = 6; // Number of public inputs for withdraw proof
    const publicInputBytes = 32 * numPublicInputs;

    if (proofData.length < publicInputBytes) {
        throw new Error(
            'Proof file is smaller than expected public input size.',
        );
    }

    // Extract public inputs
    const publicInputsBytes = proofData.slice(0, publicInputBytes);
    const publicInputsArray: string[] = [];
    for (let i = 0; i < numPublicInputs; i++) {
        const start = i * 32;
        const end = start + 32;
        const chunk = publicInputsBytes.slice(start, end);
        const hexString =
            '0x' +
            Array.from(chunk)
                .map((b) => b.toString(16).padStart(2, '0'))
                .join('');
        publicInputsArray.push(hexString);
    }

    // Extract proof bytes
    const proofBytesArray = proofData.slice(publicInputBytes);
    const proofHex =
        '0x' +
        Array.from(proofBytesArray)
            .map((b) => b.toString(16).padStart(2, '0'))
            .join('');

    // Return parsed data
    return { publicInputs: publicInputsArray, proofBytes: proofHex };
};

export const submitWithdrawProof = async (
    walletProvider: any,
    proofBytes: string,
    publicInputs: string[],
) => {
    if (!walletProvider) {
        throw new Error('Wallet provider not available.');
    }

    console.log('submit withdraw proof');

    const ethersProvider = new ethers.BrowserProvider(walletProvider);
    const signer = await ethersProvider.getSigner();

    // Log the block.timestamp
/*     const blockNumber = await ethersProvider.getBlockNumber();
    const block = await ethersProvider.getBlock(blockNumber);
    console.log('Current block timestamp:', block?.timestamp); */

    console.log('HERE');

    // Replace with your contract's ABI and address
    const contract = new ethers.Contract(vaultAddress, VAULT_ABI, signer);

    // Convert proofBytes and publicInputs to the required format
    const proofBytesArray = proofBytes;
    const publicInputsBytes32 = publicInputs.map((input) =>
        ethers.zeroPadValue(input, 32),
    );

    console.log('HERE submit withdraw proof');
    console.log(proofBytesArray, publicInputsBytes32);

    try {
        const tx = await contract.withdraw(
            proofBytesArray,
            publicInputsBytes32,
            // No need to include value for withdrawal
        );
        await tx.wait();
        alert('Withdrawal successful.');
    } catch (error: any) {
        console.error(error);
        alert('Error submitting withdraw proof: ' + error.message);
    }
};
