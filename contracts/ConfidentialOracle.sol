/* 
 SPDX-License-Identifier: MIT
 Oracle for Solidity v0.9.969 (ConfidentialOracle.sol)

  _   _       _    _____           _             _ _              _ 
 | \ | |     | |  / ____|         | |           | (_)            | |
 |  \| | ___ | |_| |     ___ _ __ | |_ _ __ __ _| |_ ___  ___  __| |
 | . ` |/ _ \| __| |    / _ \ '_ \| __| '__/ _` | | / __|/ _ \/ _` |
 | |\  | (_) | |_| |___|  __/ | | | |_| | | (_| | | \__ \  __/ (_| |
 |_| \_|\___/ \__|\_____\___|_| |_|\__|_|  \__,_|_|_|___/\___|\__,_|
                                                                    
                                                                    
 Author: @NumbersDeFi 
*/
pragma solidity ^0.8.9;

import "./circuits/IApproverVerifier.sol";

contract ConfidentialOracle {
    /* 
        General description of custom functionality

        Confidential Oracles allow external parties to set values in a key-pair in order to unlock send requests in the vault.
        The external party is assumed to be the owner of an address and this address it the only one able to set a value for a given key in a key-pair linked to that address.
        The owner of an address is able to set a value to given key.
        A viewer can check the value of a key that can only be set by a specific address owner.
    */

    address _verifier;
    address accessControl;
    
    mapping (address => mapping (uint256 => uint256)) private valuesMap;

    constructor(address verifier, address _accessControl) { 
        _verifier = verifier; 
        accessControl = _accessControl; 
    }

    function getValue(
            address owner,
            uint256 key
        ) 
        public 
        view 
        returns (
            uint256
        ){
            return valuesMap[owner][key];
    } 

    /*
        Set value attached to a given proof. 
        The ZK proof contains a key and value.
        The ZK proof allows the contract to verify that the address owner knows the underlying value of the hashed value.
    */
    function setValueMeta(
            address caller,
            bytes calldata proof,
            uint[2] memory input
        )
        public
        {
            address sender = msg.sender == accessControl ? caller : msg.sender;

            requireProof(proof, input);

            valuesMap[sender][input[1]] = input[0];
    }

    function requireProof(
            bytes memory _proof,
            uint[2] memory input
        ) internal view {
            uint256[8] memory p = abi.decode(_proof, (uint256[8]));
            require(
                ApproverVerifier(_verifier).verifyProof(
                    [p[0], p[1]],
                    [[p[2], p[3]], [p[4], p[5]]],
                    [p[6], p[7]],
                    input
            ),
            "Invalid approver (ZK)"
            );
    }
}
