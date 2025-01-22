/* 
 SPDX-License-Identifier: MIT
 Vault Utils for Solidity v0.9.9969 (Vault.sol)

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
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../ConfidentialGroup.sol";
import "../ConfidentialAccessControl.sol";
import "../ConfidentialOracle.sol";
import "../ConfidentialDeal.sol";
import "./PoseidonT2.sol";
import "../circuits/IReceiveVerifier.sol";
import "../circuits/ISendVerifier.sol";

struct CreateRequestMessage{
    uint256 index;
    address oracle_address;
    address oracle_owner;

    uint256 oracle_key_sender;
    uint256 oracle_value_sender;
    uint256 oracle_key_recipient;
    uint256 oracle_value_recipient;

    uint32 unlock_sender;
    uint32 unlock_receiver;
}


struct SendRequest{
    uint256 idHash;
    address sender;
    uint256 group_id;

    address denomination;
    address obligor;
    uint256 amount_hash;
    uint32  created;
    uint32  redeemed;
    bool    active;

    address deal_address;
    uint256 deal_group_id;
    uint256 deal_id;

    address oracle_address;
    address oracle_owner;
    uint256 oracle_key_sender;
    uint256 oracle_value_sender;
    uint256 oracle_key_recipient;
    uint256 oracle_value_recipient;
    uint32  unlock_sender;
    uint32  unlock_receiver;
}

struct SendProof {
    bytes   proof;
    uint[7] input;
}

struct Payment {
    address denomination;
    address obligor;

    address deal_address;
    uint256 deal_group_id;
    uint256 deal_id;
}

struct CheckWidraw {
    bytes   proof_sender;
    uint[7] input_sender;
    address contract_address;
    address payer_address;
    address denomination;
    
    address obligor;
    uint256 sendNonce;
    uint256 balance;
    uint256 amount;
}

struct CheckDeposit {
    address payer_address;
    address vault_address;

    uint256 amount;
    uint256 hashBalance;

    address denomination; 
    address obligor;
    
    bytes proof_sender;
    uint[3] input_sender;
}

contract Vault {
    address immutable accessControl;
    address immutable sendVerifier;
    address immutable receiveVerifier;
    address immutable paymentSignatureVerifierAddress;
    
    constructor(
        address _accessControl,
        address _sendVerifier,
        address _receiveVerifier,
        address _signatureVerifier
    )
    {
        accessControl = _accessControl;
        sendVerifier = _sendVerifier;
        receiveVerifier = _receiveVerifier;
        paymentSignatureVerifierAddress = _signatureVerifier;
    }

    function checkDeposit(
        CheckDeposit memory cd
    ) public view {
        require((cd.obligor == address(0) ? PoseidonT2.hash([cd.amount]) == cd.input_sender[2] : cd.amount == uint256(0)),"Incorrect Amount");
        require(cd.hashBalance == 0 ? cd.input_sender[2] == cd.input_sender[1] : cd.hashBalance == cd.input_sender[0],"Balances don't match");

        uint256[8] memory p = abi.decode(cd.proof_sender, (uint256[8]));
        ReceiveVerifier(receiveVerifier).verifyProof(
            [p[0], p[1]],
            [[p[2], p[3]], [p[4], p[5]]],
            [p[6], p[7]],
            [cd.input_sender[0], cd.input_sender[1], cd.input_sender[2]]
        );
    }

    function checkWithdraw(
        CheckWidraw memory ck
    ) public view {

        ck.input_sender[3] = ck.sendNonce;
        
        uint256[8] memory p = abi.decode(ck.proof_sender, (uint256[8]));
        SendVerifier(sendVerifier).verifyProof(
            [p[0], p[1]],
            [[p[2], p[3]], [p[4], p[5]]],
            [p[6], p[7]],
            [ck.input_sender[0], ck.input_sender[1], ck.input_sender[2], ck.input_sender[3], ck.input_sender[4], ck.input_sender[5], ck.input_sender[6]]
        );

        require(PoseidonT2.hash([ck.amount]) == ck.input_sender[2], "incorrect amount");
        require(ck.input_sender[3] == ck.sendNonce, "Nonce don't match");
        require(ck.balance == ck.input_sender[0], "initial balances don't match");
        require(ck.payer_address != address(0) && ck.denomination != address(0), "payer_address cannot be null");
        require(ck.obligor == address(0) ? 0 < ck.amount && ck.amount <= IERC20(ck.denomination).balanceOf(ck.contract_address) : true, "amount must be less than or equal to contract balance");
    }

    function checkSend(
        SendProof memory proof, 
        uint256 sendNonce, 
        uint256 balance, 
        uint256 deal_id, 
        Payment memory payment, 
        uint256 length
    ) public view {
        uint256[8] memory p = abi.decode(proof.proof, (uint256[8]));
        SendVerifier(sendVerifier).verifyProof(
            [p[0], p[1]],
            [[p[2], p[3]], [p[4], p[5]]],
            [p[6], p[7]],
            [proof.input[0], proof.input[1], proof.input[2], proof.input[3], proof.input[4], proof.input[5], proof.input[6]]
        );

        require(proof.input[3] == sendNonce, "Nonce don't match");
        require(balance == proof.input[0], "initial balances don't match");
        require(PoseidonT2.hash([length]) == proof.input[6], "incorrect count");
        require(deal_id != 0 ? ConfidentialDeal(payment.deal_address).getDealByID(deal_id).expiry > block.timestamp : true, "deal cannot have expired when making a payment");
    }

    function checkAccept(
        address receiver,
        address group,
        
        SendRequest memory sr, 
        uint256 hashBalance,

        bytes calldata  proof,
        uint[3] memory  input
    ) public view {
        uint256 amount_hash = sr.amount_hash;
        uint256 deal_id = sr.deal_id;

        uint256[8] memory p = abi.decode(proof, (uint256[8]));
        ReceiveVerifier(receiveVerifier).verifyProof(
            [p[0], p[1]],
            [[p[2], p[3]], [p[4], p[5]]],
            [p[6], p[7]],
            [input[0], input[1], input[2]]
        );

        require(sr.active, "Transfer request is not active");
        require(hashBalance == 0 ? (input[2] == input[1]) : (hashBalance == input[0]), "Initial amounts don't match");
        require(amount_hash == input[2], "Amounts don't match");
        require((
                deal_id != 0 ? 
                (IERC721(sr.deal_address).ownerOf(deal_id) == receiver || sr.sender == receiver || group == receiver)
                : 
                (sr.deal_address == receiver || sr.sender == receiver || group == receiver)
            ),  "You are not the owner");
        
        if(receiver == sr.sender) {
            require(sr.unlock_sender < block.timestamp, "sender unlock time is in the future");
            if(sr.oracle_address != address(0)) {
                uint oracle_value = ConfidentialOracle(sr.oracle_address).getValue(sr.oracle_owner, sr.oracle_key_sender);
                require(sr.oracle_value_sender == oracle_value, "oracle sender values don't match");
            }
        }
        else {
            require(sr.unlock_receiver < block.timestamp, "recipient unlock time is in the future");

            if(sr.deal_id > 0) {
                require(ConfidentialDeal(sr.deal_address).getDealByID(sr.deal_id).accepted > 0, "deal must be accepted first");
            }

            if(sr.oracle_address != address(0)){
                uint oracle_value = ConfidentialOracle(sr.oracle_address).getValue(sr.oracle_owner, sr.oracle_key_recipient);
                require(sr.oracle_value_recipient == oracle_value, "oracle recipient values don't match");
            }
        }
    }

    function getHash(
        CreateRequestMessage memory cr, 
        SendProof memory proof, 
        uint i
    ) public pure returns(uint256) {
        uint256 idHash = uint256(keccak256(abi.encodePacked([proof.input[4], i, 
                    uint256(uint160(cr.oracle_address)), uint256(uint160(cr.oracle_owner)), 
                    cr.oracle_key_sender, cr.oracle_value_sender, 
                    cr.oracle_key_recipient, cr.oracle_value_recipient, 
                    cr.unlock_sender, cr.unlock_receiver])));
        
        return (idHash);
    }
}