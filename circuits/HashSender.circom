/* 
 SPDX-License-Identifier: MIT
 Hash Sender Circuit v0.9.869 (HashSender.circom)

  _   _       _    _____           _             _ _              _ 
 | \ | |     | |  / ____|         | |           | (_)            | |
 |  \| | ___ | |_| |     ___ _ __ | |_ _ __ __ _| |_ ___  ___  __| |
 | . ` |/ _ \| __| |    / _ \ '_ \| __| '__/ _` | | / __|/ _ \/ _` |
 | |\  | (_) | |_| |___|  __/ | | | |_| | | (_| | | \__ \  __/ (_| |
 |_| \_|\___/ \__|\_____\___|_| |_|\__|_|  \__,_|_|_|___/\___|\__,_|
                                                                    
                                                                    
 Author: @NumbersDeFi 
*/

pragma circom 2.0.0;

include "../../node_modules/circomlib/circuits/poseidon.circom";
include "../../node_modules/circomlib/circuits/comparators.circom";

template HashSender () {  

    // Declaration of signals.  
    signal input sender;
    signal input senderBalanceBeforeTransfer;
    // signal input amount;  
    signal input nonce;

    signal input denomination;
    signal input obligor;
    signal input amount;
    signal input count;

    // signal input oracle_address;
    // signal input oracle_owner;
    
    // signal input oracle_key_sender;
    // signal input oracle_value_sender;
    // signal input oracle_key_recipient;
    // signal input oracle_value_recipient;
    
    // signal input unlock_sender;
    // signal input unlock_receiver;

    signal input deal_address;
    signal input deal_group_id;
    signal input deal_id;

    signal output senderBalanceBeforeTransferHash; //0
    signal output senderBalanceAfterTransferHash; //1
    signal output amountHash; //2
    signal output nonceVerification; //3
    signal output idHash; //4
    signal output totalHash; //5
    signal output countHash; //6

    nonceVerification <== nonce;
    
    component comp1 = GreaterEqThan(252);
    comp1.in[0] <== amount * count;
    comp1.in[1] <== 0;
    comp1.out === 1;

    component comp2 = GreaterEqThan(252);
    comp2.in[0] <== senderBalanceBeforeTransfer;
    comp2.in[1] <== amount * count;
    comp2.out === 1;

    // component hashId = Poseidon(4);
    // hashId.inputs[0] <== sender;
    // hashId.inputs[1] <== senderBalanceBeforeTransfer;
    // hashId.inputs[2] <== amount;
    // hashId.inputs[3] <== nonce;
    // idHash <== hashId.out;
    component hashId = Poseidon(7);
    hashId.inputs[0] <== denomination;
    hashId.inputs[1] <== obligor;
    hashId.inputs[2] <== amount;
    hashId.inputs[3] <== count;
    // hashId.inputs[4] <== oracle_address;
    // hashId.inputs[5] <== oracle_owner;
    // hashId.inputs[6] <== oracle_key_sender;
    // hashId.inputs[7] <== oracle_value_sender;
    // hashId.inputs[8] <== oracle_key_recipient;
    // hashId.inputs[9] <== oracle_value_recipient;
    // hashId.inputs[10] <== unlock_sender;
    // hashId.inputs[11] <== unlock_receiver;
    hashId.inputs[4] <== deal_address;
    hashId.inputs[5] <== deal_group_id;
    hashId.inputs[6] <== deal_id;
    idHash <== hashId.out;

    component hashAmount = Poseidon(1);
    hashAmount.inputs[0] <== amount;
    amountHash <== hashAmount.out;

    component hashTotal = Poseidon(1);
    hashTotal.inputs[0] <== amount * count;
    totalHash <== hashTotal.out;

    component hashBeforeBalance = Poseidon(1);
    hashBeforeBalance.inputs[0] <== senderBalanceBeforeTransfer;
    senderBalanceBeforeTransferHash <== hashBeforeBalance.out;

    component hashAfterBalance = Poseidon(1);
    hashAfterBalance.inputs[0] <== senderBalanceBeforeTransfer - amount * count;
    senderBalanceAfterTransferHash <== hashAfterBalance.out;

    component countAmount = Poseidon(1);
    countAmount.inputs[0] <== count;
    countHash <== countAmount.out;
}

component main = HashSender();