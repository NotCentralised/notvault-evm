/* 
 SPDX-License-Identifier: MIT
 Oracle for Solidity v0.4.4 (ConfidentialOracle.sol)

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

    address _verifier;
    
    mapping (address => mapping (uint256 => uint256)) private valuesMap;

    constructor(address verifier) { _verifier = verifier; }

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

    function setValue(
            bytes calldata proof,
            uint[2] memory input
        )
        public
        {
            requireProof(proof, input);

            address owner = msg.sender;
            valuesMap[owner][input[1]] = input[0];
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
