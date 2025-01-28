/* 
 SPDX-License-Identifier: MIT
 Confidential Wallet for Solidity v0.9.10069 (ConfidentialWallet.sol)

  _   _       _    _____           _             _ _              _ 
 | \ | |     | |  / ____|         | |           | (_)            | |
 |  \| | ___ | |_| |     ___ _ __ | |_ _ __ __ _| |_ ___  ___  __| |
 | . ` |/ _ \| __| |    / _ \ '_ \| __| '__/ _` | | / __|/ _ \/ _` |
 | |\  | (_) | |_| |___|  __/ | | | |_| | | (_| | | \__ \  __/ (_| |
 |_| \_|\___/ \__|\_____\___|_| |_|\__|_|  \__,_|_|_|___/\___|\__,_|
                                                                    
                                                                    
 Author: @NumbersDeFi 
*/

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./circuits/IReceiveVerifier.sol";
import "./circuits/ISendVerifier.sol";
import "./ConfidentialVault.sol";

contract ConfidentialWallet is ReentrancyGuard {
    mapping (address => string)                     publicKeys;
    mapping (address => string)                     private encryptedPrivateKeys;
    mapping (address => string)                     private encryptedSecrets;
    mapping (address => string)                     private hashedContactId;
    mapping (address => string)                     private encryptedContactId;
    mapping (string  => address)                    private hashedContactIdReverse;

    mapping (address => mapping (string => string)) private valueStore;
    mapping (address => string)                     private fileIndex;
    mapping (address => string)                     private credentialIndex;

    mapping (address => mapping (string => bool))   private credentialStatus;

    mapping (address => mapping (address => mapping (uint256 => mapping (address => mapping (address => string))))) private privateBalances;
    mapping (address => mapping (address => mapping (address => mapping (uint256 => string)))) private privateAmounts;

    address private accessControl;

    constructor(address _accessControl) { accessControl = _accessControl; }

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
    ) public nonReentrant {
        address account = msg.sender;
        publicKeys[account] = publicKey;
        encryptedPrivateKeys[account] = encryptedPrivateKey;
        encryptedSecrets[account] = encryptedSecret;

        hashedContactId[account] = contactId;
        encryptedContactId[account] = encContactId;
        hashedContactIdReverse[contactId] = account;
    }

    function getFileIndex(
        address         account
    ) public view returns (string memory) {
        return fileIndex[account];
    }

    function setFileIndexMeta(
        address         caller,
        string memory   value
    ) public nonReentrant {
        address sender = msg.sender == accessControl ? caller : msg.sender;
        fileIndex[sender] = value;
    }

    function getCredentialIndex(
        address account
    ) public view returns (string memory) {
        return credentialIndex[account];
    }
    
    function setCredentialIndexMeta(
        address         caller,
        string memory   value
    ) public nonReentrant {
        address sender = msg.sender == accessControl ? caller : msg.sender;
        credentialIndex[sender] = value;
    }

    function getValue(
        address         account, 
        string memory   key
    ) public view returns (string memory) {
        return valueStore[account][key];
    }
    
    function setValueMeta(
        address         caller,
        string memory   key, 
        string memory   value
    ) public nonReentrant {
        address sender = msg.sender == accessControl ? caller : msg.sender;
        valueStore[sender][key] = value;
    }

    function getCredentialStatus(
        address         account,
        string memory   id
    ) public view returns (bool) {
        return credentialStatus[account][id];
    }
    
    function setCredentialStatusMeta(
        address         caller,
        string memory   id, 
        bool            status
    ) public nonReentrant {
        address sender = msg.sender == accessControl ? caller : msg.sender;
        credentialStatus[sender][id] = status;
    }

    function privateBalanceOf(
        address vault,
        address account,
        uint256 group_id,
        address denomination,
        address obligor
    ) 
    public 
    view 
    returns (
        string memory
    ){  
        return privateBalances[vault][account][group_id][denomination][obligor]; 
    }

    function setPrivateBalanceMeta(
        address         caller,
        address         vault,
        uint256         group_id,
        address         denomination,
        address         obligor,
        string memory   value
    ) 
    public nonReentrant
    {  
        address sender = msg.sender == accessControl ? caller : msg.sender;
        
        privateBalances[vault][sender][group_id][denomination][obligor] = value;
    }

    function privateAmountOf(
        address index,
        address vault,
        address account,
        uint256 idHash
    ) 
    public 
    view 
    returns (
        string memory
    ){  
        return privateAmounts[index][vault][account][idHash]; 
    }

    function setPrivateAmountMeta(
        address         caller,
        address         vault,
        address         account,
        uint256         idHash,
        string memory   value
    ) 
    public nonReentrant
    {  
        address sender = msg.sender == accessControl ? caller : msg.sender;
        privateAmounts[sender][vault][account][idHash] = value;
    }
}