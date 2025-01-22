/* 
 SPDX-License-Identifier: MIT
 Hash Payment Signature Circuit v0.9.9969 (HashPaymentSignature.circom)

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

template HashPaymentSignature() {  

    // Declaration of signals.  
    signal input denomination;
    signal input obligor;
    signal input amount;  
    signal input count;
    
    signal input deal_address;
    signal input deal_group_id;
    signal input deal_id;
    
    signal output amountHash;
    signal output idHash;

    component hashAmount = Poseidon(1);
    hashAmount.inputs[0] <== amount;
    amountHash <== hashAmount.out;

    component hashId = Poseidon(7);
    hashId.inputs[0] <== denomination;
    hashId.inputs[1] <== obligor;
    hashId.inputs[2] <== amount;
    hashId.inputs[3] <== count;
    hashId.inputs[4] <== deal_address;
    hashId.inputs[5] <== deal_group_id;
    hashId.inputs[6] <== deal_id;
    idHash <== hashId.out;
}

component main = HashPaymentSignature();