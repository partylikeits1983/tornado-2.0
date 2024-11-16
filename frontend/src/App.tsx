import React, { useState, useEffect } from 'react';
import './App.css';
import { useWeb3ModalProvider } from '@web3modal/ethers/react';

import ConnectButton from './components/connectButton';
import MainForm from './components/mainForm';

import { ChakraProvider, Box, Flex } from '@chakra-ui/react';

const App: React.FC = () => {
  const { walletProvider } = useWeb3ModalProvider();

  const [username, setUsername] = useState<string>('');
  const [isAuthenticated, setIsAuthenticated] = React.useState(false);
  const [isRoaming, setIsRoaming] = useState<boolean>(false);

  return (
    <ChakraProvider>
      <Flex direction="column" minHeight="100vh" bg="gray.900">
        <Flex
          position="absolute"
          top="1rem"
          right="1rem"
          px={{ base: 2, md: 4 }}
        >
          <ConnectButton />
        </Flex>

        <Flex
          flex={1}
          direction="column"
          align="center"
          justify="center"
          px={{ base: 4, md: 8 }}
        >
          <Box
            p={{ base: 4, md: 8 }}
            mb={4}
            borderRadius="lg"
            boxShadow="lg"
            bg="gray.700"
            w={{ base: '90%', sm: '80%', md: 'lg' }}
          >
            <MainForm
              walletProvider={walletProvider}
            />
          </Box>
        </Flex>
      </Flex>
    </ChakraProvider>
  );
};

export default App;
