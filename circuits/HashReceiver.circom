/* 
 SPDX-License-Identifier: MIT
 Hash Receiver Circuit v0.9.969 (HashReceiver.circom)

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

template HashReceiver () {  
    /*
        Circuit that generates a token receiving proof ensuring the new balance is correct.
    */

    // Declaration of signals.  
    signal input amount;  
    signal input receiverBalanceBeforeTransfer;
    
    signal output receiverBalanceBeforeTransferHash;
    signal output receiverBalanceAfterTransferHash;
    signal output amountHash;

    // Ensure the amount being sent is greater than 0
    component comp1 = GreaterEqThan(252);
    comp1.in[0] <== amount;
    comp1.in[1] <== 0;
    comp1.out === 1;

    // Generate has of the amount
    component hashAmount = Poseidon(1);
    hashAmount.inputs[0] <== amount;
    amountHash <== hashAmount.out;

    // Generate hash of the balance prior to accepting send request
    component hashBeforeBalance = Poseidon(1);
    hashBeforeBalance.inputs[0] <== receiverBalanceBeforeTransfer;
    receiverBalanceBeforeTransferHash <== hashBeforeBalance.out;

    // Generate hash of the balance after the new tokens are accepted
    component hashAfterBalance = Poseidon(1);
    hashAfterBalance.inputs[0] <== receiverBalanceBeforeTransfer + amount;
    receiverBalanceAfterTransferHash <== hashAfterBalance.out;
}

component main = HashReceiver();