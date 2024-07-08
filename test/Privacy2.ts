import { expect } from "chai";
import { ethers } from "hardhat";
import { BaseContract } from 'ethers';
import { getPrivateBalance, depositAmount, sendAmount, retreiveAmount, withdrawAmount, createDeal, sendToDeal } from '../scripts/utils';
import * as EthCrypto from "eth-crypto";

import { NotVault, contractsTable } from '@notcentralised/notvault-sdk';

const {
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");

describe("Privacy", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.

  // let dealContract: BaseContract;
  // let walletContract: BaseContract;
  // let vaultContract: BaseContract;
  // let tokenContract: BaseContract;
  // let oracleContract: BaseContract;
  let owner: any;
  let token: any;
  let account0: any;
  let _owner: any;
  let _account0: any;
  let idHash1: any;
  let idHash2: any;
  let idHash3: any;

  const total_supply = 1_000_000_000_000n * 10n ** 18n;

  async function deployContracts() {
    _owner = EthCrypto.createIdentity();
    _account0 = EthCrypto.createIdentity();
    [owner, account0] = await ethers.getSigners();

    const HashSenderFactory = await ethers.getContractFactory("contracts/circuits/HashSenderVerifier.sol:Verifier");
    const hashSenderContract = await HashSenderFactory.connect(owner).deploy();

    const HashReceiverFactory = await ethers.getContractFactory("contracts/circuits/HashReceiverVerifier.sol:Verifier");
    const hashReceiverContract = await HashReceiverFactory.connect(owner).deploy();

    const HashApproverFactory = await ethers.getContractFactory("contracts/circuits/HashApproverVerifier.sol:Verifier");
    const hashApproverContract = await HashApproverFactory.connect(owner).deploy();

    const PaymentSignatureFactory = await ethers.getContractFactory("contracts/circuits/PaymentSignatureVerifier.sol:Verifier");
    const paymentSignatureContract = await PaymentSignatureFactory.connect(owner).deploy();
    console.log('Deployed HashMinCommitmentVerifier: ', paymentSignatureContract.target);

    const hashLibraryFactory = await ethers.getContractFactory("PoseidonT2");
    const hashLibraryContract = await hashLibraryFactory.connect(owner).deploy();
    console.log('Deployed hashLibraryContract: ', hashLibraryContract.target);


    const WalletFactory = await ethers.getContractFactory("ConfidentialWallet");
    const DealFactory = await ethers.getContractFactory("ConfidentialDeal");
    const VaultFactory = await ethers.getContractFactory("ConfidentialVault", { libraries: { PoseidonT2: hashLibraryContract.target}});
    const TokenFactory = await ethers.getContractFactory("ProxyToken");
    const OracleFactory = await ethers.getContractFactory("ConfidentialOracle");

    const walletContract = await WalletFactory.connect(owner).deploy();
    console.log('Deployed walletContract: ', walletContract.target);
    const vaultContract = await VaultFactory.connect(owner).deploy(hashSenderContract.target, hashReceiverContract.target, paymentSignatureContract.target);
    console.log('Deployed vaultContract: ', vaultContract.target);
    const dealContract = await DealFactory.connect(owner).deploy("Deal", "Deal", vaultContract.target, paymentSignatureContract.target);
    console.log('Deployed dealContract: ', dealContract.target);
    const oracleContract = await OracleFactory.connect(owner).deploy(hashApproverContract.target);
    console.log('Deployed oracleContract: ', oracleContract.target);
    const tokenContract = await TokenFactory.connect(owner).deploy("USDC", "USDC", total_supply);
    console.log('Deployed tokenContract: ', tokenContract.target);
    
    token = tokenContract.target;

    const email0 = EthCrypto.hash.keccak256('numbers@notcentralised.com');
    const email1 = EthCrypto.hash.keccak256('numbers@notcentralised.com');
    await walletContract.connect(owner).registerKeys(_owner.publicKey, _owner.privateKey, _owner.privateKey, email0, email0);
    await walletContract.connect(account0).registerKeys(_account0.publicKey, _account0.privateKey, _account0.privateKey, email1, email1);


    const azure_functions_url = 'https://not-vault-functions.azurewebsites.net/api';
    const vault = new NotVault();
    console.log('---> ',owner)
    
    vault.init(
      '31337',
      undefined,
      {
        contracts: {           
          walletAddress:   walletContract.target.toString(),
          vaultAddress:    vaultContract.target.toString(),
          dealAddress:     dealContract.target.toString(),
          oracleAddress:   oracleContract.target.toString(),
          serviceAddress:  walletContract.target.toString()
        },
        proofs: Object.assign(
            {}, ...[
            { key: 'receiver', value: 'HashReceiver' }, 
            { key: 'sender', value: 'HashSender' }, 
            { key: 'approver', value: 'HashApprover' }, 
            { key: 'minCommitment', value: 'HashMinCommitment' }, 
            { key: 'textExpiryData', value: 'TextExpiryData' }, 
            { key: 'textData', value: 'TextData' }, 
            { key: 'numericalData', value: 'NumericalData' },
            { key: 'alphaNumericalData', value: 'AlphaNumericalData' } 
            ].map(element => ({
                [element.key]: {
                    key:    process.env.PUBLIC_URL + `/zkp/${element.value}_0001.zkey`,
                    wasm:   process.env.PUBLIC_URL + `/zkp/${element.value}.wasm`,
                    vkey:   process.env.PUBLIC_URL + `/zkp/${element.value}_verification_key.json`
                }
            }))),
        axios: {
            get: (cid: string) => { 
                return {
                    method: 'get',
                    // url: `${azure_functions_url}/Files?command=get&chainId=${x.chainId}&code=${process.env.AZURE_FUNCTION_KEY}&cid=${cid}`
                    url: `${azure_functions_url}/Files?command=get&chainId=${'31337'}&cid=${cid}`
                }
            },
            post: (fmData: FormData, onUploadProgress: any) => { 
                return {
                    method: 'post',
                    // url: `${azure_functions_url}/Files?command=upload&chainId=${x.chainId}&code=${process.env.AZURE_FUNCTION_KEY}`,
                    url: `${azure_functions_url}/Files?command=upload&chainId=${'31337'}`, 
                    data: fmData,
                    maxContentLength: Number.POSITIVE_INFINITY,
                    headers: {
                        "Content-Type": `multipart/form-data; boundery=${(fmData as any)._boundary}`,
                    },
                    onUploadProgress: onUploadProgress
                }
            },
            del: (cid: string) => { 
                return {
                    method: 'get',
                    // url: `${azure_functions_url}/Files?command=delete&chainId=${x.chainId}&code=${process.env.AZURE_FUNCTION_KEY}&cid=${cid}`
                    url: `${azure_functions_url}/Files?command=delete&chainId=${'31337'}&cid=${cid}`
                }
            }
        }
      }   
    );

    console.log(vault)
    

    return { dealContract, walletContract, vaultContract, tokenContract, oracleContract };
  }

  describe("Deposit", function () {
    it("balances", async function () {

      const { dealContract, walletContract, vaultContract, tokenContract, oracleContract } = await loadFixture(deployContracts)

      // const balanceOwner = await getPrivateBalance(walletContract, vaultContract.target, owner, token, _owner.privateKey);
      // const balanceAccount = await getPrivateBalance(walletContract, vaultContract.target, account0, token, _account0.privateKey);

      // expect(balanceOwner).to.be.equal(0n);
      // expect(balanceAccount).to.be.equal(0n);
    });
  });
});
