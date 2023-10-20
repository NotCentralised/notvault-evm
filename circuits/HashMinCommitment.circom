/* 
 SPDX-License-Identifier: MIT
 Hash Minimum Commitment Circuit v0.5.5 (HashMinCommitment.circom)

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

template HashMinCommitment() {  

    // Declaration of signals.  
    signal input amount;  
    signal input minAmount;
    signal input oracle_owner;
    signal input oracle_key;
    signal input oracle_value;
    signal input unlock_sender;
    signal input unlock_receiver;
    
    signal output amountHash;
    signal output minAmountHash;
    signal output idHash;

    component comp1 = GreaterEqThan(252);
    comp1.in[0] <== amount;
    comp1.in[1] <== minAmount;
    comp1.out === 1;

    component hashAmount = Poseidon(1);
    hashAmount.inputs[0] <== amount;
    amountHash <== hashAmount.out;

    component hashMinAmount = Poseidon(1);
    hashMinAmount.inputs[0] <== minAmount;
    minAmountHash <== hashMinAmount.out;

    component hashId = Poseidon(6);
    hashId.inputs[0] <== amount;
    hashId.inputs[1] <== oracle_owner;
    hashId.inputs[2] <== oracle_key;
    hashId.inputs[3] <== oracle_value;
    hashId.inputs[4] <== unlock_sender;
    hashId.inputs[5] <== unlock_receiver;
    idHash <== hashId.out;
}

component main = HashMinCommitment();