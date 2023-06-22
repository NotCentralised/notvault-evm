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

### Deployment Costs
|            | GOERLI                                                                                     | SEPOLIA                                                                                     | Hedera Testnet                                                | Base Goerli                                                                                | Deployment Gas |
|------------|--------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------|---------------------------------------------------------------|--------------------------------------------------------------------------------------------|----------------|
| Wallet     | [0x5F4...](https://goerli.etherscan.io/address/0x5F4f89bd3B61740F2E8264FE9ff8e2Cdf295B2bF) | [0x4b8...](https://sepolia.etherscan.io/address/0x4b8Dfd5BdE2907c9b45E5C392421DE5B31E88313) | [0x756...](https://hashscan.io/testnet/contract/0.0.14163364) | [0xF97...](https://goerli.basescan.org/address/0xF972E1A76F08c377bF0DB8ed52a231EE99bD0b41) | 1,162,239      |
| Vault      | [0x4C1...](https://goerli.etherscan.io/address/0x4C1fcce4474CEA690Af57f08eE189CaC4f2e4721) | [0x38A...](https://sepolia.etherscan.io/address/0x38Ad327aDF4c763C0686ED8DBc6fa45c7dAb29AE) | [0xd80...](https://hashscan.io/testnet/contract/0.0.14163367) | [0x9d6...](https://goerli.basescan.org/address/0x9d68228C8E043630041Cf08f911D2EC329390555) | 5,041,627      |
| Deal       | [0xe8F...](https://goerli.etherscan.io/address/0xe8Fb759ABA61091700eBF85F35b866c751Ba6DD6) | [0x523...](https://sepolia.etherscan.io/address/0x52329a088c7d8EBd368fe67a6d3966E3BB42A5BB) | [0x38c...](https://hashscan.io/testnet/contract/0.0.14163369) | [0xFCC...](https://goerli.basescan.org/address/0xFCC3B351310c2E16035E2126cee14175F5350c91) | 4,328,511      |
| Oracle     | [0xa94...](https://goerli.etherscan.io/address/0xa946D99b5dDdd21688AfBBF16c196052c93577Ba) | [0x8b2...](https://sepolia.etherscan.io/address/0x8b2a145b8ccdAfC79DDD3D6bE56Bd513a1e0AA49) | [0xeEB...](https://hashscan.io/testnet/contract/0.0.14163370) | [0xbbf...](https://goerli.basescan.org/address/0xbbf1D9AE5919E25567e17FE0e5187f35F6F562a6) |   693,393      |
| ServiceBus | [0x989...](https://goerli.etherscan.io/address/0x9894CE6BB4dFdE24ACD6276D9CF4Fbd20d67d272) | [0x5A9...](https://sepolia.etherscan.io/address/0x5A95e579944a53370c51760A2db3dF6b96b866F1) | [0xCe0...](https://hashscan.io/testnet/contract/0.0.14195226) | [0x24A...](https://goerli.basescan.org/address/0x24A4d3335f88e59FA672093226D666B1D9CAACAf) |   735,119      |


### Method Costs
|          | Methods            | Approx Gas | Gas Limit |
|----------|--------------------|------------|-----------|
| Wallet   | registerKeys       | 684,397    | 700,000   |
| Wallet   | setValue           | 137,643    | 200,000   |
| Wallet   | setFileIndex       | 90,313     | 100,000   |
| Wallet   | setCredentialIndex | 90,313     | 100,000   |
| Vault    | deposit            | 552,191    | 600,000   |
| Vault    | withdraw           | 374,927    | 400,000   |
| Vault    | createRequest      | 1,152,414  | 1,200,000 |
| Vault    | acceptRequest      | 618,821    | 650,000   |



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

MIT License.