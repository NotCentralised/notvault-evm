/* 
 SPDX-License-Identifier: MIT
 Hash Sender Circuit v0.4.4 (HashSender.circom)

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
    signal input amount;  
    signal input nonce;

    signal output senderBalanceBeforeTransferHash;
    signal output senderBalanceAfterTransferHash;
    signal output amountHash;
    signal output nonceVerification;
    signal output idHash;

    nonceVerification <== nonce;
    
    component comp1 = GreaterEqThan(252);
    comp1.in[0] <== amount;
    comp1.in[1] <== 0;
    comp1.out === 1;

    component comp2 = GreaterEqThan(252);
    comp2.in[0] <== senderBalanceBeforeTransfer;
    comp2.in[1] <== amount;
    comp2.out === 1;

    component hashId = Poseidon(4);
    hashId.inputs[0] <== sender;
    hashId.inputs[1] <== senderBalanceBeforeTransfer;
    hashId.inputs[2] <== amount;
    hashId.inputs[3] <== nonce;
    idHash <== hashId.out;


    component hashAmount = Poseidon(1);
    hashAmount.inputs[0] <== amount;
    amountHash <== hashAmount.out;

    component hashBeforeBalance = Poseidon(1);
    hashBeforeBalance.inputs[0] <== senderBalanceBeforeTransfer;
    senderBalanceBeforeTransferHash <== hashBeforeBalance.out;

    component hashAfterBalance = Poseidon(1);
    hashAfterBalance.inputs[0] <== senderBalanceBeforeTransfer - amount;
    senderBalanceAfterTransferHash <== hashAfterBalance.out;
}

component main = HashSender();