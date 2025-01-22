/* 
 SPDX-License-Identifier: MIT
 Access Control Contract for Solidity v0.9.9969 (ConfidentialAccessControl.sol)

  _   _       _    _____           _             _ _              _ 
 | \ | |     | |  / ____|         | |           | (_)            | |
 |  \| | ___ | |_| |     ___ _ __ | |_ _ __ __ _| |_ ___  ___  __| |
 | . ` |/ _ \| __| |    / _ \ '_ \| __| '__/ _` | | / __|/ _ \/ _` |
 | |\  | (_) | |_| |___|  __/ | | | |_| | | (_| | | \__ \  __/ (_| |
 |_| \_|\___/ \__|\_____\___|_| |_|\__|_|  \__,_|_|_|___/\___|\__,_|
                                                                    
                                                                    
 Author: @NumbersDeFi 
*/

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./ConfidentialVault.sol";
import "./ConfidentialGroup.sol";
import "./ConfidentialWallet.sol";
import "./circuits/IApproverVerifier.sol";

import "hardhat/console.sol";

struct Meta {
    address userAddress;
    address contractAddress;
    bytes   functionSignature;
    bytes32 message;
    bytes   signature;
    uint256 value;
}

contract ConfidentialAccessControl is ReentrancyGuard {

    address private policyVerifier;
    address private dataVerifier;
    address private hashVerifier;

    constructor(address _policyVerifier, address _dataVerifier, address _hashVerifier) { 
        policyVerifier = _policyVerifier; 
        hashVerifier = _hashVerifier; 
        dataVerifier = _dataVerifier; 
    }

    /* 
        Execute a contract function by a relay wallet on behalf of a user wallet.
        The user wallet signs the transaction off-chain, sends it to the relay wallet and the relay wallets transmits the transaction to the blockchain paying the gas fees.
        The smart contract verifies that the signed functioncal is signed by the user wallet.
    */
    function executeMultiMetaTransaction(
        Meta[] memory meta
    ) public payable returns (bytes[] memory) {

        console.log("RECEIVED: ", msg.value);

        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        bytes[] memory res = new bytes[](meta.length);

        for(uint i = 0; i < meta.length; i++){
            require(meta[i].userAddress == getSigner(meta[i].message, meta[i].signature), "Signer and signature do not match");
            require(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(meta[i].functionSignature)))) == meta[i].message, "function not hash");

            console.log("ADDRESS: ", meta[i].contractAddress);
            console.log("VALUE: ", meta[i].value);
            (bool success, bytes memory result) = meta[i].contractAddress.call{value: meta[i].value}(meta[i].functionSignature);
            if (!success) {
            
                if (result.length > 0) {
                    assembly {
                        let returndata_size := mload(result)
                        revert(add(32, result), returndata_size)
                    }
                } else {
                    revert(string(abi.encodePacked("Function call not successful and no error message returned: ", meta[i].contractAddress)));
                }
            }

            res[i] = result;
        }
        return res;
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

    mapping(address => mapping (uint256 => uint256)) private secrets;

    /*
        Add the treasurer secret
    */
    function addSecret(address caller, bytes calldata proof, uint[3] memory input) public nonReentrant {
        address sender       = address(this) == msg.sender ? caller : msg.sender;

        requireProof(proof, input);
        secrets[sender][input[1]] = input[0];
    }

    mapping(address => mapping (uint256 => Policy)) policies;
    mapping(address => mapping (uint256 => uint256)) policyIndex;
    mapping(address => uint256) policyNonce;

    mapping(uint256 => bool) usedPolicies;

    /*
        Add a policy
    */
    function addPolicyMeta(address caller, uint256 policy_id, Policy memory policy) public nonReentrant {
        
        address sender       = address(this) == msg.sender ? caller : msg.sender;
        require(policy.minSignatories >= 1, "at least one signatory");
        require(areMembersUnique(policy.callers_address, policy.callers_id), "callers must be unique");
        require(policy.callers_address.length > 0, "must be atleast 1 caller");

        policy.counter = 0;

        policyIndex[sender][policyNonce[sender]] = policy_id;
        policies[sender][policy_id] = policy;
        policyNonce[sender]++;
    }

    /*
        Use a policy
    */
    function usePolicyMeta(
        address owner, 
        PolicyProof memory proof
    ) 
    public nonReentrant
    {
        require(!usedPolicies[proof.input[2]], "policy already used");

        if(keccak256(abi.encodePacked(proof.policy_type)) == keccak256(abi.encodePacked("secret"))){
            requireProof(proof.proof, [proof.input[0], proof.input[1], proof.input[2]]);

            require(secrets[owner][proof.input[1]] > 0, "no secret registered");
            require(secrets[owner][proof.input[1]] == proof.input[0], "secret's don't match");
            usedPolicies[proof.input[2]] = true;
            return;
        }
        else if(keccak256(abi.encodePacked(proof.policy_type)) == keccak256(abi.encodePacked("transfer"))){
            uint256[8] memory p = abi.decode(proof.proof, (uint256[8]));
            PolicyVerifier(policyVerifier).verifyProof(
                [p[0], p[1]],
                [[p[2], p[3]], [p[4], p[5]]],
                [p[6], p[7]], 
                [proof.input[0], proof.input[1]]);
        }
        
        else {
            uint256[8] memory p = abi.decode(proof.proof, (uint256[8]));
            AlphaNumericalDataVerifier(dataVerifier).verifyProof(
                [p[0], p[1]],
                [[p[2], p[3]], [p[4], p[5]]],
                [p[6], p[7]], 
                [proof.input[0], proof.input[1], proof.input[2], proof.input[3], proof.input[4], proof.input[5]]);
        }
        

        uint8 call_counter = 0;
        Policy memory policy = policies[owner][proof.input[0]];

        address[] memory _callers = new address[](proof.signatures.length);
        
        if(block.timestamp <= policy.expiry && block.timestamp >= policy.start && policy.counter <= policy.maxUse){

            uint8 call_counter_policy = 0;
            
            for(uint j = 0; j < proof.signatures.length; j++){
                
                address signer = getSigner(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked((proof.proof))))), proof.signatures[j]);

                _callers[j] = signer;

                for(uint k = 0; k < policy.callers_address.length; k++){
                    if(policy.callers_id[k] == 0){
                        if(signer == policy.callers_address[k]){
                            call_counter_policy++;
                        }
                    }
                    else{
                        if(signer == IERC721(policy.callers_address[k]).ownerOf(policy.callers_id[k])){
                            call_counter_policy++;
                        }
                    }
                }

                require(call_counter_policy >= 1, "signer not in policy list");
            }
            
            policy.counter++;
            policies[owner][proof.input[0]] = policy;
        }
        require(call_counter >= policy.minSignatories, "not enough signatories");
        require(areAddressesUnique(_callers), "callers must be unique");

        usedPolicies[proof.input[2]] = true;
    }

    function areAddressesUnique(address[] memory arr) public pure returns (bool) {
        uint256 length = arr.length;
        for (uint256 i = 0; i < length; i++) {
            for (uint256 j = i + 1; j < length; j++) {
                if (arr[i] == arr[j]) {
                    return false; // Duplicate address found
                }
            }
        }
        return true; // All addresses are unique
    }

    function areMembersUnique(address[] memory addresses, uint256[] memory ids) public pure returns (bool) {
        uint256 length = addresses.length;
        for (uint256 i = 0; i < length; i++) {
            for (uint256 j = i + 1; j < length; j++) {
                if (addresses[i] == addresses[j] && ids[i] == ids[j]) {
                    return false; // Duplicate address found
                }
            }
        }
        return true; // All addresses are unique
    }

    function requireProof(
        bytes memory _proof,
        uint[3] memory input
    ) internal view {
        uint256[8] memory p = abi.decode(_proof, (uint256[8]));
        require(
            ApproverVerifier(hashVerifier).verifyProof(
                [p[0], p[1]],
                [[p[2], p[3]], [p[4], p[5]]],
                [p[6], p[7]],
                input
            ),
            "Invalid approver (ZK)"
        );
    }
}
