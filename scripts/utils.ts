import { ethers } from "hardhat";
import * as EthCrypto from "eth-crypto";
import * as fs from "fs";
import * as metaEncryption from "@metamask/eth-sig-util";

const snarkjs = require("snarkjs");
const CryptoJS = require("crypto-js");

(BigInt.prototype as any).toJSON = function () {
  return this.toString();
};

export const textToBigInt = (text: string): bigint => {
  // Convert each character to its ASCII code and concatenate the codes
  let result = '';
  
  for (const char of text) {
    // Get ASCII code of the character
    const asciiCode = char.charCodeAt(0);
    
    // Pad the ASCII code to ensure it has three digits (e.g., '097' for 'a')
    result += asciiCode.toString().padStart(3, '0');
  }

  // Convert the concatenated string of ASCII codes to a BigInt
  return BigInt(result);
}

export const encryptedBySecret = (data: any, secret: string) => CryptoJS.AES.encrypt(JSON.stringify(data), secret).toString();

export const decryptBySecret = (data: any, secret: string) =>  JSON.parse(CryptoJS.AES.decrypt(data , secret).toString(CryptoJS.enc.Utf8));

export const genApproverProof = async (input: any) => {
  const createWasm = './circuits/output/HashApprover_js/HashApprover.wasm'; // 1.6M
  const createZkey = './circuits/output/HashApprover_0001.zkey'; //222kb

  const { proof, publicSignals } = await makeProof(input, createWasm, createZkey);

  const solidityProof = proofToSolidityInput(proof);
  return {
      proof: proof,
      solidityProof: solidityProof,
      inputs: publicSignals,
  }
}


export const genReceiverProof = async (input: any) => {
  const createWasm = './circuits/output/HashReceiver_js/HashReceiver.wasm'; // 1.6M
  const createZkey = './circuits/output/HashReceiver_0001.zkey'; //222kb

  const { proof, publicSignals } = await makeProof(input, createWasm, createZkey);

  const solidityProof = proofToSolidityInput(proof);
  return {
      proof: proof,
      solidityProof: solidityProof,
      inputs: publicSignals,
  }
}

export const genSenderProof = async (input: any) => {
  const createWasm = './circuits/output/HashSender_js/HashSender.wasm' // 1.6M
  const createZkey = './circuits/output/HashSender_0001.zkey'; //222kb

  const { proof, publicSignals } = await makeProof(input, createWasm, createZkey);

  const solidityProof = proofToSolidityInput(proof);
  return {
      proof: proof,
      solidityProof: solidityProof,
      inputs: publicSignals,
  }
}

export const genMinCommittmentProof = async (input: any) => {
  const createWasm = './circuits/output/HashMinCommitment_js/HashMinCommitment.wasm' // 1.6M
  const createZkey = './circuits/output/HashMinCommitment_0001.zkey'; //222kb

  const { proof, publicSignals } = await makeProof(input, createWasm, createZkey);

  const solidityProof = proofToSolidityInput(proof);
  return {
      proof: proof,
      solidityProof: solidityProof,
      inputs: publicSignals,
  }
}

const makeProof = async (_proofInput: any, _wasm: string, _zkey: string) : Promise<{ proof: string, publicSignals: string[]}> => {
  const { proof, publicSignals } = await snarkjs.groth16.fullProve(_proofInput, _wasm, _zkey);
  return { proof, publicSignals };
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
  const hash_from = await ethers.utils.keccak256(from.target);
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

export const getPrivateBalance = async (walletContract: any, vault: any, account: any, token: any, privateKey: string) : Promise<bigint> => {
  // const privateBalance = await verifierContract.privateBalanceOf(account.address, token);
  const privateBalance = await walletContract.privateBalanceOf(vault, account.address, token);
  const balance = BigInt(privateBalance == '' ? '0' : await decrypt(privateKey, privateBalance));

  return balance;
}

export const depositAmount = async (walletContract: any, vaultContract: any, account: any, token:any, privateKey: string, amount: bigint) : Promise<void> => {

  const beforeBalance = await getPrivateBalance(walletContract, vaultContract.target, account, token, privateKey);

  const afterBalance = BigInt(beforeBalance) + BigInt(amount);
  let privatePublicKey = EthCrypto.publicKeyByPrivateKey(privateKey);

  const privateAfterBalance = await encrypt(privatePublicKey, afterBalance);
  const proofReceive = await genReceiverProof({ receiverBalanceBeforeTransfer: beforeBalance, amount: amount });
  await vaultContract.connect(account).deposit(token, amount, proofReceive.solidityProof, proofReceive.inputs);
  await walletContract
    .connect(account)
    .setPrivateBalance(
      vaultContract.target,
      token,
      privateAfterBalance
  );
}

export const withdrawAmount = async (walletContract: any, vaultContract: any, account: any, token:any, privateKey: string , amount: bigint) : Promise<string> => {
  const senderNonce = await vaultContract.getNonce(account.address);

  const beforeBalance = await getPrivateBalance(walletContract, vaultContract.target, account, token, privateKey);

  const afterBalance = BigInt(beforeBalance) - BigInt(amount);
  let privatePublicKey = EthCrypto.publicKeyByPrivateKey(privateKey);

  const privateAfterBalance = await encrypt(privatePublicKey, afterBalance);
  
  const proofSend1 = await genSenderProof({ sender: account.address, senderBalanceBeforeTransfer: beforeBalance, amount: amount, nonce: senderNonce });
  await vaultContract.connect(account).withdraw(token, amount, proofSend1.solidityProof, proofSend1.inputs);

  await walletContract
    .connect(account)
    .setPrivateBalance(
      vaultContract.target,
      token,
      privateAfterBalance
  );
  
  return proofSend1.inputs[4];
}

export const zeroAddress = '0x0000000000000000000000000000000000000000';

export const sendAmount = async (walletContract: any, vaultContract: any, account: any, recipient: any, token:any, privateKey: string, counterPublicKey: string , amount: bigint) : Promise<string> => {

  const senderNonce = await vaultContract.getNonce(account.address);

  const beforeBalance = await getPrivateBalance(walletContract, vaultContract.target, account, token, privateKey);

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
  const expiry = Math.floor(new Date('2024-06-16T00:00:00Z').getTime() / 1000);

  const proofSend = await genSenderProof({ sender: account.address, senderBalanceBeforeTransfer: beforeBalance, amount: amount, nonce: BigInt(senderNonce) });
  const proofAgree = await genMinCommittmentProof({ 
    amount: amount, minAmount: amount, oracle_owner: oracle_owner, 
    oracle_key_sender: oracle_key, oracle_value_sender: oracle_value, 
    oracle_key_recipient: oracle_key, oracle_value_recipient: oracle_value, 
    unlock_sender: unlock_sender, unlock_receiver: unlock_receiver,
    expiry: expiry });
  
  await vaultContract
    .connect(account)
    .createRequest([{ 
        recipient: recipient, 
        denomination: token, 
    
        deal_address: deal_address,
        deal_id: deal_id,

        oracle_address: oracle_address,
        oracle_owner: oracle_owner,
        oracle_key_sender: oracle_key,
        oracle_value_sender: oracle_value,
        oracle_key_recipient: oracle_key,
        oracle_value_recipient: oracle_value,
        
        unlock_sender: unlock_sender,
        unlock_receiver: unlock_receiver,
    
        // privateNewBalance: privateAfterBalance, 
        // privateSenderAmount: privateAmount_from, 
        // privateReceiverAmount: privateAmount_to,
    
        proof: proofSend.solidityProof, 
        input: proofSend.inputs,

        proof_agree: proofAgree.solidityProof, 
        input_agree: proofAgree.inputs
      }]);
  
  const idHash = proofSend.inputs[4];

  await walletContract
    .connect(account)
    .setPrivateBalance(
      vaultContract.target,
      token,
      privateAfterBalance
  );
  
  await walletContract
    .connect(account)
    .setPrivateAmount(
      vaultContract.target,
      account.address,
      idHash,
      privateAmount_from
  ); 

  await walletContract
    .connect(account)
    .setPrivateAmount(
      vaultContract.target,
      recipient,
      idHash,
      privateAmount_to
  );
  
  return idHash;
}

export const sendToDeal = async (walletContract: any, vaultContract: any, account: any, recipient: any, token:any, privateKey: string, counterPublicKey: string , amount: bigint, dealAddress: string, dealId: bigint) : Promise<string> => {

  const senderNonce = await vaultContract.getNonce(account.address);

  const beforeBalance = await getPrivateBalance(walletContract, vaultContract.target, account, token, privateKey);

  const afterBalance = BigInt(beforeBalance) - BigInt(amount);
  let privatePublicKey = EthCrypto.publicKeyByPrivateKey(privateKey);

  const privateAfterBalance = await encrypt(privatePublicKey, afterBalance);
  const privateAmount_from = await encrypt(privatePublicKey, amount);
  const privateAmount_to = await encrypt(counterPublicKey, amount);

  const deal_address = dealAddress;
  const deal_id = BigInt(dealId);
  const oracle_address = zeroAddress;
  const oracle_owner = zeroAddress;
  const oracle_key = 0;
  const oracle_value = 0;
  const unlock_sender = 0;
  const unlock_receiver = 0;
  const expiry = Math.floor(new Date('2024-06-16T00:00:00Z').getTime() / 1000);

  const proofSend = await genSenderProof({ sender: account.address, senderBalanceBeforeTransfer: beforeBalance, amount: amount, nonce: BigInt(senderNonce) });
  const proofAgree = await genMinCommittmentProof({ 
    amount: amount, minAmount: amount, oracle_owner: oracle_owner, 
    oracle_key_sender: oracle_key, oracle_value_sender: oracle_value, 
    oracle_key_recipient: oracle_key, oracle_value_recipient: oracle_value, 
    unlock_sender: unlock_sender, unlock_receiver: unlock_receiver,
    expiry: expiry });
  
  await vaultContract
    .connect(account)
    .createRequest([{ 
        recipient: recipient, 
        denomination: token, 
    
        deal_address: deal_address,
        deal_id: deal_id,
        
        oracle_address: oracle_address,
        oracle_owner: oracle_owner,
        oracle_key_sender: oracle_key,
        oracle_value_sender: oracle_value,
        oracle_key_recipient: oracle_key,
        oracle_value_recipient: oracle_value,
        
        unlock_sender: unlock_sender,
        unlock_receiver: unlock_receiver,
    
        // privateNewBalance: privateAfterBalance, 
        // privateSenderAmount: privateAmount_from, 
        // privateReceiverAmount: privateAmount_to,
    
        proof: proofSend.solidityProof, 
        input: proofSend.inputs,

        proof_agree: proofAgree.solidityProof, 
        input_agree: proofAgree.inputs
      }]);

  const idHash = proofSend.inputs[4];

  await walletContract
    .connect(account)
    .setPrivateBalance(
      vaultContract.target,
      token,
      privateAfterBalance
  );
  
  await walletContract
    .connect(account)
    .setPrivateAmount(
      vaultContract.target,
      account.address,
      idHash,
      privateAmount_from
  ); 

  await walletContract
    .connect(account)
    .setPrivateAmount(
      vaultContract.target,
      recipient,
      idHash,
      privateAmount_to
  );
  
  return idHash;
}

export const retreiveAmount = async (walletContract: any, vaultContract: any, idHash: string, source: any, account: any, token: any, privateKey: string) => {

  const beforeBalance = await getPrivateBalance(walletContract, vaultContract.target, account, token, privateKey);
  const privateAmount = await walletContract.privateAmountOf(source, vaultContract.target, account.address, idHash);

  const amount = BigInt(await decrypt(privateKey, privateAmount));

  let privatePublicKey = EthCrypto.publicKeyByPrivateKey(privateKey);

  const afterBalance = await encrypt(privatePublicKey, beforeBalance + amount);

  const proofReceive = await genReceiverProof({ receiverBalanceBeforeTransfer: beforeBalance, amount: amount });

  await vaultContract.connect(account).acceptRequest(idHash, proofReceive.solidityProof, proofReceive.inputs);
  await walletContract
    .connect(account)
    .setPrivateBalance(
      vaultContract.target,
      token,
      afterBalance
  );
}

export const createDeal = async (vault: any, owner: any, counterpart: any, token: any) => {
  let deal = {
    owner: owner.address,
    counterpart: counterpart.address,
    denomination: token.target,
    name: 'test',
    description: 'test',
    notional: 10n,
    initial: 1n,
    files: [],
    oracle_address: zeroAddress,
    oracle_owner: zeroAddress,
    oracle_key: 0n,
    oracle_value: 0n,
    oracle_value_secret: 0n,
    unlock_sender: 0,
    unlock_receiver: 0,
    expiry: Math.floor(new Date('2024-06-16T00:00:00Z').getTime() / 1000),
  }

  let dealPackage = JSON.stringify(deal);

  let cid = '';

  const proofAgree = await genMinCommittmentProof({ 
    amount: BigInt(deal.initial), minAmount: BigInt(deal.initial), oracle_owner: deal.oracle_owner, 
    
    oracle_key_sender: deal.oracle_key, oracle_value_sender: deal.oracle_value, 
    oracle_key_recipient: deal.oracle_key, oracle_value_recipient: deal.oracle_value, 
    
    unlock_sender: deal.unlock_sender, unlock_receiver: deal.unlock_receiver,
    expiry: deal.expiry });

  const tx = await vault.connect(owner).safeMint(counterpart.address, proofAgree.inputs[1], proofAgree.inputs[2], cid, Math.floor((new Date(2125,1,1)).getTime() / 1000));
  await tx.wait();
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
