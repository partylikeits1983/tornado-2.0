pragma solidity ^0.8.0;

contract ConvertBytes32ToString {
    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        // Create a buffer of 64 bytes (2 characters per byte)
        bytes memory bytesArray = new bytes(64);
        for (uint256 i = 0; i < 32; i++) {
            // Convert each byte to uint8 to perform arithmetic operations
            uint8 byteValue = uint8(_bytes32[i]);
            // Determine the hexadecimal character for the high nibble
            bytesArray[i * 2] = byteToHexChar(byteValue / 16);
            // Determine the hexadecimal character for the low nibble
            bytesArray[1 + i * 2] = byteToHexChar(byteValue % 16);
        }
        // Prefix with "0x" and return the resulting string
        return string(abi.encodePacked("0x", string(bytesArray)));
    }

    function byteToHexChar(uint8 b) internal pure returns (bytes1) {
        // If byte is less than 10, return corresponding ASCII character for digits
        if (b < 10) {
            return bytes1(b + 48); // ASCII '0' = 48
        }
        // Otherwise, return ASCII character for a-f by adjusting with ASCII 'a' = 97 minus 10
        return bytes1(b + 87); // ASCII 'a' - 10 = 87
    }

    function fromHexChar(uint8 c) internal pure returns (uint8) {
        if (c >= uint8(bytes1("0")) && c <= uint8(bytes1("9"))) {
            return c - uint8(bytes1("0"));
        } else if (c >= uint8(bytes1("a")) && c <= uint8(bytes1("f"))) {
            return 10 + c - uint8(bytes1("a"));
        } else if (c >= uint8(bytes1("A")) && c <= uint8(bytes1("F"))) {
            return 10 + c - uint8(bytes1("A"));
        } else {
            revert("Invalid hex character");
        }
    }

    function hexStringToBytes(string memory hexString) internal pure returns (bytes memory) {
        bytes memory strBytes = bytes(hexString);

        // Check that the string has "0x" prefix and then hex pairs
        require(strBytes.length >= 2, "Hex string must have at least 2 characters for '0x'");
        require(strBytes[0] == "0" && (strBytes[1] == "x" || strBytes[1] == "X"), "Hex string must start with '0x'");

        uint256 hexLength = strBytes.length - 2; // Exclude "0x"
        require(hexLength % 2 == 0, "Hex string length must be even");

        bytes memory result = new bytes(hexLength / 2);
        for (uint256 i = 0; i < hexLength; i += 2) {
            uint8 high = fromHexChar(uint8(strBytes[2 + i])) << 4;
            uint8 low = fromHexChar(uint8(strBytes[3 + i]));
            result[i / 2] = bytes1(high | low);
        }
        return result;
    }

    function stringToBytes32(string memory hexString) public pure returns (bytes32) {
        bytes memory bytesArray = hexStringToBytes(hexString);
        require(bytesArray.length == 32, "Hex string must represent 32 bytes");

        bytes32 result;
        assembly {
            result := mload(add(bytesArray, 32))
        }
        return result;
    }

    function stringToUint(string memory _numStr) public pure returns (uint256) {
        bytes memory b = bytes(_numStr);
        uint256 result = 0;
        for (uint256 i = 0; i < b.length; i++) {
            uint8 digit = uint8(b[i]) - 48; // ASCII '0' is 48
            require(digit >= 0 && digit <= 9, "Invalid character in string");
            result = result * 10 + digit;
        }
        return result;
    }

    /**
     * @dev Finds the index of the first occurrence of `needle` in `haystack` starting from `start`.
     * Returns `type(uint256).max` if not found.
     */
    function findSubstring(bytes memory haystack, bytes memory needle, uint256 start) internal pure returns (uint256) {
        if (needle.length == 0) return 0;
        for (uint256 i = start; i <= haystack.length - needle.length; i++) {
            bool found = true;
            for (uint256 j = 0; j < needle.length; j++) {
                if (haystack[i + j] != needle[j]) {
                    found = false;
                    break;
                }
            }
            if (found) return i;
        }
        return type(uint256).max;
    }
}
