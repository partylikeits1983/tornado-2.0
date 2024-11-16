import React, { useState, useEffect } from 'react';
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
  ButtonGroup,
} from '@chakra-ui/react';
import {
  generateLeaf,
  submitProof,
  getContractBalance,
  parseDepositProof,
  parseWithdrawProof,
  submitWithdrawProof,
} from '../utils/webAuthn';
import { ToastContainer, toast } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';

interface MainFormProps {
  walletProvider?: any;
}

// Represent deposit values as strings
const depositValues = ['0.1', '0.5', '1', '10', '100'];

const MainForm: React.FC<MainFormProps> = ({ walletProvider }) => {
  const [actionType, setActionType] = useState<'deposit' | 'withdraw'>('deposit');
  const [selectedIndex, setSelectedIndex] = useState<number>(0);
  const selectedValue = depositValues[selectedIndex];
  const [proverTomlContent, setProverTomlContent] = useState<string>('');

  // State variables for deposit
  const [depositProofFile, setDepositProofFile] = useState<File | null>(null);
  const [depositPublicInputs, setDepositPublicInputs] = useState<string[]>([]);
  const [depositProofBytes, setDepositProofBytes] = useState<string>('');

  // State variables for withdraw
  const [withdrawProofFile, setWithdrawProofFile] = useState<File | null>(null);
  const [withdrawPublicInputs, setWithdrawPublicInputs] = useState<string[]>([]);
  const [withdrawProofBytes, setWithdrawProofBytes] = useState<string>('');

  const [contractBalance, setContractBalance] = useState<string>('0');

  // Countdown timer state
  const [timeLeft, setTimeLeft] = useState<number>(0);

  useEffect(() => {
    if (walletProvider) {
      fetchContractBalance();
    }
  }, [walletProvider]);

  const fetchContractBalance = async () => {
    const balance = await getContractBalance(walletProvider);
    setContractBalance(balance);
  };

  const handleGenerateLeaf = async () => {
    const tomlContent = await generateLeaf(walletProvider, selectedValue);
    setProverTomlContent(tomlContent);
    setTimeLeft(60); // Start countdown from 60 seconds
  };

  // Countdown timer logic
  useEffect(() => {
    let timer: NodeJS.Timeout;
    if (timeLeft > 0) {
      timer = setTimeout(() => {
        setTimeLeft((prevTimeLeft) => prevTimeLeft - 1);
      }, 1000);
    } else if (timeLeft === 0 && proverTomlContent) {
      // Time is up
      toast.error('Time is up! Please generate a new proof.');
      // Optionally reset the state related to proof submission
      setProverTomlContent('');
      setDepositProofFile(null);
      setDepositPublicInputs([]);
      setDepositProofBytes('');
    }
    return () => clearTimeout(timer);
  }, [timeLeft, proverTomlContent]);

  const handleSubmitDepositProof = async () => {
    if (timeLeft <= 0) {
      alert('Time has expired. Please generate a new proof.');
      return;
    }
    if (!walletProvider) {
      alert('Wallet provider not available.');
      return;
    }
    if (!depositProofBytes || depositPublicInputs.length === 0) {
      alert('Proof data is missing.');
      return;
    }

    try {
      await submitProof(
        walletProvider,
        depositProofBytes,
        depositPublicInputs,
        selectedValue,
      );
      toast.success('Deposit successful');
      fetchContractBalance(); // Refresh contract balance
      // Reset timer and state
      setTimeLeft(0);
      setProverTomlContent('');
      setDepositProofFile(null);
      setDepositPublicInputs([]);
      setDepositProofBytes('');
    } catch (error: any) {
      console.error(error);
      alert('Error submitting proof: ' + error.message);
    }
  };

  const handleSubmitWithdrawProof = async () => {
    if (!walletProvider) {
      alert('Wallet provider not available.');
      return;
    }
    if (!withdrawProofBytes || withdrawPublicInputs.length === 0) {
      alert('Withdraw proof data is missing.');
      return;
    }

    try {
      await submitWithdrawProof(
        walletProvider,
        withdrawProofBytes,
        withdrawPublicInputs,
      );

      toast.success('Withdrawal successful');
      fetchContractBalance(); // Refresh contract balance
    } catch (error: any) {
      console.error(error);
      alert('Error submitting withdraw proof: ' + error.message);
    }
  };

  // Function to handle deposit proof file selection
  const handleDepositProofFileChange = (
    event: React.ChangeEvent<HTMLInputElement>,
  ) => {
    const file = event.target.files?.[0];
    if (file) {
      setDepositProofFile(file);
    }
  };

  // Function to handle withdraw proof file selection
  const handleWithdrawProofFileChange = (
    event: React.ChangeEvent<HTMLInputElement>,
  ) => {
    const file = event.target.files?.[0];
    if (file) {
      setWithdrawProofFile(file);
    }
  };

  // Function to parse deposit proof file using parseDepositProof
  const handleParseDepositProofFile = async () => {
    if (!depositProofFile) {
      alert('Please select a deposit proof file.');
      return;
    }

    try {
      const { publicInputs, proofBytes } = await parseDepositProof(depositProofFile);
      setDepositPublicInputs(publicInputs);
      setDepositProofBytes(proofBytes);
    } catch (error: any) {
      alert('Error parsing deposit proof file: ' + error.message);
    }
  };

  // Function to parse withdraw proof file using parseWithdrawProof
  const handleParseWithdrawProofFile = async () => {
    if (!withdrawProofFile) {
      alert('Please select a withdraw proof file.');
      return;
    }

    try {
      const { publicInputs, proofBytes } = await parseWithdrawProof(withdrawProofFile);
      setWithdrawPublicInputs(publicInputs);
      setWithdrawProofBytes(proofBytes);
    } catch (error: any) {
      alert('Error parsing withdraw proof file: ' + error.message);
    }
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
      <ButtonGroup isAttached variant="outline" mb={4}>
        <Button
          isActive={actionType === 'deposit'}
          onClick={() => setActionType('deposit')}
        >
          Deposit
        </Button>
        <Button
          isActive={actionType === 'withdraw'}
          onClick={() => setActionType('withdraw')}
        >
          Withdraw
        </Button>
      </ButtonGroup>
      {actionType === 'deposit' ? (
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
              {/* Display countdown timer */}
              {timeLeft > 0 && (
                <Text color="red.500" fontSize="lg" mt={4}>
                  Time left to submit proof: {timeLeft} seconds
                </Text>
              )}
            </>
          )}
          {/* File input for deposit proof file */}
          <Input
            type="file"
            accept=".proof,.txt" // Adjust as needed
            onChange={handleDepositProofFileChange}
            mt={4}
          />
          {depositProofFile && (
            <Button colorScheme="green" onClick={handleParseDepositProofFile}>
              Parse Deposit Proof File
            </Button>
          )}
          {/* Display parsed public inputs and proof for deposit */}
          {depositPublicInputs.length > 0 && (
            <>
              <Text color="white" fontSize="lg" mt={4}>
                Public Inputs:
              </Text>
              <Textarea
                value={depositPublicInputs
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
                value={depositProofBytes}
                readOnly
                color="white"
                bg="gray.800"
                fontFamily="monospace"
                height="200px"
              />
              <Button
                colorScheme="purple"
                onClick={handleSubmitDepositProof}
                mt={4}
                isDisabled={timeLeft <= 0} // Disable if time is up
              >
                Deposit ETH
              </Button>
            </>
          )}
        </>
      ) : (
        <>
          {/* Withdraw UI */}
          <Text color="white" fontSize="lg">
            Withdraw ETH
          </Text>
          {/* File input for withdraw proof file */}
          <Input
            type="file"
            accept=".proof,.txt" // Adjust as needed
            onChange={handleWithdrawProofFileChange}
            mt={4}
          />
          {withdrawProofFile && (
            <Button colorScheme="green" onClick={handleParseWithdrawProofFile}>
              Parse Withdraw Proof File
            </Button>
          )}
          {/* Display parsed public inputs and proof for withdraw */}
          {withdrawPublicInputs.length > 0 && (
            <>
              <Text color="white" fontSize="lg" mt={4}>
                Public Inputs:
              </Text>
              <Textarea
                value={withdrawPublicInputs
                  .map((input, idx) => {
                    let label = '';
                    switch (idx) {
                      case 0:
                        label = 'Recipient';
                        break;
                      case 1:
                        label = 'Current Timestamp';
                        break;
                      case 2:
                        label = 'Asset';
                        break;
                      case 3:
                        label = 'Liquidity';
                        break;
                      case 4:
                        label = 'Root';
                        break;
                      case 5:
                        label = 'Nullifier Hash';
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
                value={withdrawProofBytes}
                readOnly
                color="white"
                bg="gray.800"
                fontFamily="monospace"
                height="200px"
              />
              <Button
                colorScheme="purple"
                onClick={handleSubmitWithdrawProof}
                mt={4}
              >
                Withdraw ETH
              </Button>
            </>
          )}
        </>
      )}
      {/* Display contract balance discretely */}
      <Text color="white" fontSize="sm" mt={4}>
        Contract Balance: {contractBalance} ETH
      </Text>
    </VStack>
  );
};

export default MainForm;
