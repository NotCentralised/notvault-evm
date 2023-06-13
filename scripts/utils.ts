import { ethers } from "hardhat";
import * as EthCrypto from "eth-crypto";
import * as fs from "fs";
import * as metaEncryption from "@metamask/eth-sig-util";

const snarkjs = require("snarkjs");
const CryptoJS = require("crypto-js");

(BigInt.prototype as any).toJSON = function () {
  return this.toString();
};

export const encryptedBySecret = (data: any, secret: string) => CryptoJS.AES.encrypt(JSON.stringify(data), secret).toString();

export const decryptBySecret = (data: any, secret: string) =>  JSON.parse(CryptoJS.AES.decrypt(data , secret).toString(CryptoJS.enc.Utf8));


export const genReceiverProof = async (input: any) => {
  const createWasm = './circuits/output/HashReceiver_js/HashReceiver.wasm'; // 1.6M
  const createWC = require('../circuits/output/HashReceiver_js/witness_calculator.js'); //9.0kb
  const WITNESS_FILE = './circuits/output/HashReceiver_witness.wtns'; //13kb
  const createZkey = './circuits/output/HashReceiver_0001.zkey'; //222kb

  const buffer = fs.readFileSync(createWasm);
  const witnessCalculator = await createWC(buffer);
  const buff = await witnessCalculator.calculateWTNSBin(input);
  // The package methods read from files only, so we just shove it in /tmp/ and hope
  // there is no parallel execution.
  fs.writeFileSync(WITNESS_FILE, buff);
  const { proof, publicSignals } = await snarkjs.groth16.prove(createZkey, WITNESS_FILE);
  const solidityProof = proofToSolidityInput(proof);
  return {
    solidityProof: solidityProof,
    inputs: publicSignals,
  }
}

export const genSenderProof = async (input: any) => {
  const createWasm = './circuits/output/HashSender_js/HashSender.wasm' // 1.6M
  const createWC = require('../circuits/output/HashSender_js/witness_calculator.js'); //9.0kb
  const WITNESS_FILE = './circuits/output/HashSender_witness.wtns'; //13kb
  const createZkey = './circuits/output/HashSender_0001.zkey'; //222kb

  const buffer = fs.readFileSync(createWasm);
  const witnessCalculator = await createWC(buffer);
  const buff = await witnessCalculator.calculateWTNSBin(input);
  // The package methods read from files only, so we just shove it in /tmp/ and hope
  // there is no parallel execution.
  fs.writeFileSync(WITNESS_FILE, buff);
  const { proof, publicSignals } = await snarkjs.groth16.prove(createZkey, WITNESS_FILE);
  const solidityProof = proofToSolidityInput(proof);
  return {
    solidityProof: solidityProof,
    inputs: publicSignals,
  }
}

const proofToSolidityInput = (proof: any): string => {
  const proofs: string[] = [
    proof.pi_a[0], proof.pi_a[1],
    proof.pi_b[0][1], proof.pi_b[0][0],
    proof.pi_b[1][1], proof.pi_b[1][0],
    proof.pi_c[0], proof.pi_c[1],
  ];
  const flatProofs = proofs.map(p => BigInt(p));
  return "0x" + flatProofs.map(x => toHex32(x)).join("")
}

const toHex32 = (num: BigInt) => {
  let str = num.toString(16);
  while (str.length < 64) str = "0" + str;
  return str;
}

export const encrypt = async (pk_to: string, message: any) => {
  const payload = message;
  const encrypted = await EthCrypto.encryptWithPublicKey(pk_to, JSON.stringify(payload));
  return EthCrypto.cipher.stringify(encrypted);
}
export const encryptSign = async (from: any, to: any, message: any) => {
  const hash_from = await ethers.utils.keccak256(from.address);
  const sig_from = await from.signMessage(ethers.utils.arrayify(hash_from));
  const pk_to = to.publicKey;
  const payload = {
      message: message,
      signature: sig_from
  };
  const encrypted = await EthCrypto.encryptWithPublicKey(pk_to, JSON.stringify(payload));
  return EthCrypto.cipher.stringify(encrypted);
}

export const decrypt = async (privateKey: string, message: any) => {
  const encryptedObject = EthCrypto.cipher.parse(message);

  const decrypted = await EthCrypto.decryptWithPrivateKey(
      privateKey,
      encryptedObject
  );

  const decryptedPayload = JSON.parse(decrypted);

  return decryptedPayload;
}

const decryptSigned = async (privateKey: any, message: any) => {
  const encryptedObject = EthCrypto.cipher.parse(message);

  const decrypted = await EthCrypto.decryptWithPrivateKey(
      privateKey,
      encryptedObject
  );

  const decryptedPayload = JSON.parse(decrypted);

  // check signature
  const senderAddress = EthCrypto.recover(
      decryptedPayload.signature,
      EthCrypto.hash.keccak256(decryptedPayload.message)
  );

  return {message: decryptedPayload, signer: senderAddress }
}

export const getPrivateBalance = async (verifierContract: any, account: any, token: any, privateKey: string) : Promise<bigint> => {
  const privateBalance = await verifierContract.privateBalanceOf(account.address, token);
  const balance = BigInt(privateBalance == '' ? '0' : await decrypt(privateKey, privateBalance));
  return balance;
}

export const depositAmount = async (verifierContract: any, account: any, token:any, privateKey: string, amount: bigint) : Promise<string> => {

  const beforeBalance = await getPrivateBalance(verifierContract, account, token, privateKey);

  const afterBalance = BigInt(beforeBalance) + BigInt(amount);
  let privatePublicKey = EthCrypto.publicKeyByPrivateKey(privateKey);

  const privateAfterBalance = await encrypt(privatePublicKey, afterBalance);
  const proofReceive = await genReceiverProof({ receiverBalanceBeforeTransfer: beforeBalance, amount: amount });
  return await verifierContract.connect(account).deposit(token, amount, privateAfterBalance, proofReceive.solidityProof, proofReceive.inputs);
}

export const withdrawAmount = async (verifierContract: any, account: any, token:any, privateKey: string , amount: bigint) : Promise<string> => {
  const senderNonce = await verifierContract.getNonce(account.address);

  const beforeBalance = await getPrivateBalance(verifierContract, account, token, privateKey);

  const afterBalance = BigInt(beforeBalance) - BigInt(amount);
  let privatePublicKey = EthCrypto.publicKeyByPrivateKey(privateKey);

  const privateAfterBalance = await encrypt(privatePublicKey, afterBalance);
  
  const proofSend1 = await genSenderProof({ sender: account.address, senderBalanceBeforeTransfer: beforeBalance, amount: amount, nonce: senderNonce });
  await verifierContract.connect(account).withdraw(token, amount, privateAfterBalance, proofSend1.solidityProof, proofSend1.inputs);
  
  return proofSend1.inputs[4];
}

export const zeroAddress = '0x0000000000000000000000000000000000000000';

export const sendAmount = async (verifierContract: any, account: any, token:any, privateKey: string, counterPublicKey: string , amount: bigint) : Promise<string> => {
  const senderNonce = await verifierContract.getNonce(account.address);

  const beforeBalance = await getPrivateBalance(verifierContract, account, token, privateKey);

  const afterBalance = BigInt(beforeBalance) - BigInt(amount);
  let privatePublicKey = EthCrypto.publicKeyByPrivateKey(privateKey);

  const privateAfterBalance = await encrypt(privatePublicKey, afterBalance);
  const privateAmount_from = await encrypt(privatePublicKey, amount);
  const privateAmount_to = await encrypt(counterPublicKey, amount);

  const deal_address = zeroAddress;
  const deal_id = BigInt(0);
  const oracle_address = zeroAddress;
  const oracle_owner = zeroAddress;
  const oracle_key = 0;
  const oracle_value = 0;
  const unlock_sender = 0;
  const unlock_receiver = 0;

  

  const proofSend = await genSenderProof({ sender: account.address, senderBalanceBeforeTransfer: beforeBalance, amount: amount, nonce: senderNonce });
  await verifierContract
    .connect(account)
    .createRequest([{ 
        recipient: account.address, 
        denomination: token, 
    
        deal_address: deal_address,
        deal_id: deal_id,
        oracle_address: oracle_address,
        oracle_owner: oracle_owner,
        oracle_key: oracle_key,
        oracle_value: oracle_value,
        unlock_sender: unlock_sender,
        unlock_receiver: unlock_receiver,
    
        privateNewBalance: privateAfterBalance, 
        privateSenderAmount: privateAmount_from, 
        privateReceiverAmount: privateAmount_to,
    
        proof: proofSend.solidityProof, 
        input: proofSend.inputs
      }]);
  
  return proofSend.inputs[4];
}

export const retreiveAmount = async (verifierContract: any, idHash: string, account: any, token: any, privateKey: string, counterPublicKey: string) => {

  const sendRequest = await verifierContract.getSendRequest(idHash);
  const beforeBalance = await getPrivateBalance(verifierContract, account, token, privateKey);
  
  const privateAmount = sendRequest.private_receiver_amount;
  const amount = BigInt(await decrypt(privateKey, privateAmount));
  let privatePublicKey = EthCrypto.publicKeyByPrivateKey(privateKey);

  const afterBalance = await encrypt(privatePublicKey, beforeBalance + amount);

  const proofReceive = await genReceiverProof({ receiverBalanceBeforeTransfer: beforeBalance, amount: amount });
  return await verifierContract.connect(account).acceptRequest(idHash, afterBalance, proofReceive.solidityProof, proofReceive.inputs);
}


export function metaMaskEncrypt(publicKey: string, data: string): string {
  // Returned object contains 4 properties: version, ephemPublicKey, nonce, ciphertext
  // Each contains data encoded using base64, version is always the same string
  const enc = metaEncryption.encrypt({
    publicKey: publicKey,//.toString('base64'),
    // data: ascii85.encode(data).toString(),
    data: data,
    version: 'x25519-xsalsa20-poly1305',
  });

  // We want to store the data in smart contract, therefore we concatenate them
  // into single Buffer
  const buf = Buffer.concat([
    Buffer.from(enc.ephemPublicKey, 'base64'),
    Buffer.from(enc.nonce, 'base64'),
    Buffer.from(enc.ciphertext, 'base64'),
  ]);
  
  // In smart contract we are using `bytes[112]` variable (fixed size byte array)
  // you might need to use `bytes` type for dynamic sized array
  // We are also using ethers.js which requires type `number[]` when passing data
  // for argument of type `bytes` to the smart contract function
  // Next line just converts the buffer to `number[]` required by contract function
  // THIS LINE IS USED IN OUR ORIGINAL CODE:
  // return buf.toJSON().data;
  
  // Return just the Buffer to make the function directly compatible with decryptData function
  return buf.toString('base64');
  // return buf.toString();
}
