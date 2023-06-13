# NotVault &nbsp; &nbsp; | &nbsp; &nbsp; The Self-Sovereignty SDK

__NotVault__ is an open-source SDK that enables the rapid and safe development of self-sovereign data workflows. __NotVault__ enables confidential commerce / payments, token transfers, file management and the use of verifiable credentials. The toolkit simplifies the implementation of Zero Knowledge Proof (ZKP) technology, while applying best practices for encryption, decentralisation and peer-to-peer / operations for all data.

**NotVaul** is analogous to a wallet since it allows users to link a contact ID like an email to their wallet in a private way. Furthermore, the wallet creates a new public / private key pair which is used to encrypt and sign data within the ecosystem, without needing access to the keys of the ETH wallet (Metamask) which is typically not accessible through the API. The contact ID allows a more user-friendly way of connecting to other identities. Instead of needing to input a wallet address, users can instead input an email for example.

The key principles are to use the following as much as possible:
- **Peer-to-peer**: in order to mitigate single point of failure risks.
- **Encryption**: to ensure confidentiality
- **Zero Knowledge Proofs**: to minimise data foot print when communicating

Builders using __NotVault__ benefit from a rich toolkit of functionality in the form of smart contracts and client-side [typescript](https://www.typescriptlang.org) modules that include:
- **Wallet**: Stores encrypted keys and encrypted metadata.
- **Credentials**: [zkSNARK](https://en.wikipedia.org/wiki/Non-interactive_zero-knowledge_proof) credental proof generation and verification.
- **Vault**: manage confidential token balances and transfers.
- **Files**: enables a self-sovereign and encrypted file storage capability through [IPFS](https://ipfs.tech).
- **Commercial Deals**: enable the life-cycle management of transactional / contractual agreements including their financial settlement and self-custody escrows of payment amounts through a peer-to-peer, self-custody platform.
- **Service Bus**: enables a confidential messaging service that ensures the integrity regarding of timestamp, source and underlying message using a [zkSNARK](https://en.wikipedia.org/wiki/Non-interactive_zero-knowledge_proof).

# Information
For more detailed information please go to our [GITBOOK](https://docs.notcentralised.com).


# Contracts

### Deployment Costs
|            | GOERLI Address                                                                                            | SEPOLIA Address                                                                                            | Hedera Testnet Address                                                       | Deployment Gas |
|------------|-----------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------|----------------|
| Wallet     | [0x5F4f89bd3B61740F2E...](https://goerli.etherscan.io/address/0x5F4f89bd3B61740F2E8264FE9ff8e2Cdf295B2bF) | [0x4b8Dfd5BdE2907c9b4...](https://sepolia.etherscan.io/address/0x4b8Dfd5BdE2907c9b45E5C392421DE5B31E88313) | [0x7560B9002516B82F5a...](https://hashscan.io/testnet/contract/0.0.14163364) | 1,162,239      |
| Vault      | [0x4C1fcce4474CEA690A...](https://goerli.etherscan.io/address/0x4C1fcce4474CEA690Af57f08eE189CaC4f2e4721) | [0x38Ad327aDF4c763C06...](https://sepolia.etherscan.io/address/0x38Ad327aDF4c763C0686ED8DBc6fa45c7dAb29AE) | [0xd8006605Fea3433D54...](https://hashscan.io/testnet/contract/0.0.14163367) | 5,041,627      |
| Deal       | [0xe8Fb759ABA61091700...](https://goerli.etherscan.io/address/0xe8Fb759ABA61091700eBF85F35b866c751Ba6DD6) | [0x52329a088c7d8EBd36...](https://sepolia.etherscan.io/address/0x52329a088c7d8EBd368fe67a6d3966E3BB42A5BB) | [0x38c084eD2b82A07A8c...](https://hashscan.io/testnet/contract/0.0.14163369) | 4,328,511      |
| Oracle     | [0xa946D99b5dDdd21688...](https://goerli.etherscan.io/address/0xa946D99b5dDdd21688AfBBF16c196052c93577Ba) | [0x8b2a145b8ccdAfC79D...](https://sepolia.etherscan.io/address/0x8b2a145b8ccdAfC79DDD3D6bE56Bd513a1e0AA49) | [0xeEBb3548334c30DFeF...](https://hashscan.io/testnet/contract/0.0.14163370) |   693,393      |
| ServiceBus | [0x9894CE6BB4dFdE24AC...](https://goerli.etherscan.io/address/0x9894CE6BB4dFdE24ACD6276D9CF4Fbd20d67d272) | [0x5A95e579944a53370c...](https://sepolia.etherscan.io/address/0x5A95e579944a53370c51760A2db3dF6b96b866F1) | [0xCe011732b409bA1332...](https://hashscan.io/testnet/contract/0.0.14195226) |   735,119      |


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