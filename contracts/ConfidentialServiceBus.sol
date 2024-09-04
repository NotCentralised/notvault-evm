/* 
 SPDX-License-Identifier: MIT
 Service Bus for Solidity v0.9.1369 (ConfidentialServiceBus.sol)

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

contract ConfidentialServiceBus {

    address _verifier;
    
    event set_value(address owner, uint key, uint value, uint block_time);

    mapping (address => mapping (uint256 => uint256)) private valuesMap;

    address accessControl;

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

    function setValue(
            bytes calldata proof,
            uint[2] memory input
        )
        public
        {
            setValueMeta(msg.sender, proof, input);
    }

    function setValueMeta(
            address caller,
            bytes calldata proof,
            uint[2] memory input
        )
        public
        {
            address sender = msg.sender == accessControl ? caller : msg.sender;
            requireProof(proof, input);

            emit set_value(sender, input[1], input[0], block.timestamp);
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
