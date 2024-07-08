// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";

contract ConfidentialAccessControl {

    address private owner;
    constructor() { owner = msg.sender; }

    function executeMetaTransaction(
        address userAddress,
        address contractAddress,
        bytes memory functionSignature,
        bytes32 message,
        bytes memory signature
        ) public payable returns (bytes memory) {

            uint256 chainId;
            assembly {
                chainId := chainid()
            }

            require(userAddress == getSigner(message, signature), "Signer and signature do not match");
            require(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(functionSignature)))) == message, "function not hash");

            
            (bool success, bytes memory result) = contractAddress.call(functionSignature);
            // require(success, "Function call not successful");
            if (!success) {
                // If the call failed, result should contain the error message
                if (result.length > 0) {
                    // The easiest way to bubble the revert reason is using memory via assembly
                    assembly {
                        let returndata_size := mload(result)
                        revert(add(32, result), returndata_size)
                    }
                } else {
                    revert("Function call not successful and no error message returned");
                }
            }
    
            // emit MetaTransactionExecuted(userAddress, msg.sender, functionSignature);

            return result;
    }

    function getSigner(bytes32 _hash, bytes memory _signature) internal pure returns (address){
        bytes32 r;
        bytes32 s;
        uint8 v;
        if (_signature.length != 65) {
            return address(0);
        }
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
        if (v < 27) {
            v += 27;
        }
        if (v != 27 && v != 28) {
            return address(0);
        } else {
            return ecrecover(keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
            ), v, r, s);
        }
    }

    mapping (address => address) private treasurers;

    function addTreasurer(address caller, address denomination) public {
        require(owner == msg.sender, "Only the owner can set a treasurer");
        treasurers[denomination] = caller;
    }

    function isTreasurer(address caller, address denomination) public view returns (bool) {
        return treasurers[denomination] == caller;
    }
}
