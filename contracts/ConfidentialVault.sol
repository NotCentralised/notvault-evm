/* 
 SPDX-License-Identifier: MIT
 Confidential Vault Contract for Solidity v0.9.569 (ConfidentialVault.sol)

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
import "./utils/PoseidonT2.sol";

import "./circuits/IPaymentSignatureVerifier.sol";

struct CreateRequestMessage{
    address denomination;
    address obligor;
    
    address oracle_address;
    address oracle_owner;

    uint256 oracle_key_sender;
    uint256 oracle_value_sender;
    uint256 oracle_key_recipient;
    uint256 oracle_value_recipient;

    uint32 unlock_sender;
    uint32 unlock_receiver;

    bytes   proof_send;
    uint[5] input_send;

    bytes   proof_signature;
    uint[2] input_signature;
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
    address sendVerifier;
    address receiveVerifier;
    address paymentSignatureVerifierAddress;
    mapping (address => mapping (uint256 => mapping (address => mapping (address => uint256)))) private _hashBalances;
    
    mapping (address => mapping (uint256 => uint256)) sendNonce;
    mapping (address => mapping (uint256 => mapping (uint256 => uint256))) receiveNonce;
    
    mapping (address => mapping (uint256 => mapping (uint256 => mapping (uint256 => uint256)))) sendPoolIndex;
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

    function getSendRequestByAddress(address account, uint256 groupId, uint256 dealId, bool bySender) public view returns (SendRequest[] memory) {
        uint256 count = bySender ? sendNonce[account][groupId] : receiveNonce[account][groupId][dealId];
        SendRequest[] memory srs = new SendRequest[](count);
        for(uint i = 0; i < count; i++){
            srs[i] = sendPool[bySender ? sendPoolIndex[account][groupId][dealId][i] : receivePoolIndex[account][groupId][dealId][i]];
        }
        return srs;
    }

    function getSendRequestByID(uint256 idHash) public view returns (SendRequest memory) {
        return sendPool[idHash];
    }

    function getNonce(address account, uint256 groupId) public view returns (uint256) {
        return sendNonce[account][groupId];
    }


    function depositMeta(
            address caller,
            uint256 group_id,
            address denomination,
            address obligor,
            uint256 amount,
            bytes calldata proof,
            uint[3] memory input
        )
        public 
        //payable // Hashlock comment H-02
        {
            if(group_id > 0)
                require(group == msg.sender, "only group can call");
            
            address payer_address = accessControl == msg.sender ? caller : msg.sender;
            address contract_address = address(this);

            uint _hashBalance = _hashBalances[payer_address][group_id][denomination][obligor];

            require((obligor == address(0) ? PoseidonT2.hash([amount]) == input[2] : amount == uint256(0)),"Incorrect Amount");
            require(_hashBalance == 0 ? input[2] == input[1] : _hashBalance == input[0],"Balances don't match");
            require(amount <= IERC20(denomination).allowance(payer_address, contract_address), "Not Enough Allowance");

            ReceiveVerifier(receiveVerifier).requireReceiverProof(proof, input);

            if(obligor == address(0))
                IERC20(denomination).transferFrom(payer_address, contract_address, amount);
            else
                require(ConfidentialAccessControl(accessControl).isTreasurer(payer_address, denomination), "Only Treasurer can deposit");

            _hashBalances[payer_address][group_id][denomination][obligor] = input[1];
    }

    function withdrawMeta(
            address         caller,
            uint256         group_id,
            address         denomination,
            address         obligor,
            uint256         amount,
            bytes calldata  proof,
            uint[5] memory  input
        ) 
        public
        {
            if(group_id > 0)
                require(group == msg.sender, "only group can call");
            
            address payer_address       = accessControl == msg.sender ? caller : msg.sender;
            address contract_address    = address(this);

            input[3] = sendNonce[payer_address][group_id];
            SendVerifier(sendVerifier).requireSenderProof(proof, input);
            
            // require(PoseidonT2.hash([amount]) == input[2] && input[3] == sendNonce[payer_address][group_id] && _hashBalances[payer_address][group_id][denomination][obligor] == input[0] && payer_address != address(0) && denomination != address(0) && 0 < amount && amount <= IERC20(denomination).balanceOf(contract_address), "setup error");

            require(PoseidonT2.hash([amount]) == input[2], "incorrect amount");
            require(input[3] == sendNonce[payer_address][group_id],"Nonce don't match");

            require(_hashBalances[payer_address][group_id][denomination][obligor] == input[0],"initial balances don't match");

            require(payer_address != address(0) && denomination != address(0), "payer_address cannot be null"); 
            require(0 < amount && amount <= IERC20(denomination).balanceOf(contract_address), "amount must be less than or equal to contract balance");

            _hashBalances[payer_address][group_id][denomination][obligor] = input[1];
            
            if(obligor == address(0))
                IERC20(denomination).transfer(payer_address, amount);
            else
                require(ConfidentialAccessControl(accessControl).isTreasurer(payer_address, denomination), "Only Treasurer can deposit");
    }

    function createRequestMeta(
            address caller,
            uint256 group_id,
            CreateRequestMessage[] memory cr,
            address deal_address,
            uint256 deal_group_id,
            uint256 deal_id,
            bool agree
        ) 
        public
        {
            address sender  = accessControl == msg.sender ? caller : msg.sender;
            
            if(group_id > 0){
                require(group == msg.sender, "only group can call");
                sender = caller;
            }
                
            uint send_nonce = sendNonce[sender][group_id];
            for(uint i = 0; i < cr.length; i++){
                CreateRequestMessage memory cri = cr[i];
                address denomination = cri.denomination;
                uint[5] memory input_send = cri.input_send;

                require(cri.input_send[3] == send_nonce, "Nonce don't match");
                require(_hashBalances[sender][group_id][denomination][cri.obligor] == input_send[0], "initial balances don't match");
                require(cri.input_signature[0] == cri.input_send[2], "deal amounts don't match");
                
                SendVerifier(sendVerifier).requireSenderProof(cri.proof_send, input_send);                
                PaymentSignatureVerifier(paymentSignatureVerifierAddress).requireSignatureProof(cri.proof_signature, cri.input_signature);

                uint256 idHash = cri.input_signature[1];

                sendPool[idHash] = SendRequest(
                    idHash, sender, group_id,
                    denomination, cri.obligor, input_send[2], 
                    uint32(block.timestamp), 0, true, 
                    deal_address, deal_group_id, deal_id,
                    cri.oracle_address, cri.oracle_owner, 
                    cri.oracle_key_sender, cri.oracle_value_sender, 
                    cri.oracle_key_recipient, cri.oracle_value_recipient, 
                    cri.unlock_sender, cri.unlock_receiver);
                
                sendPoolIndex[sender][group_id][deal_id][send_nonce] = idHash;
                _hashBalances[sender][group_id][denomination][cri.obligor] = input_send[1];
                
                send_nonce = send_nonce + 1;

                if(deal_id != 0){
                    require(ConfidentialDeal(deal_address).getDealByID(deal_id).expiry > block.timestamp, "deal cannot have expired when making a payment");
                    ConfidentialDeal(deal_address).addSendRequestMeta(sender, deal_id, cri.input_signature[1]);
                }

                uint256 receive_nonce = receiveNonce[deal_address][deal_group_id][deal_id];
                receivePoolIndex[deal_address][deal_group_id][deal_id][receive_nonce] = idHash;
                receiveNonce[deal_address][deal_group_id][deal_id] = receive_nonce + 1;
            }
            sendNonce[sender][group_id] = send_nonce;

            if(agree){
                require((sender == ConfidentialDeal(deal_address).getDealByID(deal_id).counterpart), "only the owner can agree");
                
                ConfidentialDeal(deal_address).acceptMeta(sender, deal_id);
            }
    }

    function acceptRequestMeta(
            address caller,
            uint256 idHash,
            bytes calldata proof,
            uint[3] memory input
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
            require(sr.active, "Transfer request is not active");
            require(_hashBalances[checkAddress][sr.deal_group_id][denomination][sr.obligor] == 0 ? (input[2] == input[1]) : (_hashBalances[checkAddress][sr.deal_group_id][denomination][sr.obligor] == input[0]), "Initial amounts don't match");
            require(amount_hash == input[2], "Amounts don't match");
            require(
                (
                    deal_id != 0 ? 
                    (IERC721(sr.deal_address).ownerOf(deal_id) == receiver || sr.sender == receiver || group == receiver)
                    : 
                    (sr.deal_address == receiver || sr.sender == receiver || group == receiver)
                )
            , "You are not the owner");

            if(receiver == sr.sender)
                require(sr.unlock_sender < block.timestamp, "sender unlock time is in the future");
                if(sr.oracle_address != address(0)){
                    uint oracle_value = ConfidentialOracle(sr.oracle_address).getValue(sr.oracle_owner, sr.oracle_key_sender);
                    require(sr.oracle_value_sender == oracle_value, "oracle sender values don't match");
                }
            else{
                require(sr.unlock_receiver < block.timestamp, "recipient unlock time is in the future");
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
    //         uint[5] memory input
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