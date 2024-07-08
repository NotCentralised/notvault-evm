import { expect } from "chai";
import { ethers } from "hardhat";
import { BaseContract } from 'ethers';
import { getPrivateBalance, depositAmount, sendAmount, retreiveAmount, withdrawAmount, createDeal, sendToDeal } from '../scripts/utils';
import * as EthCrypto from "eth-crypto";

const {
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");


// describe("Privacy", function () {
//   // We define a fixture to reuse the same setup in every test.
//   // We use loadFixture to run this setup once, snapshot that state,
//   // and reset Hardhat Network to that snapshot in every test.

//   // let dealContract: BaseContract;
//   // let walletContract: BaseContract;
//   // let vaultContract: BaseContract;
//   // let tokenContract: BaseContract;
//   // let oracleContract: BaseContract;
//   let owner: any;
//   let token: any;
//   let account0: any;
//   let _owner: any;
//   let _account0: any;
//   let idHash1: any;
//   let idHash2: any;
//   let idHash3: any;

//   const total_supply = 1_000_000_000_000n * 10n ** 18n;

//   async function deployContracts() {
//     _owner = EthCrypto.createIdentity();
//     _account0 = EthCrypto.createIdentity();
//     [owner, account0] = await ethers.getSigners();

//     const HashSenderFactory = await ethers.getContractFactory("contracts/circuits/HashSenderVerifier.sol:Verifier");
//     const hashSenderContract = await HashSenderFactory.connect(owner).deploy();

//     const HashReceiverFactory = await ethers.getContractFactory("contracts/circuits/HashReceiverVerifier.sol:Verifier");
//     const hashReceiverContract = await HashReceiverFactory.connect(owner).deploy();

//     const HashApproverFactory = await ethers.getContractFactory("contracts/circuits/HashApproverVerifier.sol:Verifier");
//     const hashApproverContract = await HashApproverFactory.connect(owner).deploy();

//     const HashMinCommitmmentFactory = await ethers.getContractFactory("contracts/circuits/HashMinCommitmentVerifier.sol:Verifier");
//     const hashMinCommitmentContract = await HashMinCommitmmentFactory.connect(owner).deploy();
//     console.log('Deployed HashMinCommitmentVerifier: ', hashMinCommitmentContract.target);

//     const hashLibraryFactory = await ethers.getContractFactory("PoseidonT2");
//     const hashLibraryContract = await hashLibraryFactory.connect(owner).deploy();
//     console.log('Deployed hashLibraryContract: ', hashLibraryContract.target);


//     const WalletFactory = await ethers.getContractFactory("ConfidentialWallet");
//     const DealFactory = await ethers.getContractFactory("ConfidentialDeal");
//     const VaultFactory = await ethers.getContractFactory("ConfidentialVault", { libraries: { PoseidonT2: hashLibraryContract.target}});
//     const TokenFactory = await ethers.getContractFactory("ProxyToken");
//     const OracleFactory = await ethers.getContractFactory("ConfidentialOracle");

//     const walletContract = await WalletFactory.connect(owner).deploy();
//     console.log('Deployed walletContract: ', walletContract.target);
//     const vaultContract = await VaultFactory.connect(owner).deploy(hashSenderContract.target, hashReceiverContract.target);
//     console.log('Deployed vaultContract: ', vaultContract.target);
//     const dealContract = await DealFactory.connect(owner).deploy("Deal", "Deal", vaultContract.target, hashMinCommitmentContract.target);
//     console.log('Deployed dealContract: ', dealContract.target);
//     const oracleContract = await OracleFactory.connect(owner).deploy(hashApproverContract.target);
//     console.log('Deployed oracleContract: ', oracleContract.target);
//     const tokenContract = await TokenFactory.connect(owner).deploy("USDC", "USDC", total_supply);
//     console.log('Deployed tokenContract: ', tokenContract.target);
    
//     token = tokenContract.target;

//     const email0 = EthCrypto.hash.keccak256('numbers@notcentralised.com');
//     const email1 = EthCrypto.hash.keccak256('numbers@notcentralised.com');
//     await walletContract.connect(owner).registerKeys(_owner.publicKey, _owner.privateKey, _owner.privateKey, email0, email0);
//     await walletContract.connect(account0).registerKeys(_account0.publicKey, _account0.privateKey, _account0.privateKey, email1, email1);

//     return { dealContract, walletContract, vaultContract, tokenContract, oracleContract };
//   }

//   describe("Deposit", function () {
    
    
//     it("balances", async function () {
      
//       const { dealContract, walletContract, vaultContract, tokenContract, oracleContract } = await loadFixture(deployContracts)

//       const balanceOwner = await getPrivateBalance(walletContract, vaultContract.target, owner, token, _owner.privateKey);
//       const balanceAccount = await getPrivateBalance(walletContract, vaultContract.target, account0, token, _account0.privateKey);

//       expect(balanceOwner).to.be.equal(0n);
//       expect(balanceAccount).to.be.equal(0n);
//     });

//     it("deposit", async function () {

//       const { dealContract, walletContract, vaultContract, tokenContract, oracleContract } = await loadFixture(deployContracts)

//       await tokenContract.connect(owner).approve(vaultContract.target, total_supply);
//       await depositAmount(walletContract, vaultContract, owner, token, _owner.privateKey, total_supply);
//     });

//     it("balances", async function () {

//       const { dealContract, walletContract, vaultContract, tokenContract, oracleContract } = await loadFixture(deployContracts)

//       await tokenContract.connect(owner).approve(vaultContract.target, total_supply);
//       await depositAmount(walletContract, vaultContract, owner, token, _owner.privateKey, total_supply);

//       const balanceOwner = await getPrivateBalance(walletContract, vaultContract.target, owner, token, _owner.privateKey);
//       expect(balanceOwner).to.be.equal(total_supply);
//     });
//   });

//   describe("Withdraw", function () {
//     it("withdraw", async function () {
//       const { dealContract, walletContract, vaultContract, tokenContract, oracleContract } = await loadFixture(deployContracts)

//       await tokenContract.connect(owner).approve(vaultContract.target, total_supply);
//       await depositAmount(walletContract, vaultContract, owner, token, _owner.privateKey, total_supply);

//       const balanceOwnerBefore = await getPrivateBalance(walletContract, vaultContract.target, owner, token, _owner.privateKey);
      
//       await withdrawAmount(walletContract, vaultContract, owner, token, _owner.privateKey, 1n);
      
//       const balanceOwnerAfter = await getPrivateBalance(walletContract, vaultContract.target, owner, token, _owner.privateKey);

//       expect(balanceOwnerBefore).to.be.equal(balanceOwnerAfter + 1n);
//     });
//   });

//   describe("Send", function () {
//     it("balances", async function () {

//       const { dealContract, walletContract, vaultContract, tokenContract, oracleContract } = await loadFixture(deployContracts)

//       await tokenContract.connect(owner).approve(vaultContract.target, total_supply);
//       // await tokenContract.connect(owner).approve(walletContract.target, total_supply);
//       await depositAmount(walletContract, vaultContract, owner, token, _owner.privateKey, total_supply);

//       const balanceOwner = await getPrivateBalance(walletContract, vaultContract.target, owner, token, _owner.privateKey);
//       const balanceAccount = await getPrivateBalance(walletContract, vaultContract.target, account0, token, _account0.privateKey);

//       expect(balanceOwner).to.be.equal(total_supply);
//       expect(balanceAccount).to.be.equal(0n);
//     });

//     it("send 1", async function () {
//       const { dealContract, walletContract, vaultContract, tokenContract, oracleContract } = await loadFixture(deployContracts)

//       await tokenContract.connect(owner).approve(vaultContract.target, total_supply);
//       // await tokenContract.connect(owner).approve(walletContract.target, total_supply);
//       await depositAmount(walletContract, vaultContract, owner, token, _owner.privateKey, total_supply);

//       idHash1 = await sendAmount(walletContract, vaultContract, owner, account0.address, token, _owner.privateKey, _account0.publicKey, 1n);

//       const balanceOwner = await getPrivateBalance(walletContract, vaultContract.target, owner, token, _owner.privateKey);
//       const balanceAccount = await getPrivateBalance(walletContract, vaultContract.target, account0, token, _account0.privateKey);

//       expect(balanceOwner).to.be.equal(total_supply - 1n);
//       expect(balanceAccount).to.be.equal(0n);
//     });

//     it("send 10", async function () {
//       const { dealContract, walletContract, vaultContract, tokenContract, oracleContract } = await loadFixture(deployContracts)

//       await tokenContract.connect(owner).approve(vaultContract.target, total_supply);
//       // await tokenContract.connect(owner).approve(walletContract.target, total_supply);
//       await depositAmount(walletContract, vaultContract, owner, token, _owner.privateKey, total_supply);

//       idHash1 = await sendAmount(walletContract, vaultContract, owner, account0.address, token, _owner.privateKey, _account0.publicKey, 1n);
//       idHash2 = await sendAmount(walletContract, vaultContract, owner, account0.address, token, _owner.privateKey, _account0.publicKey, 10n);

//       const balanceOwner = await getPrivateBalance(walletContract, vaultContract.target, owner, token, _owner.privateKey);
//       const balanceAccount = await getPrivateBalance(walletContract, vaultContract.target, account0, token, _account0.privateKey);

//       expect(balanceOwner).to.be.equal(total_supply - 1n - 10n);
//       expect(balanceAccount).to.be.equal(0n);
//     });
//   });

//   describe("Retrieve", function () {
//     it("retreive 1", async function () {
//       const { dealContract, walletContract, vaultContract, tokenContract, oracleContract } = await loadFixture(deployContracts)

//       await tokenContract.connect(owner).approve(vaultContract.target, total_supply);
//       await depositAmount(walletContract, vaultContract, owner, token, _owner.privateKey, total_supply);

//       idHash1 = await sendAmount(walletContract, vaultContract, owner, account0.address, token, _owner.privateKey, _account0.publicKey, 1n);

//       await retreiveAmount(walletContract, vaultContract, idHash1, owner.address, account0, token, _account0.privateKey);

//       const balanceOwner = await getPrivateBalance(walletContract, vaultContract.target, owner, token, _owner.privateKey);
//       const balanceAccount = await getPrivateBalance(walletContract, vaultContract.target, account0, token, _account0.privateKey);
//       expect(balanceOwner).to.be.equal(total_supply - 1n);
//       expect(balanceAccount).to.be.equal(1n);
//     });

//     it("retreive again", async function () {
//       const { dealContract, walletContract, vaultContract, tokenContract, oracleContract } = await loadFixture(deployContracts)

//       await tokenContract.connect(owner).approve(vaultContract.target, total_supply);
//       await depositAmount(walletContract, vaultContract, owner, token, _owner.privateKey, total_supply);

//       idHash1 = await sendAmount(walletContract, vaultContract, owner, account0.address, token, _owner.privateKey, _account0.publicKey, 1n);
//       idHash2 = await sendAmount(walletContract, vaultContract, owner, account0.address, token, _owner.privateKey, _account0.publicKey, 10n);

//       await retreiveAmount(walletContract, vaultContract, idHash1, owner.address, account0, token, _account0.privateKey);
//       try{
//         await retreiveAmount(walletContract, vaultContract, idHash1, owner.address, account0, token, _account0.privateKey);
//       }
//       catch{
//         expect(1).to.be.equal(1);
//       }
//     });

//     it("retreive 10", async function () {
//       const { dealContract, walletContract, vaultContract, tokenContract, oracleContract } = await loadFixture(deployContracts)

//       await tokenContract.connect(owner).approve(vaultContract.target, total_supply);
//       await depositAmount(walletContract, vaultContract, owner, token, _owner.privateKey, total_supply);

//       idHash1 = await sendAmount(walletContract, vaultContract, owner, account0.address, token, _owner.privateKey, _account0.publicKey, 1n);
//       idHash2 = await sendAmount(walletContract, vaultContract, owner, account0.address, token, _owner.privateKey, _account0.publicKey, 10n);

//       await retreiveAmount(walletContract, vaultContract, idHash1, owner.address, account0, token, _account0.privateKey);
//       await retreiveAmount(walletContract, vaultContract, idHash2, owner.address, account0, token, _account0.privateKey);

//       const balanceOwner = await getPrivateBalance(walletContract, vaultContract.target, owner, token, _owner.privateKey);
//       const balanceAccount = await getPrivateBalance(walletContract, vaultContract.target, account0, token, _account0.privateKey);
//       expect(balanceOwner).to.be.equal(total_supply - 1n - 10n);
//       expect(balanceAccount).to.be.equal(11n);
//     });
//   });

//   describe("Deal", function () {
//     it("deal 1", async function () {
//       const { dealContract, walletContract, vaultContract, tokenContract, oracleContract } = await loadFixture(deployContracts)

//       await createDeal(dealContract, account0, owner, token);

//       await tokenContract.connect(owner).approve(vaultContract.target, total_supply);
//       await depositAmount(walletContract, vaultContract, owner, token, _owner.privateKey, total_supply);

//       let dealId = 1n;

//       idHash1 = await sendToDeal(walletContract, vaultContract, owner, account0.address, token, _owner.privateKey, _account0.publicKey, 1n, dealContract.target, dealId);
      
//       await retreiveAmount(walletContract, vaultContract, idHash1, owner.address, account0, token, _account0.privateKey);
      
//       const balanceOwner = await getPrivateBalance(walletContract, vaultContract.target, owner, token, _owner.privateKey);
//       const balanceAccount = await getPrivateBalance(walletContract, vaultContract.target, account0, token, _account0.privateKey);
//       expect(balanceOwner).to.be.equal(total_supply - 1n);
//       expect(balanceAccount).to.be.equal(1n);
//     });

//     it("deal transfer", async function () {
//       const { dealContract, walletContract, vaultContract, tokenContract, oracleContract } = await loadFixture(deployContracts)

//       await createDeal(dealContract, owner, owner, token);

//       await tokenContract.connect(owner).approve(vaultContract.target, total_supply);
//       await depositAmount(walletContract, vaultContract, owner, token, _owner.privateKey, total_supply);

//       let dealId = 1n;

//       idHash1 = await sendToDeal(walletContract, vaultContract, owner, account0.address, token, _owner.privateKey, _account0.publicKey, 1n, dealContract.target, dealId);

//       await dealContract.connect(owner).transferFrom(owner.address, account0.address, dealId)
      
//       await retreiveAmount(walletContract, vaultContract, idHash1, owner.address, account0, token, _account0.privateKey);
      
//       const balanceOwner = await getPrivateBalance(walletContract, vaultContract.target, owner, token, _owner.privateKey);
//       const balanceAccount = await getPrivateBalance(walletContract, vaultContract.target, account0, token, _account0.privateKey);
//       expect(balanceOwner).to.be.equal(total_supply - 1n);
//       expect(balanceAccount).to.be.equal(1n);
//     });
//   });

//   // describe("Send Back", function () {
//   //   it("send back 5", async function () {
//   //     idHash3 = await sendAmount(vaultContract, account0, token, _account0.privateKey, _owner.publicKey, 5n);

//   //     const balanceOwner = await getPrivateBalance(vaultContract, owner, token, _owner.privateKey);
//   //     const balanceAccount = await getPrivateBalance(vaultContract, account0, token, _account0.privateKey);

//   //     expect(balanceOwner).to.be.equal(total_supply - 1n - 10n);
//   //     expect(balanceAccount).to.be.equal(1n + 10n - 5n);
//   //   });

//   //   it("retreive back 5", async function () {
//   //     await retreiveAmount(vaultContract, idHash3, owner, token, _owner.privateKey, _account0.publicKey);

//   //     const balanceOwner = await getPrivateBalance(vaultContract, owner, token, _owner.privateKey);
//   //     const balanceAccount = await getPrivateBalance(vaultContract, account0, token, _account0.privateKey);

//   //     expect(balanceOwner).to.be.equal(total_supply - 1n - 10n + 5n);
//   //     expect(balanceAccount).to.be.equal(1n + 10n - 5n);
//   //   }); 
//   // });

//   // describe("Multiple breaks", function () {
//   //   it("send too much", async function () {
//   //     try{
//   //       await sendAmount(vaultContract, account0, token, _account0.privateKey, _owner.publicKey, 500n);
//   //     }
//   //     catch{
//   //       expect(1).to.be.equal(1);
//   //     }
//   //   });

//   //   it("break when retreive again 1", async function () {
//   //     try{
//   //       await retreiveAmount(vaultContract, idHash1, account0, token, _account0.privateKey, _owner.publicKey);
//   //     }
//   //     catch{
//   //       expect(1).to.be.equal(1);
//   //     }
//   //   });   
    
//   //   it("break when retreive again 2", async function () {
//   //     try{
//   //       await retreiveAmount(vaultContract, idHash2, account0, token, _account0.privateKey, _owner.publicKey);
//   //     }
//   //     catch{
//   //       expect(1).to.be.equal(1);
//   //     }
//   //   });   

//   //   it("break when retreive again 3", async function () {
//   //     try{
//   //       await retreiveAmount(vaultContract, idHash3, account0, token, _account0.privateKey, _owner.publicKey);
//   //     }
//   //     catch{
//   //       expect(1).to.be.equal(1);
//   //     }

//   //   });   




//   //   it("break when retreive again 4", async function () {
//   //     try{
//   //       await retreiveAmount(vaultContract, idHash1, owner, token, _owner.privateKey, _account0.publicKey);
//   //     }
//   //     catch{
//   //       expect(1).to.be.equal(1);
//   //     }
//   //   });   
    
//   //   it("break when retreive again 5", async function () {
//   //     try{
//   //       await retreiveAmount(vaultContract, idHash2, owner, token, _owner.privateKey, _account0.publicKey);
//   //     }
//   //     catch{
//   //       expect(1).to.be.equal(1);
//   //     }
//   //   });   

//   //   it("break when retreive again 6", async function () {
//   //     try{
//   //       await retreiveAmount(vaultContract, idHash3, owner, token, _owner.privateKey, _account0.publicKey);
//   //     }
//   //     catch{
//   //       expect(1).to.be.equal(1);
//   //     }
//   //   });   
//   // });
// });
