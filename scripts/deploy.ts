import { ethers, config } from "hardhat";
import { metaMaskEncrypt, encryptedBySecret } from './utils';

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
  
  const [owner] = await ethers.getSigners();
  console.log('Deploying with: ', owner.address);
  
  const HashSenderFactory = await ethers.getContractFactory("contracts/circuits/HashSenderVerifier.sol:Verifier");
  const hashSenderContract = await HashSenderFactory.connect(owner).deploy();
  console.log('Deployed HashSenderVerifier: ', hashSenderContract.address);

  const HashReceiverFactory = await ethers.getContractFactory("contracts/circuits/HashReceiverVerifier.sol:Verifier");
  const hashReceiverContract = await HashReceiverFactory.connect(owner).deploy();
  console.log('Deployed HashReceiverVerifier: ', hashReceiverContract.address);

  const HashApproverFactory = await ethers.getContractFactory("contracts/circuits/HashApproverVerifier.sol:Verifier");
  const hashApproverContract = await HashApproverFactory.connect(owner).deploy();
  console.log('Deployed HashApproverVerifier: ', hashApproverContract.address);

  const HashMinCommitmmentFactory = await ethers.getContractFactory("contracts/circuits/HashMinCommitmentVerifier.sol:Verifier");
  const hashMinCommitmentContract = await HashMinCommitmmentFactory.connect(owner).deploy();
  console.log('Deployed HashMinCommitmentVerifier: ', hashMinCommitmentContract.address);

  const AlphaNumericalFactory = await ethers.getContractFactory("contracts/circuits/AlphaNumericalDataVerifier.sol:Verifier");
  const alphaNumericalContract = await AlphaNumericalFactory.connect(owner).deploy();
  console.log('Deployed AlphaNumericalVerifier: ', alphaNumericalContract.address);

  const NumericalDataFactory = await ethers.getContractFactory("contracts/circuits/NumericalDataVerifier.sol:Verifier");
  const numericalDataContract = await NumericalDataFactory.connect(owner).deploy();
  console.log('Deployed NumericalDataVerifier: ', numericalDataContract.address);

  const TextDataFactory = await ethers.getContractFactory("contracts/circuits/TextDataVerifier.sol:Verifier");
  const textDataContract = await TextDataFactory.connect(owner).deploy();
  console.log('Deployed TextDataVerifier: ', textDataContract.address);

  const TextExpiryDataFactory = await ethers.getContractFactory("contracts/circuits/TextExpiryDataVerifier.sol:Verifier");
  const textExpiryDataContract = await TextExpiryDataFactory.connect(owner).deploy();
  console.log('Deployed TextExpiryDataVerifier: ', textExpiryDataContract.address);


  const WalletFactory = await ethers.getContractFactory("ConfidentialWallet");
  const VaultFactory = await ethers.getContractFactory("ConfidentialVault");
  const DealFactory = await ethers.getContractFactory("ConfidentialDeal");
  const OracleFactory = await ethers.getContractFactory("ConfidentialOracle");
  
  
  const walletContract = await WalletFactory.connect(owner).deploy();
  console.log('Deployed WalletFactory:', walletContract.address);

  const accounts = config.networks.hardhat.accounts;
  const index = 0; // first wallet, increment for next wallets
  const _privateKey = (ethers.Wallet.fromMnemonic((accounts as any).mnemonic, (accounts as any).path + `/${index}`)).privateKey
  const ownerPrivateKey = _privateKey.substring(2,_privateKey.length);  
  
  
  let ownerPublicKey = metaEncryption.getEncryptionPublicKey(ownerPrivateKey);
  console.log('Using public key: ', ownerPublicKey);
  const secretKey = 'zk-secret';
  const encryptedSecret = metaMaskEncrypt(ownerPublicKey, secretKey);
  const encryptedPrivateKey = encryptedBySecret(_owner.privateKey, secretKey);
  let encryptedEmail = await encrypt(_owner.publicKey, "numbers@notcentralised.com");
  let hashedEmail = EthCrypto.hash.keccak256("numbers@notcentralised.com");      
  await walletContract.connect(owner).registerKeys(_owner.publicKey, encryptedPrivateKey, encryptedSecret, hashedEmail, encryptedEmail);
  // await walletContract.connect(owner).registerKeys(_owner.publicKey, encryptedPrivateKey, encryptedSecret, hashedEmail, encryptedEmail, {gasLimit: 2n**20n-1n });
  
  const vaultContract = await VaultFactory.connect(owner).deploy(hashSenderContract.address, hashReceiverContract.address);
  // const vaultContract = await VaultFactory.connect(owner).deploy(hashSenderContract.address, hashReceiverContract.address, {gasLimit: 2n**20n-1n });
  console.log('Deployed VaultFactory: ', vaultContract.address);
  
  const dealContract = await DealFactory.connect(owner).deploy("ConfidentialDeal", "Deal", vaultContract.address, hashMinCommitmentContract.address);
  // const dealContract = await DealFactory.connect(owner).deploy("ConfidentialDeal", "Deal", vaultContract.address, hashMinCommitmentContract.address, {gasLimit: 2n**20n-1n });
  console.log('Deployed DealFactory: ', dealContract.address);
  
  const oracleContract = await OracleFactory.connect(owner).deploy(hashApproverContract.address);
  console.log('Deployed OracleFactory: ', oracleContract.address);

  console.log('Deploying Proxy')
  const total_supply_usdc = 1_000_000_000n * 10n ** 18n;
  const total_supply_weth = 1_000_000_000n * 10n ** 18n;
  const total_supply_wbtc = 1_000_000_000n * 10n ** 18n;
  const ProxyFactory = await ethers.getContractFactory("ProxyToken");
  const usdcContract = await ProxyFactory.connect(owner).deploy("USDC", "USDC", total_supply_usdc);
  const ethContract = await ProxyFactory.connect(owner).deploy("Wrapped ETH", "wETH", total_supply_weth);
  const btcContract = await ProxyFactory.connect(owner).deploy("Wrapped BTC", "wBTC", total_supply_wbtc);
  console.log('Deployed Done')

  
  console.log("Wallet: ", walletContract.address);
  console.log("Vault: ", vaultContract.address);
  console.log("Deal: ", dealContract.address);
  console.log("Oracle: ", oracleContract.address);
  console.log("USDC: ", usdcContract.address);
  console.log("wETH: ", ethContract.address);
  console.log("wBTC: ", btcContract.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
