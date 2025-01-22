import { ethers, config } from "hardhat";
import { metaMaskEncrypt, encryptedBySecret, genApproverProof, textToBigInt, strToFeltArr } from './utils';

import * as EthCrypto from "eth-crypto";

import * as metaEncryption from "@metamask/eth-sig-util";

const encrypt = async (pk_to: string, message: any) => {
  const payload = message;
  const encrypted = await EthCrypto.encryptWithPublicKey(pk_to, JSON.stringify(payload));
  return EthCrypto.cipher.stringify(encrypted);
}

const main = async () => {

  let start = Date.now();
  start = Date.now();

  const _owner = EthCrypto.createIdentity();
  
  const [owner, treasurer] = await ethers.getSigners();
  console.log('Deploying with: ', owner.address);
  
  const HashSenderFactory = await ethers.getContractFactory("contracts/circuits/HashSenderVerifier.sol:Groth16Verifier");
  const hashSenderContract = await HashSenderFactory.connect(owner).deploy();
  console.log('Deployed HashSenderVerifier: ', hashSenderContract.target);

  const HashReceiverFactory = await ethers.getContractFactory("contracts/circuits/HashReceiverVerifier.sol:Groth16Verifier");
  const hashReceiverContract = await HashReceiverFactory.connect(owner).deploy();
  console.log('Deployed HashReceiverVerifier: ', hashReceiverContract.target);

  const HashApproverFactory = await ethers.getContractFactory("contracts/circuits/HashApproverVerifier.sol:Groth16Verifier");
  const hashApproverContract = await HashApproverFactory.connect(owner).deploy();
  console.log('Deployed HashApproverVerifier: ', hashApproverContract.target);

  const PaymentSignatureFactory = await ethers.getContractFactory("contracts/circuits/HashPaymentSignatureVerifier.sol:Groth16Verifier");
  const paymentSignatureContract = await PaymentSignatureFactory.connect(owner).deploy();
  console.log('Deployed HashPaymentSignatureVerifier: ', paymentSignatureContract.target);

  const AlphaNumericalFactory = await ethers.getContractFactory("contracts/circuits/AlphaNumericalDataVerifier.sol:Groth16Verifier");
  const alphaNumericalContract = await AlphaNumericalFactory.connect(owner).deploy();
  console.log('Deployed AlphaNumericalVerifier: ', alphaNumericalContract.target);

  const NumericalDataFactory = await ethers.getContractFactory("contracts/circuits/NumericalDataVerifier.sol:Groth16Verifier");
  const numericalDataContract = await NumericalDataFactory.connect(owner).deploy();
  console.log('Deployed NumericalDataVerifier: ', numericalDataContract.target);

  const TextDataFactory = await ethers.getContractFactory("contracts/circuits/TextDataVerifier.sol:Groth16Verifier");
  const textDataContract = await TextDataFactory.connect(owner).deploy();
  console.log('Deployed TextDataVerifier: ', textDataContract.target);

  const TextExpiryDataFactory = await ethers.getContractFactory("contracts/circuits/TextExpiryDataVerifier.sol:Groth16Verifier");
  const textExpiryDataContract = await TextExpiryDataFactory.connect(owner).deploy();
  console.log('Deployed TextExpiryDataVerifier: ', textExpiryDataContract.target);

  const PolicyFactory = await ethers.getContractFactory("contracts/circuits/PolicyVerifier.sol:Groth16Verifier");
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

  const VaultUtilFactory = await ethers.getContractFactory("Vault", { libraries: { PoseidonT2: hashLibraryContract.target } });
  const vaultUtilsContract = await VaultUtilFactory.connect(owner).deploy(accessControl.target, hashSenderContract.target, hashReceiverContract.target, paymentSignatureContract.target);
  console.log('Deployed VaultContract: ', vaultUtilsContract.target);


  console.log('Deploying Group')
  const groupFactory = await ethers.getContractFactory("ConfidentialGroup");
  const groupContract = await groupFactory.connect(owner).deploy(policyContract.target, alphaNumericalContract.target, accessControl.target);
  console.log('Deployed GroupFactory: ', groupContract.target);

  
  const walletContract = await WalletFactory.connect(owner).deploy(accessControl.target);
  console.log('Deployed WalletFactory:', walletContract.target);

  const ownerPrivateKey = process.env.OWNER_PRIVATE_KEY ?? '';
  
  let ownerPublicKey = metaEncryption.getEncryptionPublicKey(ownerPrivateKey);
  console.log('Using public key: ', ownerPublicKey);
  const secretKey = process.env.OWNER_SECRET ?? '';
  const encryptedSecret = metaMaskEncrypt(ownerPublicKey, secretKey);
  const encryptedPrivateKey = encryptedBySecret(_owner.privateKey, secretKey);
  let encryptedEmail = await encrypt(_owner.publicKey, process.env.OWNER_EMAIL ?? '');
  let hashedEmail = EthCrypto.hash.keccak256(process.env.OWNER_EMAIL ?? '');      
  await walletContract.connect(owner).registerKeys(_owner.publicKey, encryptedPrivateKey, encryptedSecret, hashedEmail, encryptedEmail);
  
  const vaultContract = await VaultFactory.connect(owner).deploy(accessControl.target, groupContract.target, vaultUtilsContract.target);
  console.log('Deployed VaultFactory: ', vaultContract.target);
  
  const dealContract = await DealFactory.connect(owner).deploy("ConfidentialDeal", "Deal", vaultContract.target, paymentSignatureContract.target, accessControl.target);

  console.log('Deployed DealFactory: ', dealContract.target);
  
  const oracleContract = await OracleFactory.connect(owner).deploy(hashApproverContract.target, accessControl.target);
  console.log('Deployed OracleFactory: ', oracleContract.target);

  const serviceBusContract = await ServiceBusFactory.connect(owner).deploy(hashApproverContract.target, accessControl.target);
  console.log('Deployed ServiceBusFactory: ', serviceBusContract.target);

  console.log('Deploying Treasury')
  const decimals = 2;
 
  const total_supply_weth = 0n;
  const total_supply_wbtc = 0n;
  const TreasuryFactory = await ethers.getContractFactory("ConfidentialTreasury");
  
  const cashContract = await TreasuryFactory.connect(owner).deploy("Hutly Cash", "HUT", total_supply_weth, decimals, accessControl.target);
  const shadowContract = await TreasuryFactory.connect(owner).deploy("Hutly Shadow", "sHUT", total_supply_wbtc, decimals, accessControl.target);

  const hut_secret = process.env.HUT_SECRET ?? '';
  const shut_secret = process.env.sHUT_SECRET ?? '';

  const proof_cash = await genApproverProof({key: cashContract.target, value: textToBigInt(hut_secret), salt: strToFeltArr('0') });
  const proof_shadow = await genApproverProof({key: shadowContract.target, value: textToBigInt(shut_secret), salt: strToFeltArr('0') });

  console.log('Adding HUT treasurer');
  const tx_cash_secret = await cashContract.connect(owner).addSecretMeta(owner.address, proof_cash.solidityProof, proof_cash.inputs, {gasLimit: 2747885 });
  console.log("tx_cash_secret: ", tx_cash_secret);

  console.log('Adding sHUT treasurer');
  const tx_shadow_secret = await shadowContract.connect(owner).addSecretMeta(owner.address, proof_shadow.solidityProof, proof_shadow.inputs, {gasLimit: 2747885 });
  console.log("tx_shadow_secret: ", tx_shadow_secret);
  

  console.log('Deployed Done')


  console.log("AccessControl: ", accessControl.target);
  console.log("Wallet: ", walletContract.target);
  console.log("Vault: ", vaultContract.target);
  console.log("Deal: ", dealContract.target);
  console.log("Oracle: ", oracleContract.target);
  console.log("Group: ", groupContract.target);
  console.log("ServiceBus: ", serviceBusContract.target);
  console.log("HUT: ", cashContract.target);
  console.log("sHUT: ", shadowContract.target);

  console.log({
    accessAddress:   accessControl.target,
    walletAddress:   walletContract.target,
    vaultAddress:    vaultContract.target,
    dealAddress:     dealContract.target,
    oracleAddress:   oracleContract.target,
    groupAddress:    groupContract.target,
    serviceAddress:  serviceBusContract.target
  })

  console.log({
    'HUT':          cashContract.target,
    'sHUT':         shadowContract.target
  })
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
