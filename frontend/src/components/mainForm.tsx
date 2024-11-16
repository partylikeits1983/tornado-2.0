import React, { useState } from 'react';
import {
  Slider,
  SliderTrack,
  SliderFilledTrack,
  SliderThumb,
  Button,
  Text,
  VStack,
  Heading,
  Textarea,
  Input,
} from '@chakra-ui/react';
import { generateLeaf, submitProof } from '../utils/webAuthn';
import { ToastContainer } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';

interface MainFormProps {
  setIsAuthenticated: (isAuthenticated: boolean) => void;
  isAuthenticated: boolean;
  walletProvider?: any;
}

// Represent deposit values as strings
const depositValues = ['0.05', '0.1', '1', '10', '100'];

const MainForm: React.FC<MainFormProps> = ({
  setIsAuthenticated,
  isAuthenticated,
  walletProvider,
}) => {
  const [selectedIndex, setSelectedIndex] = useState<number>(0);
  const selectedValue = depositValues[selectedIndex]; // This will now be a string
  const [proverTomlContent, setProverTomlContent] = useState<string>('');

  // New state variables
  const [proofFile, setProofFile] = useState<File | null>(null);
  const [publicInputs, setPublicInputs] = useState<string[]>([]);
  const [proofBytes, setProofBytes] = useState<string>('');

  const handleGenerateLeaf = async () => {
    const tomlContent = await generateLeaf(
      walletProvider,
      selectedValue, // Pass as string
    );
    setProverTomlContent(tomlContent);
  };

  const handleSubmitProof = async () => {
    if (!walletProvider) {
      alert('Wallet provider not available.');
      return;
    }
    if (!proofBytes || publicInputs.length === 0) {
      alert('Proof data is missing.');
      return;
    }

    try {
      await submitProof(walletProvider, proofBytes, publicInputs, selectedValue);
    } catch (error: any) {
      console.error(error);
      alert('Error submitting proof: ' + error.message);
    }
  };

  // New function to handle file selection
  const handleProofFileChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      setProofFile(file);
    }
  };

  // New function to parse proof file
  const parseProofFile = async () => {
    if (!proofFile) {
      alert('Please select a proof file.');
      return;
    }

    const fileBuffer = await proofFile.arrayBuffer();
    const proofData = new Uint8Array(fileBuffer);

    const numPublicInputs = 4; // Adjust as needed
    const publicInputBytes = 32 * numPublicInputs;

    if (proofData.length < publicInputBytes) {
      alert('Error: Proof file is smaller than expected public input size.');
      return;
    }

    // Extract public inputs
    const publicInputsBytes = proofData.slice(0, publicInputBytes);
    const publicInputsArray: string[] = [];
    for (let i = 0; i < numPublicInputs; i++) {
      const start = i * 32;
      const end = start + 32;
      const chunk = publicInputsBytes.slice(start, end);
      const hexString = '0x' + Array.from(chunk)
        .map((b) => b.toString(16).padStart(2, '0'))
        .join('');
      publicInputsArray.push(hexString);
    }

    // Extract proof bytes
    const proofBytesArray = proofData.slice(publicInputBytes);
    const proofHex = '0x' + Array.from(proofBytesArray)
      .map((b) => b.toString(16).padStart(2, '0'))
      .join('');

    // Update state
    setPublicInputs(publicInputsArray);
    setProofBytes(proofHex);
  };



  return (
    <VStack spacing={4} width="100%" maxW="600px" mx="auto">
      <ToastContainer
        position="top-right"
        autoClose={5000}
        hideProgressBar={false}
        newestOnTop={false}
        closeOnClick
        rtl={false}
        pauseOnFocusLoss
        draggable
        pauseOnHover
        theme="light"
      />
      <Heading size="lg" color="white">
        Tornado Cash 2.0
      </Heading>
      {!isAuthenticated ? (
        <>
          <Text color="white" fontSize="lg">
            Select Amount of ETH to Deposit: {selectedValue} ETH
          </Text>
          <Slider
            aria-label="deposit-amount-slider"
            defaultValue={0}
            min={0}
            max={depositValues.length - 1}
            step={1}
            onChange={(val) => setSelectedIndex(val)}
          >
            <SliderTrack>
              <SliderFilledTrack />
            </SliderTrack>
            <SliderThumb />
          </Slider>
          <Button colorScheme="blue" onClick={handleGenerateLeaf}>
            Generate Deposit Prover.toml
          </Button>
          {proverTomlContent && (
            <>
              <Text color="white" fontSize="lg" mt={4}>
                Prover.toml Content:
              </Text>
              <Textarea
                value={proverTomlContent}
                readOnly
                color="white"
                bg="gray.800"
                fontFamily="monospace"
                height="200px"
              />
              <Button
                colorScheme="teal"
                onClick={() => navigator.clipboard.writeText(proverTomlContent)}
              >
                Copy to Clipboard
              </Button>
            </>
          )}
          {/* New file input for proof file */}
          <Input
            type="file"
            accept=".proof,.txt" // Adjust as needed
            onChange={handleProofFileChange}
            mt={4}
          />
          {proofFile && (
            <Button colorScheme="green" onClick={parseProofFile}>
              Parse Proof File
            </Button>
          )}
          {/* Display parsed public inputs and proof */}
          {publicInputs.length > 0 && (
  <>
    <Text color="white" fontSize="lg" mt={4}>
      Public Inputs:
    </Text>
    <Textarea
      value={publicInputs
        .map((input, idx) => {
          let label = '';
          switch (idx) {
            case 0:
              label = 'Asset';
              break;
            case 1:
              label = 'Liquidity';
              break;
            case 2:
              label = 'Timestamp';
              break;
            case 3:
              label = 'Leaf';
              break;
            default:
              label = `Input ${idx}`;
          }
          return `${label}: ${input}`;
        })
        .join('\n')}
      readOnly
      color="white"
      bg="gray.800"
      fontFamily="monospace"
      height="200px"
    />
    <Text color="white" fontSize="lg" mt={4}>
      Proof:
    </Text>
    <Textarea
      value={proofBytes}
      readOnly
      color="white"
      bg="gray.800"
      fontFamily="monospace"
      height="200px"
    />
    <Button colorScheme="purple" onClick={handleSubmitProof} mt={4}>
      Deposit ETH
    </Button>
  </>
)}
        </>
      ) : (
        <Text color="white">You are logged in</Text>
      )}
    </VStack>
  );
};

export default MainForm;
