# NotVault &nbsp; &nbsp; | &nbsp; &nbsp; The Self-Sovereignty SDK

The **NotVault** SDK is an open-source toolset designed for the swift and secure creation of self-sovereign data workflows. Its functionality spans multiple use cases, including confidential commerce and payments, token transfers, file management, and the application of verifiable credentials.
With a focus on streamlining the incorporation of Zero Knowledge Proof (ZKP) technology, NotVault emphasises best practices for encryption, decentralisation, and peer-to-peer operations in all data exchanges.

## Core Principles
NotVault operates on three fundamental principles:
- **Peer-to-Peer**: To mitigate risks associated with a single point of failure.
- **Encryption**: To maintain confidentiality at all times.
- Zero Knowledge Proofs: To minimise data footprints during communication.

The functionality of NotVault mirrors that of a wallet, facilitating the private linkage of a contact ID (such as an email) to a user's wallet. Additionally, it generates a new public/private key pair used for data encryption and signing within the ecosystem. This system negates the need to access the keys of the Ethereum wallet (typically inaccessible via API) and provides a more user-friendly method of connecting with other identities.

## Key Features
Developers leveraging NotVault can access a plethora of features including:
- **Wallet**: Safeguards encrypted keys and metadata.
- **Credentials**: Facilitates the generation and verification of [zkSNARK](https://en.wikipedia.org/wiki/Non-interactive_zero-knowledge_proof) credential proofs.
- **Vault**: Manages confidential token balances and transfers.
- **Files**: Enables self-sovereign and encrypted file storage capability through [IPFS](https://ipfs.tech).
- **Commercial Deals**: Supports the lifecycle management of transactional or contractual agreements, including their financial settlement. It offers self-custody escrows of token payment amounts via a peer-to-peer platform.
- **Service Bus**: Provides a confidential messaging service, ensuring integrity of timestamp, source, and underlying message using a [zkSNARK](https://en.wikipedia.org/wiki/Non-interactive_zero-knowledge_proof).
Harness the power of **NotVault** SDK to expedite the development of secure, decentralised applications and services.

# Information
For more detailed information please go to our [GITBOOK](https://docs.notcentralised.com).


# Contracts
## ConfidentialVault.sol
Description: The ConfidentialVault contract enables confidential token transfers between wallets. It uses zero-knowledge proofs to ensure that the sender's balance is sufficient for the transfer without revealing the actual amounts on the blockchain.

### Key Features:
- Confidential Transfers: Allows sending tokens without revealing the amount.
- Zero-Knowledge Proofs: Ensures the validity of transactions without disclosing sensitive information.
- Asynchronous Process: The transfer process involves creating a send request and then accepting it in separate transactions.
- Unlocking Conditions: The sender can set conditions for unlocking the tokens, such as time-based locks or oracle-based conditions.

### Usage:
- Deposit Tokens: The sender deposits ERC20 tokens into the vault.
- Create Send Request: The sender creates a send request with a ZK proof, locking the tokens.
- Accept Request: The receiver accepts the request with a ZK proof, updating their balance.
- Unlocking Conditions:

    - Earliest time the receiver can unlock tokens.
    - Earliest time the sender can unlock tokens.
    - Oracle-based conditions for both sender and receiver.

## ConfidentialDeal.sol
Description: The ConfidentialDeal contract represents legal agreements as NFTs. It allows the owner to attach required payments and the counterpart to agree to the deal by locking in these payments.

### Key Features:
- NFT Representation: Each deal is represented as an NFT.
- Custom Functionality: Allows programming of cashflows and selective disclosure using ZK methodologies.
- Preprogrammed Payments: The owner can attach required payments that the counterpart must lock in before agreeing to the deal.

###  Usage:
- Mint Deal: The owner mints a new deal NFT specifying the counterpart, ZK hash, and expiry.
- Attach Payments: The owner attaches required payments to the deal.
- Accept Deal: The counterpart locks in the payments and accepts the deal.

## ConfidentialAccessControl.sol
Description: The ConfidentialAccessControl contract manages access control for the vault and other contracts. It allows relay wallets to execute transactions on behalf of user wallets.

### Key Features:
- Meta Transactions: Allows relay wallets to execute transactions on behalf of user wallets.
- Treasurer Management: Manages treasurers for different ERC20 denominations.

### Usage:

- Execute Meta Transaction: The relay wallet executes a transaction signed by the user wallet.
- Add Treasurer: The owner adds a treasurer for a specific ERC20 denomination.
- Check Treasurer: Verify if an address is the treasurer for a given ERC20 denomination.

## ConfidentialGroup.sol
Description: The ConfidentialGroup contract manages groups of wallets with specific policies for token transfers. It allows group owners to set policies and add members.

### Key Features:
- Group Management: Manages groups of wallets with specific policies.
- Policy-Based Transfers: Allows token transfers based on predefined policies.
- Membership Management: Manages group memberships and linked Deal NFTs.

### Usage:
- Register Group: Create a new group with a set of members.
- Set Group Wallet: Set the wallet address for the group.
- Add Policy: Add a policy for the group.
- Create Request: Create a send request from the group account.
- Accept Request: Accept a send request on behalf of the group.

## ConfidentialOracle.sol
Description: The ConfidentialOracle contract allows external parties to set values in a key-pair to unlock send requests in the vault.

### Key Features:
- Value Setting: Allows setting values for a key-pair linked to an address.
- Proof Verification: Verifies ZK proofs to ensure the validity of the values.

### Usage:
- Set Value: Set a value for a key-pair using a ZK proof.
- Get Value: Retrieve the value of a key-pair.

----
# Building
In order to compile and run the smart contract code.

### Prerequisites
The compilation and development environment necessary are:
#### Rust
A fast and memory efficient language used by the circom compiler.

https://www.rust-lang.org
```shell
curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh
```
#### Circom 2.0
The zero knowledge circuit development environment.

https://docs.circom.io
```shell
git clone https://github.com/iden3/circom.git
cd circom
cargo build --release
cargo install --path circom
```
#### SnarkJS
The zkSnark environment.

https://github.com/iden3/snarkjs
```shell
npm install -g snarkjs
```
Once the environment is correctly setup, you can proceed with compiling the cirtuits.
## Build the circuits

```shell
cd circuits
sh compile.sh
cd ...
```

Run the tests

```shell
npx hardhat test
```

# License
This project is licensed under the MIT License.

# Authors
@NumbersDeFi

# Acknowledgments
OpenZeppelin for their ERC20 and ERC721 implementations.
The Ethereum community for their support and contributions to the ecosystem.