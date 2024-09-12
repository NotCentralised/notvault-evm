/* 
 SPDX-License-Identifier: MIT
 Access Control Contract for Solidity v0.9.1769 (ConfidentialAccessControl.sol)

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
import "./ConfidentialGroup.sol";
import "./ConfidentialWallet.sol";
import "./circuits/IApproverVerifier.sol";

struct Meta {
    address userAddress;
    address contractAddress;
    bytes   functionSignature;
    bytes32 message;
    bytes   signature;
}

contract ConfidentialAccessControl {

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

            uint256 chainId;
            assembly {
                chainId := chainid()
            }

            bytes[] memory res = new bytes[](meta.length);

            for(uint i = 0; i < meta.length; i++){
                require(meta[i].userAddress == getSigner(meta[i].message, meta[i].signature), "Signer and signature do not match");
                require(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(meta[i].functionSignature)))) == meta[i].message, "function not hash");

                (bool success, bytes memory result) = meta[i].contractAddress.call(meta[i].functionSignature);
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

    // mapping (address => address) private treasurers;
    mapping(address => mapping (uint256 => uint256)) private secrets;

    /*
        Add the treasurer secret
    */
    function addSecret(address caller, bytes calldata proof, uint[2] memory input) public {
        address sender       = address(this) == msg.sender ? caller : msg.sender;

        requireProof(proof, input);
        secrets[sender][input[1]] = input[0];
    }

    mapping(address => mapping (uint256 => Policy)) policies;
    mapping(address => mapping (uint256 => uint256)) policyIndex;
    mapping(address => uint256) policyNonce;

    /*
        Add a policy
    */
    function addPolicyMeta(address caller, uint256 policy_id, Policy memory policy) public {
        
        address sender       = address(this) == msg.sender ? caller : msg.sender;
        require(policy.minSignatories >= 1, "at least one signatory");

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
        public
        {
            if(keccak256(abi.encodePacked(proof.policy_type)) == keccak256(abi.encodePacked("secret"))){
                requireProof(proof.proof, [proof.input[0], proof.input[1]]);

                require(secrets[owner][proof.input[1]] == proof.input[0], "secret's don't match");
                return;
            }
            else if(keccak256(abi.encodePacked(proof.policy_type)) == keccak256(abi.encodePacked("transfer")))
                PolicyVerifier(policyVerifier).requirePolicyProof(proof.proof, [proof.input[0], proof.input[1]]);
            
            else
                AlphaNumericalDataVerifier(dataVerifier).requireDataProof(proof.proof, [proof.input[0], proof.input[1], proof.input[2], proof.input[3], proof.input[4], proof.input[5]]);
            

            int8 call_counter = 0;
            Policy memory policy = policies[owner][proof.input[0]];
            
            if(block.timestamp <= policy.expiry && block.timestamp >= policy.start && policy.counter <= policy.maxUse){

                int8 call_counter_policy = 0;
                
                for(uint j = 0; j < proof.signatures.length; j++){
                    
                    address signer = getSigner(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked((proof.proof))))), proof.signatures[j]);

                    for(uint k = 0; k < policy.callers.length; k++){
                        if(signer == policy.callers[k]){
                            call_counter++;
                            call_counter_policy++;
                        }
                    }

                    require(call_counter_policy >= policy.minSignatories, "not enough signatories");
                }
                
                policy.counter++;
                policies[owner][proof.input[0]] = policy;
            }

            require(call_counter > 0, "no signatory");            
    }

    function requireProof(
            bytes memory _proof,
            uint[2] memory input
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
