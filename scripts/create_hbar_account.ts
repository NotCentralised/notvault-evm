const {
    Client,
    PrivateKey,
    AccountCreateTransaction,
    AccountBalanceQuery,
    Hbar,
  } = require("@hashgraph/sdk");
  require("dotenv").config();
  
  async function transferHbar() {
    // Grab your Hedera testnet account ID and private key from your .env file
    const myAccountId = process.env.HEDERA_TESTNET_ACCOUNT;
    const myPrivateKey = process.env.HEDERA_TESTNET_ACCOUNT_DER_KEY;
  
    // If we weren't able to grab it, we should throw a new error
    if (myAccountId == null || myPrivateKey == null) {
      throw new Error(
        "Environment variables myAccountId and myPrivateKey must be present"
      );
    }
  
    // Create our connection to the Hedera network
    // The Hedera JS SDK makes this really easy!
    const client = Client.forTestnet();
  
    client.setOperator(myAccountId, myPrivateKey);
  
    // Create new keys
    // const newAccountPrivateKey = PrivateKey.generateED25519();
    const newAccountPrivateKey = PrivateKey.generateECDSA();
    const newAccountPublicKey = newAccountPrivateKey.publicKey;
  
    // Create a new account with 1,000 tinybar starting balance
    const newAccount = await new AccountCreateTransaction()
      .setKey(newAccountPublicKey)
      .setInitialBalance(Hbar.fromTinybars(1000))
      .execute(client);
  
    // Get the new account ID
    const getReceipt = await newAccount.getReceipt(client);
    const newAccountId = getReceipt.accountId;
  
    console.log("The new account ID is: " + newAccountId);
    console.log("The public key is: " + newAccountPublicKey);
    console.log("The private key is: " + newAccountPrivateKey);

  
    // Verify the account balance
    const accountBalance = await new AccountBalanceQuery()
      .setAccountId(newAccountId)
      .execute(client);
  
    console.log(
      "The new account balance is: " +
        accountBalance.hbars.toTinybars() +
        " tinybar."
    );
  
    return newAccountId;
  }
  
  // Call the async transferHbar function
  transferHbar();
  