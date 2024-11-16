// MainForm.tsx
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
} from '@chakra-ui/react';
import { generateLeaf } from '../utils/webAuthn';
import { ToastContainer } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';

interface MainFormProps {
  setIsAuthenticated: (isAuthenticated: boolean) => void;
  isAuthenticated: boolean;
  walletProvider?: any;
}

const depositValues = [0.05, 0.1, 1, 10, 100];

const MainForm: React.FC<MainFormProps> = ({
  setIsAuthenticated,
  isAuthenticated,
  walletProvider,
}) => {
  const [selectedIndex, setSelectedIndex] = useState<number>(0);
  const selectedValue = depositValues[selectedIndex];
  const [proverTomlContent, setProverTomlContent] = useState<string>('');

  const handleGenerateLeaf = async () => {
    const tomlContent = await generateLeaf(
      walletProvider,
      selectedValue.toString(),
    );
    setProverTomlContent(tomlContent);
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
        </>
      ) : (
        <Text color="white">You are logged in</Text>
      )}
    </VStack>
  );
};

export default MainForm;
