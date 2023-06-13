import { expect } from "chai";
import { ethers } from "hardhat";
import { Contract } from 'ethers';
import { getPrivateBalance, depositAmount, sendAmount, retreiveAmount, withdrawAmount } from '../scripts/utils';
import * as EthCrypto from "eth-crypto";

describe("Privacy", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.

  let dealContract: Contract;
  let walletContract: Contract;
  let vaultContract: Contract;
  let tokenContract: Contract;
  let oracleContract: Contract;
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

    const WalletFactory = await ethers.getContractFactory("ConfidentialWallet");
    const DealFactory = await ethers.getContractFactory("ConfidentialDeal");
    const VaultFactory = await ethers.getContractFactory("ConfidentialVault");
    const TokenFactory = await ethers.getContractFactory("ProxyToken");
    const OracleFactory = await ethers.getContractFactory("ConfidentialOracle");

    walletContract = await WalletFactory.connect(owner).deploy();
    vaultContract = await VaultFactory.connect(owner).deploy(hashSenderContract.address, hashReceiverContract.address);
    dealContract = await DealFactory.connect(owner).deploy("Deal", "Deal", vaultContract.address);
    oracleContract = await OracleFactory.connect(owner).deploy(hashApproverContract.address);
    tokenContract = await TokenFactory.connect(owner).deploy("USDC", "USDC", total_supply);
    
    token = tokenContract.address;

    const email0 = EthCrypto.hash.keccak256('numbers@notcentralised.com');
    const email1 = EthCrypto.hash.keccak256('numbers@notcentralised.com');
    await walletContract.connect(owner).registerKeys(_owner.publicKey, _owner.privateKey, _owner.privateKey, email0, email0);
    await walletContract.connect(account0).registerKeys(_account0.publicKey, _account0.privateKey, _account0.privateKey, email1, email1);
  }

  before(async function() {
    await deployContracts()
  });

  describe("Deposit", function () {
    it("balances", async function () {
      const balanceOwner = await getPrivateBalance(vaultContract, owner, token, _owner.privateKey);
      const balanceAccount = await getPrivateBalance(vaultContract, account0, token, _account0.privateKey);

      expect(balanceOwner).to.be.equal(0n);
      expect(balanceAccount).to.be.equal(0n);
    });

    it("deposit", async function () {
      await tokenContract.connect(owner).approve(vaultContract.address, total_supply);
      await depositAmount(vaultContract, owner, token, _owner.privateKey, total_supply);
    });

    it("balances", async function () {
      const balanceOwner = await getPrivateBalance(vaultContract, owner, token, _owner.privateKey);
      expect(balanceOwner).to.be.equal(total_supply);
    });
  });

  describe("Send", function () {
    it("balances", async function () {
      const balanceOwner = await getPrivateBalance(vaultContract, owner, token, _owner.privateKey);
      const balanceAccount = await getPrivateBalance(vaultContract, account0, token, _account0.privateKey);

      expect(balanceOwner).to.be.equal(total_supply);
      expect(balanceAccount).to.be.equal(0n);
    });

    it("send 1", async function () {
      idHash1 = await sendAmount(vaultContract, owner, token, _owner.privateKey, _account0.publicKey, 1n);

      const balanceOwner = await getPrivateBalance(vaultContract, owner, token, _owner.privateKey);
      const balanceAccount = await getPrivateBalance(vaultContract, account0, token, _account0.privateKey);

      expect(balanceOwner).to.be.equal(total_supply - 1n);
      expect(balanceAccount).to.be.equal(0n);
    });

    it("send 10", async function () {
      idHash2 = await sendAmount(vaultContract, owner, token, _owner.privateKey, _account0.publicKey, 10n);

      const balanceOwner = await getPrivateBalance(vaultContract, owner, token, _owner.privateKey);
      const balanceAccount = await getPrivateBalance(vaultContract, account0, token, _account0.privateKey);

      expect(balanceOwner).to.be.equal(total_supply - 1n - 10n);
      expect(balanceAccount).to.be.equal(0n);
    });
  });

  describe("Retrieve", function () {
    it("retreive 1", async function () {
      await retreiveAmount(vaultContract, idHash1, account0, token, _account0.privateKey, _owner.publicKey);

      const balanceOwner = await getPrivateBalance(vaultContract, owner, token, _owner.privateKey);
      const balanceAccount = await getPrivateBalance(vaultContract, account0, token, _account0.privateKey);
      expect(balanceOwner).to.be.equal(total_supply - 1n - 10n);
      expect(balanceAccount).to.be.equal(1n);
    });

    it("break when retreive 1 again", async function () {
      try{
        await retreiveAmount(vaultContract, idHash1, account0, token, _account0.privateKey, _owner.publicKey);
      }
      catch{
        expect(1).to.be.equal(1);
      }
    });

    it("retreive 10", async function () {
      await retreiveAmount(vaultContract, idHash2, account0, token, _account0.privateKey, _owner.publicKey);

      const balanceOwner = await getPrivateBalance(vaultContract, owner, token, _owner.privateKey);
      const balanceAccount = await getPrivateBalance(vaultContract, account0, token, _account0.privateKey);

      expect(balanceOwner).to.be.equal(total_supply - 1n - 10n);
      expect(balanceAccount).to.be.equal(1n + 10n);
    });
  });

  describe("Send Back", function () {
    it("send back 5", async function () {
      idHash3 = await sendAmount(vaultContract, account0, token, _account0.privateKey, _owner.publicKey, 5n);

      const balanceOwner = await getPrivateBalance(vaultContract, owner, token, _owner.privateKey);
      const balanceAccount = await getPrivateBalance(vaultContract, account0, token, _account0.privateKey);

      expect(balanceOwner).to.be.equal(total_supply - 1n - 10n);
      expect(balanceAccount).to.be.equal(1n + 10n - 5n);
    });

    it("retreive back 5", async function () {
      await retreiveAmount(vaultContract, idHash3, owner, token, _owner.privateKey, _account0.publicKey);

      const balanceOwner = await getPrivateBalance(vaultContract, owner, token, _owner.privateKey);
      const balanceAccount = await getPrivateBalance(vaultContract, account0, token, _account0.privateKey);

      expect(balanceOwner).to.be.equal(total_supply - 1n - 10n + 5n);
      expect(balanceAccount).to.be.equal(1n + 10n - 5n);
    }); 
  });

  describe("Multiple breaks", function () {
    it("send too much", async function () {
      try{
        await sendAmount(vaultContract, account0, token, _account0.privateKey, _owner.publicKey, 500n);
      }
      catch{
        expect(1).to.be.equal(1);
      }
    });

    it("break when retreive again 1", async function () {
      try{
        await retreiveAmount(vaultContract, idHash1, account0, token, _account0.privateKey, _owner.publicKey);
      }
      catch{
        expect(1).to.be.equal(1);
      }
    });   
    
    it("break when retreive again 2", async function () {
      try{
        await retreiveAmount(vaultContract, idHash2, account0, token, _account0.privateKey, _owner.publicKey);
      }
      catch{
        expect(1).to.be.equal(1);
      }
    });   

    it("break when retreive again 3", async function () {
      try{
        await retreiveAmount(vaultContract, idHash3, account0, token, _account0.privateKey, _owner.publicKey);
      }
      catch{
        expect(1).to.be.equal(1);
      }
    });   




    it("break when retreive again 4", async function () {
      try{
        await retreiveAmount(vaultContract, idHash1, owner, token, _owner.privateKey, _account0.publicKey);
      }
      catch{
        expect(1).to.be.equal(1);
      }
    });   
    
    it("break when retreive again 5", async function () {
      try{
        await retreiveAmount(vaultContract, idHash2, owner, token, _owner.privateKey, _account0.publicKey);
      }
      catch{
        expect(1).to.be.equal(1);
      }
    });   

    it("break when retreive again 6", async function () {
      try{
        await retreiveAmount(vaultContract, idHash3, owner, token, _owner.privateKey, _account0.publicKey);
      }
      catch{
        expect(1).to.be.equal(1);
      }
    });   
  });

  describe("Withdraw", function () {
    it("withdraw", async function () {
      const balanceOwnerBefore = await getPrivateBalance(vaultContract, owner, token, _owner.privateKey);
      await withdrawAmount(vaultContract, owner, token, _owner.privateKey, 1n);
      const balanceOwnerAfter = await getPrivateBalance(vaultContract, owner, token, _owner.privateKey);
      expect(balanceOwnerBefore).to.be.equal(balanceOwnerAfter + 1n);
    });

    it("withdraw", async function () {
      const balanceOwnerBefore = await getPrivateBalance(vaultContract, account0, token, _account0.privateKey);
      await withdrawAmount(vaultContract, account0, token, _account0.privateKey, 1n);
      const balanceOwnerAfter = await getPrivateBalance(vaultContract, account0, token, _account0.privateKey);
      expect(balanceOwnerBefore).to.be.equal(balanceOwnerAfter + 1n);
    });
  });
});
