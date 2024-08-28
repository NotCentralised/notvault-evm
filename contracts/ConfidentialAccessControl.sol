/* 
 SPDX-License-Identifier: MIT
 Access Control Contract for Solidity v0.9.969 (ConfidentialAccessControl.sol)

  _   _       _    _____           _             _ _              _ 
 | \ | |     | |  / ____|         | |           | (_)            | |
 |  \| | ___ | |_| |     ___ _ __ | |_ _ __ __ _| |_ ___  ___  __| |
 | . ` |/ _ \| __| |    / _ \ '_ \| __| '__/ _` | | / __|/ _ \/ _` |
 | |\  | (_) | |_| |___|  __/ | | | |_| | | (_| | | \__ \  __/ (_| |
 |_| \_|\___/ \__|\_____\___|_| |_|\__|_|  \__,_|_|_|___/\___|\__,_|
                                                                    
                                                                    
 Author: @NumbersDeFi 
*/

pragma solidity ^0.8.9;

import "./ConfidentialVault.sol";

contract ConfidentialAccessControl {

    address private owner;
    address private policyVerifier;
    constructor(address _policyVerifier) { owner = msg.sender; policyVerifier = _policyVerifier;}

    /* 
        Execute a contract function by a relay wallet on behalf of a user wallet.
        The user wallet signs the transaction off-chain, sends it to the relay wallet and the relay wallets transmits the transaction to the blockchain paying the gas fees.
        The smart contract verifies that the signed functioncal is signed by the user wallet.
    */
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
            if (!success) {
                if (result.length > 0) {
                    assembly {
                        let returndata_size := mload(result)
                        revert(add(32, result), returndata_size)
                    }
                } else {
                    revert("Function call not successful and no error message returned");
                }
            }

            return result;
    }

    /*
        Extract the signer from a signed message.
    */
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

    /*
        Add the treasurer of a given ERC20 address denomination.
    */
    function addTreasurer(address caller, address denomination) public {
        require(owner == msg.sender, "Only the owner can set a treasurer");
        treasurers[denomination] = caller;
    }

    /*
        Check if an address is the treasurer of a given ERC20 address denomination.
    */
    function isTreasurer(address caller, address denomination) public view returns (bool) {
        return treasurers[denomination] == caller;
    }
}
