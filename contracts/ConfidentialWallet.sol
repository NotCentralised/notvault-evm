/* 
 SPDX-License-Identifier: MIT
 Confidential Wallet for Solidity v0.5.5 (ConfidentialWallet.sol)

  _   _       _    _____           _             _ _              _ 
 | \ | |     | |  / ____|         | |           | (_)            | |
 |  \| | ___ | |_| |     ___ _ __ | |_ _ __ __ _| |_ ___  ___  __| |
 | . ` |/ _ \| __| |    / _ \ '_ \| __| '__/ _` | | / __|/ _ \/ _` |
 | |\  | (_) | |_| |___|  __/ | | | |_| | | (_| | | \__ \  __/ (_| |
 |_| \_|\___/ \__|\_____\___|_| |_|\__|_|  \__,_|_|_|___/\___|\__,_|
                                                                    
                                                                    
 Author: @NumbersDeFi 
*/

pragma solidity ^0.8.9;

import "./circuits/IReceiveVerifier.sol";
import "./circuits/ISendVerifier.sol";

contract ConfidentialWallet {
    mapping (address => string) publicKeys;
    mapping (address => string) private encryptedPrivateKeys;
    mapping (address => string) private encryptedSecrets;
    mapping (address => string) private hashedContactId;
    mapping (address => string) private encryptedContactId;
    mapping (string  => address) private hashedContactIdReverse;

    mapping (address => mapping (string => string)) private valueStore;
    mapping (address => string) private fileIndex;
    mapping (address => string) private credentialIndex;

    mapping (address => mapping (string => bool)) private credentialStatus;

    constructor() { }

    function getPublicKey(address account) public view returns (string memory) {
        return publicKeys[account];
    }

    function getEncryptedPrivateKey(address account) public view returns (string memory) {
        return encryptedPrivateKeys[account];
    }

    function getEncryptedSecret(address account) public view returns (string memory) {
        return encryptedSecrets[account];
    }

    function getAddressByContactId(string memory hashContactId) public view returns (address) {
        return hashedContactIdReverse[hashContactId];
    }

    function getEncryptedContactId(address account) public view returns (string memory) {
        return encryptedContactId[account];
    }

    function registerKeys(
            string memory publicKey, 
            string memory encryptedPrivateKey, 
            string memory encryptedSecret, 
            string memory contactId, 
            string memory encContactId
        ) public {
            address account = msg.sender;
            publicKeys[account] = publicKey;
            encryptedPrivateKeys[account] = encryptedPrivateKey;
            encryptedSecrets[account] = encryptedSecret;

            hashedContactId[account] = contactId;
            encryptedContactId[account] = encContactId;
            hashedContactIdReverse[contactId] = account;
    }

    function getFileIndex(
            address account
        ) public view returns (string memory) {
            return fileIndex[account];
    }
    
    function setFileIndex(
            string memory value
        ) public {
            address account = msg.sender;
            fileIndex[account] = value;
    }

    function getCredentialIndex(
            address account
        ) public view returns (string memory) {
            return credentialIndex[account];
    }
    
    function setCredentialIndex(
            string memory value
        ) public {
            address account = msg.sender;
            credentialIndex[account] = value;
    }

    function getValue(
            address account, 
            string memory key
        ) public view returns (string memory) {
            return valueStore[account][key];
    }
    
    function setValue(
            string memory key, 
            string memory value
        ) public {
            address account = msg.sender;
            valueStore[account][key] = value;
    }

    function getCredentialStatus(
            address account,
            string memory id
        ) public view returns (bool) {
            return credentialStatus[account][id];
    }
    
    function setCredentialStatus(
            string memory id, 
            bool status
        ) public {
            address account = msg.sender;
            credentialStatus[account][id] = status;
    }
}