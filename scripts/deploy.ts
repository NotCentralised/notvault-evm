import { ethers, config } from "hardhat";
import { metaMaskEncrypt, encryptedBySecret } from './utils';

import * as EthCrypto from "eth-crypto";

import * as metaEncryption from "@metamask/eth-sig-util";

import axios from 'axios';

const encrypt = async (pk_to: string, message: any) => {
  const payload = message;
  const encrypted = await EthCrypto.encryptWithPublicKey(pk_to, JSON.stringify(payload));
  return EthCrypto.cipher.stringify(encrypted);
}


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

  // {
  //   // Access MS Graph
  //   const fmData = new FormData();
  //   fmData.append('grant_type', 'client_credentials');
  //   fmData.append('client_id', 'b5b76856-e0b5-4093-b5cb-765ed78b48b0');
  //   fmData.append('client_secret', 'ask8Q~Nrx.EYvuxTnwyM29yG6HvGfDYcAI3JhcX6');
  //   fmData.append('scope', 'https://graph.microsoft.com/.default');

  //   const res = await axios.post(
  //     `https://login.microsoftonline.com/1580ea85-41b7-4ec8-8967-abfe2a0a8349/oauth2/v2.0/token`,
  //     fmData,
  //     {
  //         headers: {
  //             "Content-Type": `multipart/form-data`
  //         }
  //     }
  //   );
  //   console.log('------')
  //   console.log(res.data.access_token)

  // }
  // {
  //   // Access API
  //   const fmData = new FormData();
  //   fmData.append('grant_type', 'client_credentials');
  //   fmData.append('client_id', 'dd7e333c-8e56-4d1e-8a2c-bd041aa68696');
  //   fmData.append('client_secret', 'NbO8Q~5NUcvCn5KX4e6h5q-~CkAPjFMTFlTHcceu');
  //   fmData.append('scope', 'https://ncdevtenant.onmicrosoft.com/dd7e333c-8e56-4d1e-8a2c-bd041aa68696/.default');

  //   const res = await axios.post(
  //     `https://login.microsoftonline.com/1580ea85-41b7-4ec8-8967-abfe2a0a8349/oauth2/v2.0/token`,
  //     fmData,
  //     {
  //         headers: {
  //             "Content-Type": `multipart/form-data`
  //         }
  //     }
  //   );
  //   console.log('------')
  //   console.log(res.data.access_token)

  //   return
  // }
  // {
  //   const addrss = '0xd82A0f5B25f8de3Be1Bb21148b6e0C21261241cE';

  //   const provider = await ethers.getDefaultProvider('sepolia');
    
  //   const bal = ethers.utils.formatUnits(await provider.getBalance(addrss), "ether");
  //   console.log('-bal-', bal);

  //   const data = await provider.getFeeData();
  //   const gasAmount = BigInt('700000');
  //   console.log('gas data', {
  //     lastBaseFeePerGas: ethers.utils.formatUnits(data.lastBaseFeePerGas ?? 0, "gwei"),
  //     maxFeePerGas: ethers.utils.formatUnits(data.maxFeePerGas ?? 0, "gwei"),
  //     maxPriorityFeePerGas: ethers.utils.formatUnits(data.maxPriorityFeePerGas ?? 0, "gwei"),
  //     gasPrice: ethers.utils.formatUnits(data.gasPrice ?? 0, "gwei"),
  //   });
  //   if(data.gasPrice){
  //     console.log(data.gasPrice.toBigInt());
  //     console.log(ethers.utils.formatUnits(data.gasPrice.toBigInt() * gasAmount , "ether"));

  //     if(bal > ethers.utils.formatUnits(data.gasPrice.toBigInt() * gasAmount , "ether"))
  //       console.log('--B')
  //   }
  //   return;
  // }

  let start = Date.now();
  start = Date.now();

  const _owner = EthCrypto.createIdentity();
  
  const [owner] = await ethers.getSigners();
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

  const HashMinCommitmmentFactory = await ethers.getContractFactory("contracts/circuits/HashMinCommitmentVerifier.sol:Verifier");
  const hashMinCommitmentContract = await HashMinCommitmmentFactory.connect(owner).deploy();
  console.log('Deployed HashMinCommitmentVerifier: ', hashMinCommitmentContract.target);

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


  const WalletFactory = await ethers.getContractFactory("ConfidentialWallet");
  const VaultFactory = await ethers.getContractFactory("ConfidentialVault");
  const DealFactory = await ethers.getContractFactory("ConfidentialDeal");
  const OracleFactory = await ethers.getContractFactory("ConfidentialOracle");
  const ServiceBusFactory = await ethers.getContractFactory("ConfidentialServiceBus");
  
  
  const walletContract = await WalletFactory.connect(owner).deploy();
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
  
  const vaultContract = await VaultFactory.connect(owner).deploy(hashSenderContract.target, hashReceiverContract.target);
  // const vaultContract = await VaultFactory.connect(owner).deploy(hashSenderContract.target, hashReceiverContract.target, {gasLimit: 2n**20n-1n });
  console.log('Deployed VaultFactory: ', vaultContract.target);
  
  const dealContract = await DealFactory.connect(owner).deploy("ConfidentialDeal", "Deal", vaultContract.target, hashMinCommitmentContract.target);
  // const dealContract = await DealFactory.connect(owner).deploy("ConfidentialDeal", "Deal", vaultContract.target, hashMinCommitmentContract.target, {gasLimit: 2n**20n-1n });
  console.log('Deployed DealFactory: ', dealContract.target);
  
  const oracleContract = await OracleFactory.connect(owner).deploy(hashApproverContract.target);
  console.log('Deployed OracleFactory: ', oracleContract.target);

  const serviceBusContract = await ServiceBusFactory.connect(owner).deploy(hashApproverContract.target);
  console.log('Deployed ServiceBusFactory: ', serviceBusContract.target);


  console.log('Deploying Proxy')
  const total_supply_usdc = 1_000_000_000n * 10n ** 18n;
  const total_supply_weth = 1_000_000_000n * 10n ** 18n;
  const total_supply_wbtc = 1_000_000_000n * 10n ** 18n;
  const ProxyFactory = await ethers.getContractFactory("ProxyToken");
  const usdcContract = await ProxyFactory.connect(owner).deploy("USDC", "USDC", total_supply_usdc);
  const ethContract = await ProxyFactory.connect(owner).deploy("Wrapped ETH", "wETH", total_supply_weth);
  const btcContract = await ProxyFactory.connect(owner).deploy("Wrapped BTC", "wBTC", total_supply_wbtc);
  console.log('Deployed Done')

  
  console.log("Wallet: ", walletContract.target);
  console.log("Vault: ", vaultContract.target);
  console.log("Deal: ", dealContract.target);
  console.log("Oracle: ", oracleContract.target);
  console.log("ServiceBus: ", serviceBusContract.target);
  console.log("USDC: ", usdcContract.target);
  console.log("wETH: ", ethContract.target);
  console.log("wBTC: ", btcContract.target);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
