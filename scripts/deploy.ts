import { ethers, config } from "hardhat";
import { metaMaskEncrypt, encryptedBySecret, genApproverProof, textToBigInt } from './utils';

import * as EthCrypto from "eth-crypto";

import * as metaEncryption from "@metamask/eth-sig-util";

import axios from 'axios';

const encrypt = async (pk_to: string, message: any) => {
  const payload = message;
  const encrypted = await EthCrypto.encryptWithPublicKey(pk_to, JSON.stringify(payload));
  return EthCrypto.cipher.stringify(encrypted);
}

// Access     : Gas = 46,923
// Wallet     : Gas = 684,633
// Vault      : Gas = 5,439,384
// Deal       : Gas = 5,277,448
// Oracle     : Gas = 774,810
// ServiceBus : Gas = 816,453
// USDC       : Gas = 1,792,955
// ETH        : Gas = 1,793,039
// BTC        : Gas = 1,793,039


// API KEY
// test1
// Client ID: dd7e333c-8e56-4d1e-8a2c-bd041aa68696
// Value: XtS8Q~IGq6dtczp9Xqt3KjTTLYbQuFmIFWLxpaeD
// Secret ID: f54199ac-23ef-4a89-81af-ef4c1a152f7a


// main
// Client ID: b5b76856-e0b5-4093-b5cb-765ed78b48b0
// Value: ask8Q~Nrx.EYvuxTnwyM29yG6HvGfDYcAI3JhcX6
// Secret ID: c9b53b9b-5e9f-4648-bee7-ff9bc9182a25


// azure-function: api-gateway
// Client ID: dd7e333c-8e56-4d1e-8a2c-bd041aa68696
// Secret ID: af69fda9-52fb-41c1-862c-8d4a537c2a95
// Secret: Wsu8Q~HNK1i3AG-8h9fuHBaUvbkAZwyeZkT7IaFV

// spa-auth: api-gateway
// Client ID: 93f3fe31-4175-4953-a686-0253cf563b2e
// Secret ID: c986e68d-e0de-4cd4-b8d5-c5996f14b835
// Secret: zUm8Q~oSkz1wOo5mulpjGBPOwUG2ZF8JvY.KzaCc

const main = async () => {

  let start = Date.now();
  start = Date.now();

  const _owner = EthCrypto.createIdentity();
  
  const [owner, treasurer] = await ethers.getSigners();
  console.log('Deploying with: ', owner.address);
  
  const HashSenderFactory = await ethers.getContractFactory("contracts/circuits/HashSenderVerifier.sol:Verifier");
  const hashSenderContract = await HashSenderFactory.connect(owner).deploy();
  console.log('Deployed HashSenderVerifier: ', hashSenderContract.target);

  const HashReceiverFactory = await ethers.getContractFactory("contracts/circuits/HashReceiverVerifier.sol:Verifier");
  const hashReceiverContract = await HashReceiverFactory.connect(owner).deploy();
  console.log('Deployed HashReceiverVerifier: ', hashReceiverContract.target);

  const HashApproverFactory = await ethers.getContractFactory("contracts/circuits/HashApproverVerifier.sol:Verifier");
  const hashApproverContract = await HashApproverFactory.connect(owner).deploy();
  console.log('Deployed HashApproverVerifier: ', hashApproverContract.target);

  const PaymentSignatureFactory = await ethers.getContractFactory("contracts/circuits/HashPaymentSignatureVerifier.sol:Verifier");
  const paymentSignatureContract = await PaymentSignatureFactory.connect(owner).deploy();
  console.log('Deployed HashPaymentSignatureVerifier: ', paymentSignatureContract.target);

  const AlphaNumericalFactory = await ethers.getContractFactory("contracts/circuits/AlphaNumericalDataVerifier.sol:Verifier");
  const alphaNumericalContract = await AlphaNumericalFactory.connect(owner).deploy();
  console.log('Deployed AlphaNumericalVerifier: ', alphaNumericalContract.target);

  const NumericalDataFactory = await ethers.getContractFactory("contracts/circuits/NumericalDataVerifier.sol:Verifier");
  const numericalDataContract = await NumericalDataFactory.connect(owner).deploy();
  console.log('Deployed NumericalDataVerifier: ', numericalDataContract.target);

  const TextDataFactory = await ethers.getContractFactory("contracts/circuits/TextDataVerifier.sol:Verifier");
  const textDataContract = await TextDataFactory.connect(owner).deploy();
  console.log('Deployed TextDataVerifier: ', textDataContract.target);

  const TextExpiryDataFactory = await ethers.getContractFactory("contracts/circuits/TextExpiryDataVerifier.sol:Verifier");
  const textExpiryDataContract = await TextExpiryDataFactory.connect(owner).deploy();
  console.log('Deployed TextExpiryDataVerifier: ', textExpiryDataContract.target);

  const PolicyFactory = await ethers.getContractFactory("contracts/circuits/PolicyVerifier.sol:Verifier");
  const policyContract = await PolicyFactory.connect(owner).deploy();
  console.log('Deployed PolicyVerifier: ', policyContract.target);

  const HashLibraryFactory = await ethers.getContractFactory("PoseidonT2");
  const hashLibraryContract = await HashLibraryFactory.connect(owner).deploy();
  console.log('Deployed HashLibraryContract: ', hashLibraryContract.target);

  const WalletFactory = await ethers.getContractFactory("ConfidentialWallet");
  const VaultFactory = await ethers.getContractFactory("ConfidentialVault");
  const DealFactory = await ethers.getContractFactory("ConfidentialDeal");
  const OracleFactory = await ethers.getContractFactory("ConfidentialOracle");
  const ServiceBusFactory = await ethers.getContractFactory("ConfidentialServiceBus");

  console.log('Deploying Access Control')
  const accessControlFactory = await ethers.getContractFactory("ConfidentialAccessControl");
  const accessControl = await accessControlFactory.connect(owner).deploy(policyContract.target, alphaNumericalContract.target, hashApproverContract.target);

  const VaultUtilFactory = await ethers.getContractFactory("VaultUtils", { libraries: { PoseidonT2: hashLibraryContract.target } });
  const vaultUtilsContract = await VaultUtilFactory.connect(owner).deploy(accessControl.target, hashSenderContract.target, hashReceiverContract.target, paymentSignatureContract.target);
  console.log('Deployed VaultUtilsContract: ', vaultUtilsContract.target);


  console.log('Deploying Group')
  const groupFactory = await ethers.getContractFactory("ConfidentialGroup");
  const groupContract = await groupFactory.connect(owner).deploy(policyContract.target, alphaNumericalContract.target, accessControl.target);
  console.log('Deployed GroupFactory: ', groupContract.target);

  
  const walletContract = await WalletFactory.connect(owner).deploy(accessControl.target);
  console.log('Deployed WalletFactory:', walletContract.target);

  const ownerPrivateKey = 'ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80'
  
  let ownerPublicKey = metaEncryption.getEncryptionPublicKey(ownerPrivateKey);
  console.log('Using public key: ', ownerPublicKey);
  const secretKey = 'zk-super-secret';
  const encryptedSecret = metaMaskEncrypt(ownerPublicKey, secretKey);
  const encryptedPrivateKey = encryptedBySecret(_owner.privateKey, secretKey);
  let encryptedEmail = await encrypt(_owner.publicKey, "numbers@notcentralised.com");
  let hashedEmail = EthCrypto.hash.keccak256("numbers@notcentralised.com");      
  await walletContract.connect(owner).registerKeys(_owner.publicKey, encryptedPrivateKey, encryptedSecret, hashedEmail, encryptedEmail);
  // await walletContract.connect(owner).registerKeys(_owner.publicKey, encryptedPrivateKey, encryptedSecret, hashedEmail, encryptedEmail, {gasLimit: 2n**20n-1n });
  
  const vaultContract = await VaultFactory.connect(owner).deploy(accessControl.target, groupContract.target, vaultUtilsContract.target);
  // const vaultContract = await VaultFactory.connect(owner).deploy(hashSenderContract.target, hashReceiverContract.target, {gasLimit: 2n**20n-1n });
  console.log('Deployed VaultFactory: ', vaultContract.target);
  
  const dealContract = await DealFactory.connect(owner).deploy("ConfidentialDeal", "Deal", vaultContract.target, paymentSignatureContract.target, accessControl.target);
  // const dealContract = await DealFactory.connect(owner).deploy("ConfidentialDeal", "Deal", vaultContract.target, hashMinCommitmentContract.target, {gasLimit: 2n**20n-1n });
  console.log('Deployed DealFactory: ', dealContract.target);
  
  const oracleContract = await OracleFactory.connect(owner).deploy(hashApproverContract.target, accessControl.target);
  console.log('Deployed OracleFactory: ', oracleContract.target);

  const serviceBusContract = await ServiceBusFactory.connect(owner).deploy(hashApproverContract.target, accessControl.target);
  console.log('Deployed ServiceBusFactory: ', serviceBusContract.target);

  console.log('Deploying Treasury')
  const decimals = 2n;
  // const total_supply_usdc = 1_000_000_000n;// * 10n ** 2n;
  const total_supply_usdc = 1_000_000_000n;// * 10n ** 2n;
  const total_supply_weth = 0n;// * 10n ** 2n;
  const total_supply_wbtc = 0n;// * 10n ** 2n;
  const TreasuryFactory = await ethers.getContractFactory("ConfidentialTreasury");
  const usdcContract = await TreasuryFactory.connect(owner).deploy("Layer-C USDC", "LCUSDC", total_supply_usdc, decimals, accessControl.target);
  const cashContract = await TreasuryFactory.connect(owner).deploy("Layer-C Cash", "LCC", total_supply_weth, decimals, accessControl.target);
  const shadowContract = await TreasuryFactory.connect(owner).deploy("Layer-C Shadow", "LCS", total_supply_wbtc, decimals, accessControl.target);

  // const treasurerAddress = '0x554F0168a0234ad62E4B59131BEFA1E29Ed4c6c8';
  // const treasurerAddress = '0x04042Cda624b96051BEFA77dEC268F368461AAbb';

  const proof_usdc = await genApproverProof({key: usdcContract.target, value: textToBigInt("usdc") });
  const proof_cash = await genApproverProof({key: cashContract.target, value: textToBigInt("cash") });
  const proof_shadow = await genApproverProof({key: shadowContract.target, value: textToBigInt("shadow") });

  console.log('Adding USDC treasurer');
  await usdcContract.connect(owner).addSecretMeta(owner.address, proof_usdc.solidityProof, proof_usdc.inputs);
  console.log('Adding CASH treasurer');
  await cashContract.connect(owner).addSecretMeta(owner.address, proof_cash.solidityProof, proof_cash.inputs);
  console.log('Adding SHADOW treasurer');
  await shadowContract.connect(owner).addSecretMeta(owner.address, proof_shadow.solidityProof, proof_shadow.inputs);
  

  console.log('Deployed Done')


  console.log("AccessControl: ", accessControl.target);
  console.log("Wallet: ", walletContract.target);
  console.log("Vault: ", vaultContract.target);
  console.log("Deal: ", dealContract.target);
  console.log("Oracle: ", oracleContract.target);
  console.log("Group: ", groupContract.target);
  console.log("ServiceBus: ", serviceBusContract.target);
  console.log("USDC: ", usdcContract.target);
  console.log("CASH: ", cashContract.target);
  console.log("SHADOW: ", shadowContract.target);
  

  // const add = '0x574D1135a10E91006eC937eFD2b29FC5B99F18a0';

  // await usdcContract.connect(owner).approve(add, 10_000n);
  // await usdcContract.connect(owner).transfer(add, 10_000n);

  // await usdcContract.connect(owner).approve('0xad63a911B28419939c605B46F63a1a49B54F7643', 10_000n); // TENANT
  // await usdcContract.connect(owner).transfer('0xad63a911B28419939c605B46F63a1a49B54F7643', 10_000n); // TENANT

  // const tx = {
  //   to: add,
  //   value: ethers.parseEther("100.0"),
  // };
  // const transaction = await owner.sendTransaction(tx);
  // console.log("Transaction sent: ", transaction);
  // const receipt = await transaction.wait();
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
