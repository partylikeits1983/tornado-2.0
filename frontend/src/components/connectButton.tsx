import { useWeb3Modal } from '@web3modal/ethers/react';
import {
  createWeb3Modal,
  defaultConfig,
  useWeb3ModalAccount,
} from '@web3modal/ethers/react';

import {
  ChakraProvider,
  Container,
  Input,
  Button,
  Text,
  VStack,
  HStack, // Import HStack for horizontal alignment
} from '@chakra-ui/react';

// 1. Get projectId
const projectId = 'f970a14188f89386a9e004373a6da588';

// 2. Set chains
const localhost = {
  chainId: 31337,
  name: 'Localhost',
  currency: 'ETH',
  explorerUrl: 'https://etherscan.io',
  rpcUrl: 'http://127.0.0.1:8545',
};

const mainnet = {
  chainId: 1,
  name: 'Ethereum',
  currency: 'ETH',
  explorerUrl: 'https://etherscan.io',
  rpcUrl: 'https://eth.llamarpc.com	',
};

type ChainConfig = {
  chainId: number;
  name: string;
  currency: string;
  explorerUrl: string;
  rpcUrl: string;
};

// Define your chain configurations in a single array
const chains: ChainConfig[] = [
  {
    chainId: 31337,
    name: 'Localhost',
    currency: 'ETH',
    explorerUrl: 'https://etherscan.io',
    rpcUrl: 'http://127.0.0.1:8545',
  },
  {
    chainId: 1,
    name: 'Ethereum',
    currency: 'ETH',
    explorerUrl: 'https://etherscan.io',
    rpcUrl: 'https://eth.llamarpc.com',
  },
];

// 3. Create a metadata object
const metadata = {
  name: 'My Website',
  description: 'My Website description',
  url: 'https://mywebsite.com', // origin must match your domain & subdomain
  icons: ['https://avatars.mywebsite.com/'],
};

// 4. Create Ethers config
const ethersConfig = defaultConfig({
  /*Required*/
  metadata,

  /*Optional*/
  enableEIP6963: true, // true by default
  enableInjected: true, // true by default
  enableCoinbase: true, // true by default
  rpcUrl: '...', // used for the Coinbase SDK
  defaultChainId: 1, // used for the Coinbase SDK
});

// 5. Create a Web3Modal instance
createWeb3Modal({
  ethersConfig,
  chains: chains,
  projectId,
  enableAnalytics: true, // Optional - defaults to your Cloud configuration
});

const ConnectButton: React.FC = () => {
  const { address, isConnected, chainId } = useWeb3ModalAccount();
  const { open } = useWeb3Modal();

  // Function to shorten the displayed address
  const shortenAddress = (address: `0x${string}`): string =>
    `${address.slice(0, 5)}...${address.slice(-4)}`;

  // Function to get the name of the chain by its chainId
  const getChainName = (chainId: number | undefined): string => {
    const chain = chains.find((chain) => chain.chainId === chainId);
    return chain ? chain.name : 'Switch Network'; // Default to 'Switch Network' if chain not found or chainId is undefined
  };

  return (
    <HStack spacing={4}>
      <Button onClick={() => open()} colorScheme="gray">
        {isConnected && address ? shortenAddress(address) : 'Connect Wallet'}
      </Button>
      <Button onClick={() => open({ view: 'Networks' })} colorScheme="gray">
        {isConnected ? getChainName(chainId) : 'Switch Network'}
      </Button>
    </HStack>
  );
};
export default ConnectButton;
