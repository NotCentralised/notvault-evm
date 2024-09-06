/* 
 SPDX-License-Identifier: MIT
 Approver Oracle Circuit v0.9.1569 (HashApprover.circom)

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

template HashApprover () {  

    // Declaration of signals.  
    signal input key;
    signal input value;
    signal output hash;
    signal output keyOut;

    component hasher = Poseidon(2);
    hasher.inputs[0] <== key;
    hasher.inputs[1] <== value;
    hash <== hasher.out;

    keyOut <== key;

}

component main = HashApprover();