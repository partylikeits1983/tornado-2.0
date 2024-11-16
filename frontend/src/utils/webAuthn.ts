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
const vaultAddress = '0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9';

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

/* export const generateWallet = async (
    signature: string,
): Promise<ethers.HDNodeWallet> => {
    const signatureBuffer = Buffer.from(signature, 'base64');
    const signatureHex = '0x' + signatureBuffer.toString('hex');
    const hashedSignature = ethers.keccak256(signatureHex);

    const mnemonic = ethers.Mnemonic.entropyToPhrase(hashedSignature);

    const wallet = ethers.Wallet.fromPhrase(mnemonic);

    if (!wallet.mnemonic) {
        throw new Error('Failed to generate a mnemonic.');
    }

    const mnemonicPhrase = wallet.mnemonic.phrase;
    const deterministicWallet = ethers.Wallet.fromPhrase(mnemonicPhrase);

    return deterministicWallet;
};
 */

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
        const secretBytes = randomBytes(32);
        const nullifierBytes = randomBytes(32);

        // Convert bytes to BigInt
        const secret = ethers.toBigInt(secretBytes);
        const nullifier = ethers.toBigInt(nullifierBytes);

        // Asset is 0 (assuming ETH)
        const asset = 0;

        // Convert liquidity amount to Wei (BigInt)
        const liquidity = parseEther(liquidity_amount);

        // Current timestamp as BigInt
        const depositTimestamp = BigInt(Math.floor(Date.now() / 1000));

        const ethersProvider = new BrowserProvider(walletProvider);
        const signer = await ethersProvider.getSigner();

        const vault = new ethers.Contract(vaultAddress, VAULT_ABI, signer);

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
