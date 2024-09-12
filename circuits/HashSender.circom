/* 
 SPDX-License-Identifier: MIT
 Hash Sender Circuit v0.9.1769 (HashSender.circom)

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
    /*
        Circuit that generates a token sending proof ensuring:
            - amount being sent is less than or equal to the current balance
            - the new balance is correct
    */

    // Declaration of signals.  
    signal input sender;
    signal input senderBalanceBeforeTransfer;
    signal input nonce;

    signal input denomination;
    signal input obligor;
    signal input amount;
    signal input count;

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
    
    // sending amount greater than or equal to 0
    component comp1 = GreaterEqThan(252);
    comp1.in[0] <== amount * count;
    comp1.in[1] <== 0;
    comp1.out === 1;

    // current balance is greater than or equal to the sending amount
    component comp2 = GreaterEqThan(252);
    comp2.in[0] <== senderBalanceBeforeTransfer;
    comp2.in[1] <== amount * count;
    comp2.out === 1;

    // generating an id hash
    component hashId = Poseidon(7);
    hashId.inputs[0] <== denomination;
    hashId.inputs[1] <== obligor;
    hashId.inputs[2] <== amount;
    hashId.inputs[3] <== count;
    hashId.inputs[4] <== deal_address;
    hashId.inputs[5] <== deal_group_id;
    hashId.inputs[6] <== deal_id;
    idHash <== hashId.out;

    // hash of the amunt being sent
    component hashAmount = Poseidon(1);
    hashAmount.inputs[0] <== amount;
    amountHash <== hashAmount.out;

    // hash of the total amount
    component hashTotal = Poseidon(1);
    hashTotal.inputs[0] <== amount * count;
    totalHash <== hashTotal.out;

    // hash of balance before amount deduction
    component hashBeforeBalance = Poseidon(1);
    hashBeforeBalance.inputs[0] <== senderBalanceBeforeTransfer;
    senderBalanceBeforeTransferHash <== hashBeforeBalance.out;

    // hash of balance after amount deduction
    component hashAfterBalance = Poseidon(1);
    hashAfterBalance.inputs[0] <== senderBalanceBeforeTransfer - amount * count;
    senderBalanceAfterTransferHash <== hashAfterBalance.out;

    // hash of count
    component countAmount = Poseidon(1);
    countAmount.inputs[0] <== count;
    countHash <== countAmount.out;
}

component main = HashSender();