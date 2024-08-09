/* 
 SPDX-License-Identifier: MIT
 General Policy Verification Circuit v0.9.669 (PolicyVerifier.circom)

  _   _       _    _____           _             _ _              _ 
 | \ | |     | |  / ____|         | |           | (_)            | |
 |  \| | ___ | |_| |     ___ _ __ | |_ _ __ __ _| |_ ___  ___  __| |
 | . ` |/ _ \| __| |    / _ \ '_ \| __| '__/ _` | | / __|/ _ \/ _` |
 | |\  | (_) | |_| |___|  __/ | | | |_| | | (_| | | \__ \  __/ (_| |
 |_| \_|\___/ \__|\_____\___|_| |_|\__|_|  \__,_|_|_|___/\___|\__,_|
                                                                    
                                                                    
 Author: @NumbersDeFi 
*/

pragma circom 2.0.0;

include "../../node_modules/circomlib/circuits/comparators.circom";
include "../../node_modules/circomlib/circuits/poseidon.circom";

template Policy() {

    signal input group_id;
    signal input amount;
    signal input upper;
    signal input lower;

    signal input start;
    signal input expiry;
    signal input max_use;

    signal input deal_address;
    signal input deal_group_id;
    signal input deal_id;

    signal output idHash;
    signal output amountHash;

    component comp_upper = GreaterEqThan(252);
    comp_upper.in[0] <== upper;
    comp_upper.in[1] <== amount;
    comp_upper.out === 1;

    component comp_lower = LessEqThan(252);
    comp_lower.in[0] <== lower;
    comp_lower.in[1] <== amount;
    comp_lower.out === 1;

    component idHasher = Poseidon(8);
    idHasher.inputs[0] <== start;
    idHasher.inputs[1] <== expiry;
    idHasher.inputs[2] <== max_use;
    idHasher.inputs[3] <== upper;
    idHasher.inputs[4] <== lower;
    idHasher.inputs[5] <== deal_address;
    idHasher.inputs[6] <== deal_group_id;
    idHasher.inputs[7] <== deal_id;
    idHash <== idHasher.out;

    component amountHasher = Poseidon(1);
    amountHasher.inputs[0] <== amount;
    amountHash <== amountHasher.out;
}

component main = Policy();



