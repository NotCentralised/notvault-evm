import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import { config as dotenvConfig } from "dotenv";
import { resolve } from "path";

require('hardhat-contract-sizer');


const dotenvConfigPath: string = process.env.DOTENV_CONFIG_PATH || "./.env";
dotenvConfig({ path: resolve(__dirname, dotenvConfigPath) });

const GOERLI_ALCHEMY_API_KEY: string | undefined = process.env.GOERLI_ALCHEMY_API_KEY;
const GOERLI_PRIVATE_KEY: string | undefined = process.env.GOERLI_PRIVATE_KEY;
const GOERLI_PRIVATE_KEY_0: string | undefined = process.env.GOERLI_PRIVATE_KEY_0;
const GOERLI_PRIVATE_KEY_1: string | undefined = process.env.GOERLI_PRIVATE_KEY_1;

const SEPOLIA_ALCHEMY_API_KEY: string | undefined = process.env.SEPOLIA_ALCHEMY_API_KEY;
const SEPOLIA_PRIVATE_KEY: string | undefined = process.env.SEPOLIA_PRIVATE_KEY;
const SEPOLIA_PRIVATE_KEY_0: string | undefined = process.env.SEPOLIA_PRIVATE_KEY_0;
const SEPOLIA_PRIVATE_KEY_1: string | undefined = process.env.SEPOLIA_PRIVATE_KEY_1;

const MAINNET_ALCHEMY_API_KEY: string | undefined = process.env.MAINNET_ALCHEMY_API_KEY;
const MAINNET_PRIVATE_KEY: string | undefined = process.env.MAINNET_PRIVATE_KEY;
const MAINNET_PRIVATE_KEY_0: string | undefined = process.env.MAINNET_PRIVATE_KEY_0;
const MAINNET_PRIVATE_KEY_1: string | undefined = process.env.MAINNET_PRIVATE_KEY_1;

const BASE_GOERLI_PRIVATE_KEY: string | undefined = process.env.BASE_GOERLI_PRIVATE_KEY;
const BASE_GOERLI_PRIVATE_KEY_0: string | undefined = process.env.BASE_GOERLI_PRIVATE_KEY_0;
const BASE_GOERLI_PRIVATE_KEY_1: string | undefined = process.env.BASE_GOERLI_PRIVATE_KEY_1;

const HEDERA_TESTNET_PRIVATE_KEY: string | undefined = process.env.HEDERA_TESTNET_PRIVATE_KEY;
const HEDERA_TESTNET_PRIVATE_KEY_0: string | undefined = process.env.HEDERA_TESTNET_PRIVATE_KEY_0;
const HEDERA_TESTNET_PRIVATE_KEY_1: string | undefined = process.env.HEDERA_TESTNET_PRIVATE_KEY_1;

const REDBELLY_TESTNET_PRIVATE_KEY: string | undefined = process.env.REDBELLY_TESTNET_PRIVATE_KEY;
const REDBELLY_TESTNET_PRIVATE_KEY_0: string | undefined = process.env.REDBELLY_TESTNET_PRIVATE_KEY_0;
const REDBELLY_TESTNET_PRIVATE_KEY_1: string | undefined = process.env.REDBELLY_TESTNET_PRIVATE_KEY_1;

const REDBELLY_MAINNET_PRIVATE_KEY: string | undefined = process.env.REDBELLY_MAINNET_PRIVATE_KEY;
const REDBELLY_MAINNET_PRIVATE_KEY_0: string | undefined = process.env.REDBELLY_MAINNET_PRIVATE_KEY_0;
const REDBELLY_MAINNET_PRIVATE_KEY_1: string | undefined = process.env.REDBELLY_MAINNET_PRIVATE_KEY_1;

if (!GOERLI_PRIVATE_KEY || !GOERLI_PRIVATE_KEY_0 || !GOERLI_PRIVATE_KEY_1) {
  throw new Error("Please set your GOERLI_PRIVATE_KEY in a .env file");
}
if (!SEPOLIA_PRIVATE_KEY || !SEPOLIA_PRIVATE_KEY_0 || !SEPOLIA_PRIVATE_KEY_1) {
  throw new Error("Please set your SEPOLIA_PRIVATE_KEY in a .env file");
}
if (!MAINNET_PRIVATE_KEY || !MAINNET_PRIVATE_KEY_0 || !MAINNET_PRIVATE_KEY_1) {
  throw new Error("Please set your MAINNET_PRIVATE_KEY in a .env file");
}
if (!HEDERA_TESTNET_PRIVATE_KEY || !HEDERA_TESTNET_PRIVATE_KEY_0 || !HEDERA_TESTNET_PRIVATE_KEY_1) {
  throw new Error("Please set your HEDERA_TESTNET_PRIVATE_KEY in a .env file");
}
if (!BASE_GOERLI_PRIVATE_KEY || !BASE_GOERLI_PRIVATE_KEY_0 || !BASE_GOERLI_PRIVATE_KEY_1) {
  throw new Error("Please set your BASE_GOERLI_PRIVATE_KEY in a .env file");
}
if (!REDBELLY_TESTNET_PRIVATE_KEY || !REDBELLY_TESTNET_PRIVATE_KEY_0 || !REDBELLY_TESTNET_PRIVATE_KEY_1) {
  throw new Error("Please set your REDBELLY_TESTNET_PRIVATE_KEY in a .env file");
}
if (!REDBELLY_MAINNET_PRIVATE_KEY || !REDBELLY_MAINNET_PRIVATE_KEY_0 || !REDBELLY_MAINNET_PRIVATE_KEY_1) {
  throw new Error("Please set your REDBELLY_MAINNET_PRIVATE_KEY in a .env file");
}

const config: HardhatUserConfig = {
  solidity:{
    compilers:[{
        version: "0.8.18",
    }],
    settings: {
      viaIR: true,
      optimizer: {
          enabled: true,
      }
    },
  },
  networks: {
    goerli: {
      url: `https://eth-goerli.g.alchemy.com/v2/${GOERLI_ALCHEMY_API_KEY}`,
      accounts: [GOERLI_PRIVATE_KEY, GOERLI_PRIVATE_KEY_0, GOERLI_PRIVATE_KEY_1]
    },
    sepolia: {
      url: `https://eth-sepolia.g.alchemy.com/v2/${SEPOLIA_ALCHEMY_API_KEY}`,
      accounts: [SEPOLIA_PRIVATE_KEY, SEPOLIA_PRIVATE_KEY_0, SEPOLIA_PRIVATE_KEY_1]
    },
    mainnet: {
      url: `https://eth-mainnet.g.alchemy.com/v2/${MAINNET_ALCHEMY_API_KEY}`,
      accounts: [MAINNET_PRIVATE_KEY, MAINNET_PRIVATE_KEY_0, MAINNET_PRIVATE_KEY_1]
    },
    hedera_testnet: {
      url: `https://testnet.hashio.io/api`,
      accounts: [HEDERA_TESTNET_PRIVATE_KEY, HEDERA_TESTNET_PRIVATE_KEY_0, HEDERA_TESTNET_PRIVATE_KEY_1],
    },
    hedera_local: {
      url: `http://localhost:7546`,
      accounts: [HEDERA_TESTNET_PRIVATE_KEY, HEDERA_TESTNET_PRIVATE_KEY_0, HEDERA_TESTNET_PRIVATE_KEY_1],
    },
    base_goerli: {
      url: `https://goerli.base.org`,
      accounts: [BASE_GOERLI_PRIVATE_KEY, BASE_GOERLI_PRIVATE_KEY_0, BASE_GOERLI_PRIVATE_KEY_1],
    },

    redbelly_testnet: {
      url: `https://governors.testnet.redbelly.network`,
      accounts: [REDBELLY_TESTNET_PRIVATE_KEY, REDBELLY_TESTNET_PRIVATE_KEY_0, REDBELLY_TESTNET_PRIVATE_KEY_1],
    },
    redbelly_mainnet: {
      url: `https://governors.mainnet.redbelly.network`,
      accounts: [REDBELLY_MAINNET_PRIVATE_KEY, REDBELLY_MAINNET_PRIVATE_KEY_0, REDBELLY_MAINNET_PRIVATE_KEY_1],
    },
  },
  contractSizer: {
    alphaSort: true,
    runOnCompile: true,
    disambiguatePaths: false,
  }
};

export default config;
