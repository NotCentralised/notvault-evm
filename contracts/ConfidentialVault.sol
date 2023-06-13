/* 
 SPDX-License-Identifier: MIT
 Confidential Vault Contract for Solidity v0.4.0 (ConfidentialVault.sol)

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

import "./circuits/IReceiveVerifier.sol";
import "./circuits/ISendVerifier.sol";

import "./ConfidentialWallet.sol";
import "./ConfidentialDeal.sol";
import "./ConfidentialOracle.sol";

struct CreateRequestMessage{
    address recipient;
    address denomination;

    address deal_address;
    uint256 deal_id;
    address oracle_address;
    address oracle_owner;
    uint256 oracle_key;
    uint256 oracle_value;
    uint    unlock_sender;
    uint    unlock_receiver;

    string  privateNewBalance;
    string  privateSenderAmount;
    string  privateReceiverAmount;

    bytes   proof;
    uint[5] input;

    bytes   proof_agree;
    uint[3] input_agree;
}

struct SendRequest{
    uint256 idHash;
    address sender;
    address recipient;
    address denomination;
    uint256 amount_hash;
    string  private_sender_amount;
    string  private_receiver_amount;
    uint    created;
    uint    redeemed;
    bool    active;

    address deal_address;
    uint256 deal_id;
    address oracle_address;
    address oracle_owner;
    uint256 oracle_key;
    uint256 oracle_value;
    uint    unlock_sender;
    uint    unlock_receiver;
}

contract ConfidentialVault {
    address sendVerifier;
    address receiveVerifier;
    mapping (address => mapping (address => uint256)) private _hashBalances;
    mapping (address => mapping (address => string)) private _privateBalances;
    
    mapping (address => uint256) sendNonce;
    mapping (address => uint256) receiveNonce;
    
    mapping (address => mapping (uint256 => uint256)) sendPoolIndex;
    mapping (address => mapping (uint256 => uint256)) receivePoolIndex;
    
    mapping (uint256 => SendRequest) sendPool;

    constructor(
        address _sendVerifier,
        address _receiveVerifier
        )
        {
            sendVerifier = _sendVerifier;
            receiveVerifier = _receiveVerifier;
    }

    function requireSenderProof(
            bytes memory _proof,
            uint[5] memory input
        ) internal view {
            uint256[8] memory p = abi.decode(_proof, (uint256[8]));
            require(
                SendVerifier(sendVerifier).verifyProof(
                    [p[0], p[1]],
                    [[p[2], p[3]], [p[4], p[5]]],
                    [p[6], p[7]],
                    input
            ),
            "Invalid sender (ZK)"
            );
    }

    function requireReceiverProof(
            bytes memory _proof,
            uint[3] memory input
        ) internal view {
            uint256[8] memory p = abi.decode(_proof, (uint256[8]));
            require(
                ReceiveVerifier(receiveVerifier).verifyProof(
                    [p[0], p[1]],
                    [[p[2], p[3]], [p[4], p[5]]],
                    [p[6], p[7]],
                    input
            ),
            "Invalid receiver (ZK)"
            );
    }

    function privateBalanceOf(
            address account,
            address denomination
        ) 
        public 
        view 
        returns (
            string memory
        ){  
            return _privateBalances[account][denomination]; 
    }

    function getSendRequestBySender(address account) public view returns (SendRequest[] memory) {
        SendRequest[] memory srs = new SendRequest[](sendNonce[account]);
        for(uint i = 0; i < sendNonce[account]; i++){
            srs[i] = sendPool[sendPoolIndex[account][i]];
        }
        return srs;
    }

    function getSendRequestByReceiver(address account) public view returns (SendRequest[] memory) {
        SendRequest[] memory srs = new SendRequest[](receiveNonce[account]);
        for(uint i = 0; i < receiveNonce[account]; i++){
            srs[i] = sendPool[receivePoolIndex[account][i]];
        }
        return srs;
    }

    function getSendRequest(uint256 idHash) public view returns (SendRequest memory) {
        return sendPool[idHash];
    }

    function getNonce(address account) public view returns (uint256) {
        return sendNonce[account];
    }

    // Deposit token
    function deposit(
            address denomination,
            uint256 amount,
            string memory privateNewBalance,
            bytes calldata proof,
            uint[3] memory input
        )
        public 
        payable
        {
            address payer_address = msg.sender;
            address payable contract_address = payable(address(this));
            uint256 allowance = IERC20(denomination).allowance(payer_address, contract_address);

            require(
                amount <= allowance,
                "amount must be less than or equal to allowance"
            );

            requireReceiverProof(proof, input);
            
            IERC20(denomination).transferFrom(payer_address, contract_address, amount);

            _hashBalances[payer_address][denomination] = input[1];
            _privateBalances[payer_address][denomination] = privateNewBalance;
    }

    // Withdraw token
    function withdraw(
            address         denomination,
            uint256         amount,
            string memory   privateNewBalance,
            bytes calldata  proof,
            uint[5] memory  input
        ) 
        public
        {
            address payer_address       = msg.sender;
            address contract_address    = address(this);

            input[3] = sendNonce[payer_address];
            requireSenderProof(proof, input);

            require(input[3] == sendNonce[payer_address], "Nonce don't match");
            require(_hashBalances[payer_address][denomination] == input[0], "initial balances don't match");

            uint256 contract_balance    = IERC20(denomination).balanceOf(contract_address);

            require(
                denomination != address(0),
                "base_address cannot be null"
            );

            require(
                payer_address != address(0),
                "payer_address cannot be null"
            );

            require(
                0 < contract_balance,
                "contract balance cannot be null"
            );

            require(
                amount <= contract_balance,
                "amount must be less than or equal to contract balance"
            );

            _hashBalances[payer_address][denomination] = input[1];
            _privateBalances[payer_address][denomination] = privateNewBalance;

            IERC20(denomination).transfer(payer_address, amount);
    }

    function createRequest(
            CreateRequestMessage[] memory cr
        ) 
        public
        {
            address sender = msg.sender;
            for(uint i = 0; i < cr.length; i++){
                cr[i].input[3] = sendNonce[sender];
                requireSenderProof(cr[i].proof, cr[i].input);
                
                require(cr[i].input[3] == sendNonce[sender], "Nonce don't match");

                uint256 idHash = cr[i].input[4];

                require(_hashBalances[sender][cr[i].denomination] == cr[i].input[0], "initial balances don't match");

                sendPoolIndex[sender][sendNonce[sender]] = idHash;
                receivePoolIndex[cr[i].recipient][receiveNonce[cr[i].recipient]] = idHash;
                sendPool[idHash] = SendRequest(idHash, sender, cr[i].recipient, cr[i].denomination, cr[i].input[2], cr[i].privateSenderAmount, cr[i].privateReceiverAmount, block.timestamp, 0, true, cr[i].deal_address, cr[i].deal_id, cr[i].oracle_address, cr[i].oracle_owner, cr[i].oracle_key, cr[i].oracle_value, cr[i].unlock_sender, cr[i].unlock_receiver);
                _hashBalances[sender][cr[i].denomination] = cr[i].input[1];
                _privateBalances[sender][cr[i].denomination] = cr[i].privateNewBalance;

                sendNonce[sender] = sendNonce[sender] + 1;
                receiveNonce[cr[i].recipient] = receiveNonce[cr[i].recipient] + 1;

                if(cr[i].deal_id != 0){
                    require(cr[i].input_agree[0] == cr[i].input[2], "deal amounts don't match");
                    ConfidentialDeal(cr[i].deal_address).addSendRequest(cr[i].deal_id, idHash);
                    ConfidentialDeal(cr[i].deal_address).accept(cr[i].deal_id, cr[i].proof_agree, cr[i].input_agree);
                }
            }
    }

    function acceptRequest(
            uint256 idHash,
            string memory privateNewBalance,
            bytes calldata proof,
            uint[3] memory input
        )
        public
        {
            address receiver = msg.sender;
            requireReceiverProof(proof, input);

            SendRequest memory sr = sendPool[idHash];
            require(sr.active && sr.amount_hash == input[2], "Transfer request is not active or the amounts don't match");

            if(_hashBalances[receiver][sr.denomination] == 0){
                require(input[2] == input[1], "initial balances don't match");
            }
            else{
                require(_hashBalances[receiver][sr.denomination] == input[0], "initial balances don't match");
            }

            if(receiver == sr.sender)
                require(sr.unlock_sender < block.timestamp, "unlock time is in the future");
            else{
                require(sr.unlock_receiver < block.timestamp, "unlock time is in the future");
                if(sr.oracle_address != address(0)){
                    uint oracle_value = ConfidentialOracle(sr.oracle_address).getValue(sr.oracle_owner, sr.oracle_key);
                    require(sr.oracle_value == oracle_value, "oracle values don't match");
                }
            }

            sendPool[idHash] = SendRequest(sr.idHash, sr.sender, sr.recipient, sr.denomination, sr.amount_hash, sr.private_sender_amount,sr.private_receiver_amount, sr.created, block.timestamp, false, sr.deal_address, sr.deal_id, sr.oracle_address, sr.oracle_owner, sr.oracle_key, sr.oracle_value, sr.unlock_sender, sr.unlock_receiver);

            _hashBalances[receiver][sr.denomination] = input[1];
            _privateBalances[receiver][sr.denomination] = privateNewBalance;
    }
}