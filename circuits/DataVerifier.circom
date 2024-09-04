/* 
 SPDX-License-Identifier: MIT
 General Data Verification Circuit v0.9.1369 (DataVerifier.circom)

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
include "../../node_modules/circomlib/circuits/pedersen.circom";

template DataVerifier (tLevel, nLevel) {

    // max size = 68,719,476,735 (68.7b)
    var bitSize = 36;

    signal input data[tLevel + nLevel];
    signal input code[tLevel + nLevel];
    
    // Declaration of signals.  
    signal input constraint_upper[nLevel];
    signal input constraint_lower[nLevel];

    signal input salt[2];

    signal output idHash[2];
    signal output vIdHash[2];
    signal output constraintHash[2];

    component comp_upper[nLevel];
    component comp_lower[nLevel];

    for(var i = 0; i < nLevel; i++){
        comp_upper[i] = GreaterEqThan(bitSize);
        comp_upper[i].in[0] <== constraint_upper[i] * code[i];
        comp_upper[i].in[1] <== data[i] * code[i];
        comp_upper[i].out === 1;

        comp_lower[i] = LessEqThan(bitSize);
        comp_lower[i].in[0] <== constraint_lower[i] * code[i];
        comp_lower[i].in[1] <== data[i] * code[i];
        comp_lower[i].out === 1;
    }
    
    component hasher = Pedersen(tLevel + nLevel);    
    component chasher = Pedersen(tLevel);
    
    for(var i = 0; i < tLevel + nLevel; i++){
        hasher.in[i] <== data[i];
    }

    for(var i = nLevel; i < tLevel + nLevel; i++){
        chasher.in[i - nLevel] <== data[i] * code[i];
    }
    idHash <== hasher.out;
    constraintHash <== chasher.out;


    if(nLevel > 0){
        component nhasher = Pedersen(nLevel);
        for(var i = 0; i < nLevel; i++){
            nhasher.in[i] <== constraint_upper[i] - constraint_lower[i];        
        }
        var nhasher_out[2];
        nhasher_out = nhasher.out;

        component vhasher = Pedersen(6);
        vhasher.in[0] <== constraintHash[0];
        vhasher.in[1] <== constraintHash[1];
        vhasher.in[2] <== nhasher_out[0];
        vhasher.in[3] <== nhasher_out[1];
        vhasher.in[4] <== salt[0];
        vhasher.in[5] <== salt[1];

        vIdHash  <== vhasher.out;
    }
    else{
        component vhasher = Pedersen(4);
        vhasher.in[0] <== constraintHash[0];
        vhasher.in[1] <== constraintHash[1];
        vhasher.in[2] <== salt[0];
        vhasher.in[3] <== salt[1];

        vIdHash  <== vhasher.out;
    }    
}

// component main = DataVerifier(35, 100); char = 1,120
// component main = DataVerifier(350, 75); char = 11,200
// component main = DataVerifier(900, 50); char = 28,800
// component main = DataVerifier(1250, 25);char = 40,000
// component main = DataVerifier(1780, 1); char = 56,960
// component main = DataVerifier(1800, 0); char = 57,600





