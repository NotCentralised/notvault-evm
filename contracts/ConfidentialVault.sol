/* 
 SPDX-License-Identifier: MIT
 Confidential Vault Contract for Solidity v0.9.1869 (ConfidentialVault.sol)

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

import "./circuits/IReceiveVerifier.sol";
import "./circuits/ISendVerifier.sol";

import "./ConfidentialWallet.sol";
import "./ConfidentialDeal.sol";
import "./ConfidentialOracle.sol";
import "./ConfidentialAccessControl.sol";
import "./ConfidentialGroup.sol";
import "./utils/PoseidonT2.sol";

struct CreateRequestMessage{
    address oracle_address;
    address oracle_owner;

    uint256 oracle_key_sender;
    uint256 oracle_value_sender;
    uint256 oracle_key_recipient;
    uint256 oracle_value_recipient;

    uint32 unlock_sender;
    uint32 unlock_receiver;
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

contract ConfidentialVault {
    
    /* 
        General description of custom functionality

        Confidential Vault is a smart contract that allows a sender wallet to send a given number of tokens to a recipient wallet where the number of tokens is unknown to the blockchain.
        The smart contract stores hashes instead of transparent balances and the calculation of balance changes happens off-chain.
        Using zero-knowledge-proofs, the smart contract only accepts transfers that are not spending more than the sender initially had.
        
        Sending tokens using the vault is an asynchronous process.
            - The sender first creates a request to send tokens and locks the number of sent tokens such that only the sender or the receiver can unlock them under certain conditions.
            - The receiver can accept the locked tokens in the sender's request in a separate transaction.

        Steps of use:
            - Sender deposits a given number of ERC20 tokens to the vault. NOTE: This transaction is visible to all
            - Sender creates a send request locking in the token amount and deducting this amount from their hashed balance. This step requires a ZK proof.
            - Received accepts the request and offers a ZK proof to the contract that new balance is the sum of the old balance and the sent amount.
             
        The sender is able to set unlocking conditions on each send request including:
            - earliest time the receiver can unlock tokens
            - earliest time the sender can unlock tokens
            - value an oracle must have for the receiver to unlock tokens
            - value an oracle must have for the sender to unlock tokens

        Recipient
        Send Requests are programmed to be received by either:
            - a specific wallet defined by the deal_address if the deal_id is set to 0
            - the owner of a deal if the deal_id is not 0. If the deal_id is not zero, the deal_addres must be the smart contract address of the deal

        Obligor
        The vault allows the treasurer wallet of a given denomination to increase their confidential vault balance without depositing the underlying ERC20 token.
        This enables a treasurer to mint "credit" linked to a given denomination issued by the "obligor".
        This obligor linked token is meant to be redeemed by the obligor in exchange for the ERC20 token.
    */

    address sendVerifier;
    address receiveVerifier;
    address paymentSignatureVerifierAddress;
    mapping (address => mapping (uint256 => mapping (address => mapping (address => uint256)))) private _hashBalances;
    
    mapping (address => mapping (uint256 => uint256)) sendNonce;
    mapping (address => mapping (uint256 => mapping (uint256 => uint256))) receiveNonce;
    
    mapping (address => mapping (uint256 => mapping (uint256 => uint256))) sendPoolIndex;
    mapping (address => mapping (uint256 => mapping (uint256 => mapping (uint256 => uint256)))) receivePoolIndex;
    
    mapping (uint256 => SendRequest) sendPool;

    address accessControl;
    address group;
    
    constructor(
        address _sendVerifier,
        address _receiveVerifier,
        address _signatureVerifier,
        address _accessControl,
        address _group
        )
        {
            sendVerifier = _sendVerifier;
            receiveVerifier = _receiveVerifier;
            paymentSignatureVerifierAddress = _signatureVerifier;
            accessControl = _accessControl;
            group = _group;
    }

    function getSendRequestByIndex(address account, uint256 groupId, uint256 dealId, uint i, bool bySender) public view returns (SendRequest memory) {
        return sendPool[bySender ? sendPoolIndex[account][groupId][i] : receivePoolIndex[account][groupId][dealId][i]];
    }

    function getSendRequestByID(uint256 idHash) public view returns (SendRequest memory) {
        return sendPool[idHash];
    }

    function getNonce(address account, uint256 groupId, uint256 dealId, bool bySender) public view returns (uint256) {
        return bySender ? sendNonce[account][groupId] : receiveNonce[account][groupId][dealId];
    }

    /*
        Sender deposits an ERC20 token of the denomination address.
        If the obligor parameter is not the zero address, the smart contract verifies that the caller is the treasurer.
    */
    function depositMeta(
            address caller,
            uint256 group_id,
            address denomination,
            address obligor,
            uint256 amount,
            bytes calldata proof_sender,
            uint[3] memory input_sender,
            PolicyProof memory policy_proof
        )
        public 
        //payable // Hashlock comment H-02
        {
            if(group_id > 0)
                require(group == msg.sender, "only group can call");
            
            address payer_address = accessControl == msg.sender ? caller : msg.sender;
            address contract_address = address(this);

            uint _hashBalance = _hashBalances[payer_address][group_id][denomination][obligor];

            require((obligor == address(0) ? PoseidonT2.hash([amount]) == input_sender[2] : amount == uint256(0)),"Incorrect Amount");
            require(_hashBalance == 0 ? input_sender[2] == input_sender[1] : _hashBalance == input_sender[0],"Balances don't match");
            

            ReceiveVerifier(receiveVerifier).requireReceiverProof(proof_sender, input_sender);

            if(obligor == address(0)){
                require(amount <= IERC20(denomination).allowance(payer_address, contract_address), "Not Enough Allowance");
                IERC20(denomination).transferFrom(payer_address, contract_address, amount);
            }
            else
                ConfidentialAccessControl(accessControl).usePolicyMeta(denomination, policy_proof);

            _hashBalances[payer_address][group_id][denomination][obligor] = input_sender[1];
    }

    /*
        Withdraw amont from the vault by decreasing vault balance and transfering ERC20 from smart contract balance to the caller.
    */
    function withdrawMeta(
            address             caller,
            uint256             group_id,
            address             denomination,
            address             obligor,
            uint256             amount,
            bytes calldata      proof_sender,
            uint[7] memory      input_sender,
            PolicyProof memory  policy_proof
        ) 
        public
        {
            if(group_id > 0)
                require(group == msg.sender, "only group can call");
            
            address payer_address       = accessControl == msg.sender ? caller : msg.sender;
            address contract_address    = address(this);

            input_sender[3] = sendNonce[payer_address][group_id];
            SendVerifier(sendVerifier).requireSenderProof(proof_sender, input_sender);
                        
            require(
                PoseidonT2.hash([amount]) == input_sender[2] && // "incorrect amount"
                input_sender[3] == sendNonce[payer_address][group_id] && // "Nonce don't match"
                _hashBalances[payer_address][group_id][denomination][obligor] == input_sender[0] && // "initial balances don't match"
                payer_address != address(0) && denomination != address(0) && // "payer_address cannot be null"
                obligor == address(0) ? 0 < amount && amount <= IERC20(denomination).balanceOf(contract_address) : true // "amount must be less than or equal to contract balance"
                , "withdraw: setup error");

            _hashBalances[payer_address][group_id][denomination][obligor] = input_sender[1];
            
            if(obligor == address(0))
                IERC20(denomination).transfer(payer_address, amount);
            else
                ConfidentialAccessControl(accessControl).usePolicyMeta(denomination, policy_proof);
    }

    /*
        Create a send request based on the following parameters:
            - group_id: defines the group from which the balance of the send request is deducted

            - cr:
                oracle_address: address of oracle that can unlock the send request
                oracle_owner: owner of the key that can unlock the send request

                oracle_key_sender: key for the value that unlocks the request for the sender
                oracle_value_sender: value that unlocks the request for the sender
                oracle_key_recipient: key for the value that unlocks the request for the recipient
                oracle_value_recipient: value that unlocks the request for the recipient

                unlock_sender: earliest time a sender can unlock
                unlock_receiver: earliest time a recipient can unlock

            - proof: ZK proof to show that the balance is enough to send tokens and the new balance is the deduction of the tokens.

            - payment: 
                denomination: address of the ERC20 tokens
                obligor: obligor linked to the credit token if this value is not the zero address

                deal_address: address of the recipient or the deal contract address
                deal_group_id: group_id of the recipient
                deal_id: if the deal_id is not 0, the recipient of the send request is the owner of the deal. otherwise the recipient is the address of the deal_address

            - agree: if this send request is linked to a deal and the necessary tokens are being locked, setting this to true will call the agree function of the deal smart contract
    */
    function createRequestMeta(
            address                         caller,
            uint256                         group_id,
            CreateRequestMessage[] memory   cr,
            SendProof memory                proof,            
            Payment memory                  payment,
            bool                            agree
        ) 
        public
        {
            address sender  = accessControl == msg.sender ? caller : msg.sender;

            if(group_id > 0){
                require(group == msg.sender, "only group can call");
                sender = caller;
            }

            uint256 deal_id = payment.deal_id;
            address denomination = payment.denomination;
                
            SendVerifier(sendVerifier).requireSenderProof(proof.proof, proof.input);                

            require(
                proof.input[3] == sendNonce[sender][group_id] && // "Nonce don't match"
                _hashBalances[sender][group_id][denomination][payment.obligor] == proof.input[0] && // "initial balances don't match"
                PoseidonT2.hash([cr.length]) == proof.input[6] && // "incorrect count"
                deal_id != 0 ? ConfidentialDeal(payment.deal_address).getDealByID(deal_id).expiry > block.timestamp : true // "deal cannot have expired when making a payment"
            ,"create: setup error");
          
            uint send_nonce = sendNonce[sender][group_id];

            for(uint i = 0; i < cr.length; i++){
                uint256 idHash = uint256(keccak256(abi.encodePacked([proof.input[4], i, 
                    uint256(uint160(cr[i].oracle_address)), uint256(uint160(cr[i].oracle_owner)), 
                    cr[i].oracle_key_sender, cr[i].oracle_value_sender, 
                    cr[i].oracle_key_recipient, cr[i].oracle_value_recipient, 
                    cr[i].unlock_sender, cr[i].unlock_receiver])));

                sendPool[idHash] = SendRequest(
                    idHash, sender, group_id,
                    denomination, payment.obligor, proof.input[2], 
                    uint32(block.timestamp), 0, true, 
                    payment.deal_address, payment.deal_group_id, deal_id,
                    cr[i].oracle_address, cr[i].oracle_owner, 
                    cr[i].oracle_key_sender, cr[i].oracle_value_sender, 
                    cr[i].oracle_key_recipient, cr[i].oracle_value_recipient, 
                    cr[i].unlock_sender, cr[i].unlock_receiver);

                sendPoolIndex[sender][group_id][send_nonce] = idHash;
                
                send_nonce++;                
                
                if(deal_id != 0)
                    ConfidentialDeal(payment.deal_address).addSendRequestMeta(sender, deal_id, idHash);
                
                receivePoolIndex[payment.deal_address][payment.deal_group_id][deal_id][receiveNonce[payment.deal_address][payment.deal_group_id][deal_id]] = idHash;
                receiveNonce[payment.deal_address][payment.deal_group_id][deal_id] = receiveNonce[payment.deal_address][payment.deal_group_id][deal_id] + 1;
            }

            sendNonce[sender][group_id] = send_nonce;

            _hashBalances[sender][group_id][denomination][payment.obligor] = proof.input[1];

            if(agree){
                require((sender == ConfidentialDeal(payment.deal_address).getDealByID(deal_id).counterpart), "only the owner can agree");
                ConfidentialDeal(payment.deal_address).acceptMeta(sender, deal_id);
            }
    }

    /*
        Accept the request linked to a hash id. A proof is necessary to change the balance of the accepting wallet.
    */
    function acceptRequestMeta(
            address         caller,
            uint256         idHash,
            bytes calldata  proof,
            uint[3] memory  input
        )
        public
        {
            address receiver  = accessControl == msg.sender ? caller : msg.sender;
            ReceiveVerifier(receiveVerifier).requireReceiverProof(proof, input);

            SendRequest memory sr = sendPool[idHash];
            uint256 amount_hash = sr.amount_hash;
            address denomination = sr.denomination;
            uint256 deal_id = sr.deal_id;

            if(sr.deal_group_id > 0)
                require(group == msg.sender, "only group can call");

            address checkAddress = sr.sender == receiver ? receiver : (deal_id != 0 ? IERC721(sr.deal_address).ownerOf(deal_id) : sr.deal_address);
            
            require(
                sr.active && // "Transfer request is not active"
                // _hashBalances[checkAddress][sr.deal_group_id][denomination][sr.obligor] == 0 ? (input[2] == input[1]) : (true) && // "Initial amounts don't match"
                _hashBalances[checkAddress][sr.deal_group_id][denomination][sr.obligor] == 0 ? (input[2] == input[1]) : (_hashBalances[checkAddress][sr.deal_group_id][denomination][sr.obligor] == input[0]) && // "Initial amounts don't match"
                amount_hash == input[2] && // "Amounts don't match"
                (
                    deal_id != 0 ? 
                    (IERC721(sr.deal_address).ownerOf(deal_id) == receiver || sr.sender == receiver || group == receiver)
                    : 
                    (sr.deal_address == receiver || sr.sender == receiver || group == receiver)
                ) //  "You are not the owner"
                ,"accept: setup error");

            
            if(receiver == sr.sender){
                require(sr.unlock_sender < block.timestamp, "sender unlock time is in the future");
                if(sr.oracle_address != address(0)){
                    uint oracle_value = ConfidentialOracle(sr.oracle_address).getValue(sr.oracle_owner, sr.oracle_key_sender);
                    require(sr.oracle_value_sender == oracle_value, "oracle sender values don't match");
                }
            }
            else{
                require(sr.unlock_receiver < block.timestamp, "recipient unlock time is in the future");

                if(sr.deal_id > 0){
                    require(ConfidentialDeal(sr.deal_address).getDealByID(sr.deal_id).accepted > 0, "deal must be accepted first");
                }

                if(sr.oracle_address != address(0)){
                    uint oracle_value = ConfidentialOracle(sr.oracle_address).getValue(sr.oracle_owner, sr.oracle_key_recipient);
                    require(sr.oracle_value_recipient == oracle_value, "oracle recipient values don't match");
                }
            }

            sendPool[idHash] = SendRequest(
                idHash, sr.sender, sr.group_id,
                denomination, sr.obligor, amount_hash, 
                sr.created, uint32(block.timestamp), false, sr.deal_address, sr.deal_group_id, deal_id, sr.oracle_address, sr.oracle_owner, 
                sr.oracle_key_sender, sr.oracle_value_sender, 
                sr.oracle_key_recipient, sr.oracle_value_recipient, 
                sr.unlock_sender, sr.unlock_receiver);

            _hashBalances[checkAddress][sr.deal_group_id][denomination][sr.obligor] = input[1];
    }

    // function requireDataProof(
    //     bytes memory _proof,
    //     uint[6] memory input
    // ) public view {
    //     uint256[8] memory p = abi.decode(_proof, (uint256[8]));
    //     require(
    //         verifyProof(
    //             [p[0], p[1]],
    //             [[p[2], p[3]], [p[4], p[5]]],
    //             [p[6], p[7]],
    //             input
    //     ),
    //     "Invalid policy (ZK)"
    //     );
    // }

    // function requirePolicyProof(
    //     bytes memory _proof,
    //     uint[2] memory input
    // ) public view {
    //     uint256[8] memory p = abi.decode(_proof, (uint256[8]));
    //     require(
    //         verifyProof(
    //             [p[0], p[1]],
    //             [[p[2], p[3]], [p[4], p[5]]],
    //             [p[6], p[7]],
    //             input
    //     ),
    //     "Invalid policy (ZK)"
    //     );
    // }

    // function requireSenderProof(
    //         bytes memory _proof,
    //         uint[7] memory input
    //     ) public view {
    //         uint256[8] memory p = abi.decode(_proof, (uint256[8]));
    //         require(
    //             verifyProof(
    //                 [p[0], p[1]],
    //                 [[p[2], p[3]], [p[4], p[5]]],
    //                 [p[6], p[7]],
    //                 input
    //         ),
    //         "Invalid sender (ZK)"
    //         );
    // }

    // function requireReceiverProof(
    //         bytes memory _proof,
    //         uint[3] memory input
    //     ) public view {
    //         uint256[8] memory p = abi.decode(_proof, (uint256[8]));
    //         require(
    //             verifyProof(
    //                 [p[0], p[1]],
    //                 [[p[2], p[3]], [p[4], p[5]]],
    //                 [p[6], p[7]],
    //                 input
    //         ),
    //         "Invalid receiver (ZK)"
    //         );
    // }

    // function requireSignatureProof(
    //         bytes memory _proof,
    //         uint[2] memory input
    //     ) public view {
    //         uint256[8] memory p = abi.decode(_proof, (uint256[8]));
    //         require(
    //             verifyProof(
    //                 [p[0], p[1]],
    //                 [[p[2], p[3]], [p[4], p[5]]],
    //                 [p[6], p[7]],
    //                 input
    //         ),
    //         "Invalid signature (ZK)"
    //         );
    // }
}