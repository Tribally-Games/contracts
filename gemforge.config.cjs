require('dotenv').config()

const SALT = "0xf93ac9c61a8577e3e439a5639f65f9eca367e2c6de7086f3b4076c0a895d1902"

module.exports = {
  version: 2,
  solc: {
    // SPDX License - to be inserted in all generated .sol files
    license: "MIT",
    // Solidity compiler version - to be inserted in all generated .sol files
    version: "0.8.24",
  },
  // commands to execute
  commands: {
    // the build command
    build: "forge build --names --sizes",
  },
  paths: {
    // contract built artifacts folder
    artifacts: "out",
    // source files
    src: {
      // file patterns to include in facet parsing
      facets: [
        // include all .sol files in the facets directory ending "Facet"
        "src/facets/*Facet.sol",
      ],
    },
    // folders for gemforge-generated files
    generated: {
      // output folder for generated .sol files
      solidity: "src/generated",
      // output folder for support scripts and files
      support: ".gemforge",
      // deployments JSON file
      deployments: "gemforge.deployments.json",
    },
    // library source code
    lib: {
      // diamond library
      diamond: "lib/diamond-2-hardhat",
    },
  },
  // artifacts configuration
  artifacts: {
    // artifact format - "foundry" or "hardhat"
    format: "foundry",
  },
  // generator options
  generator: {
    // proxy interface options
    proxyInterface: {
      // imports to include in the generated IDiamondProxy interface
      imports: ["src/shared/Structs.sol"],
    },
  },
  // diamond configuration
  diamond: {
    // Whether to include public methods when generating the IDiamondProxy interface. Default is to only include external methods.
    publicMethods: false,
    // The diamond initialization contract - to be called when first deploying the diamond.
    init: {
      // The diamond initialization contract name
      contract: "InitDiamond",
      // The diamond initialization function name
      function: "init",
    },
    // Names of core facet contracts - these will not be modified/removed once deployed and are also reserved names.
    // This default list is taken from the diamond-2-hardhat library.
    // NOTE: we recommend not removing any of these existing names unless you know what you are doing.
    coreFacets: ["OwnershipFacet", "DiamondCutFacet", "DiamondLoupeFacet"],
  },
  // lifecycle hooks
  hooks: {
    // shell command to execute before build
    preBuild: "",
    // shell command to execute after build
    postBuild: "",
    // shell command to execute before deploy
    preDeploy: "",
    // shell command to execute after deploy
    postDeploy: "",
  },
  // Wallets to use for deployment
  wallets: {
    local_wallet: {
      type: "mnemonic",
      config: {
        // Mnemonic phrase - same as anvil default wallet
        words: "test test test test test test test test test test test junk",
        // 0-based index of the account to use
        index: 0,
      },
    },
    deployer_wallet: {
      type: "private-key",
      config: {
        key: process.env.DEPLOYER_PRIVATE_KEY
      },
    },
  },
  // Networks to deploy to
  networks: {
    local: {
      rpcUrl: "http://localhost:8545",
    },
    base_sepolia: {
      rpcUrl: "https://sepolia.base.org",
      contractVerification: {
        foundry: {
          apiUrl: "https://api-sepolia.basescan.org/api",
          apiKey: process.env.BASESCAN_API_KEY,
        },
      },
    },
    base: {
      rpcUrl: "https://base.llamarpc.com",
      contractVerification: {
        foundry: {
          apiUrl: "https://api.basescan.org/api",
          apiKey: process.env.BASESCAN_API_KEY,
        },
      },
    },
    baseFork: {
      rpcUrl: 'http://localhost:8545/',
    }    
  },
  // Targets to deploy
  targets: {
    local: {
      // Network to deploy to
      network: "local",
      // Wallet to use for deployment
      wallet: "local_wallet",
      // Initialization function arguments
      initArgs: [
        // null token
        "0x000000000000000000000000000000000000dead", 
        // default anvil account as signer
        "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
      ],
      // CREATE3 salt
      create3Salt: SALT,
    },
    base_sepolia: {
      // Network to deploy to
      network: "base_sepolia",
      // Wallet to use for deployment
      wallet: "deployer_wallet",
      // Initialization function arguments
      initArgs: [
        // TRIBAL token - see https://github.com/Tribally-Games/tribal-token
        "0xD55592FB0907E505C361Ef6D007424f105CcBD93", 
        // null signer initially
        "0x000000000000000000000000000000000000dead"
      ],
      // CREATE3 salt
      create3Salt: SALT,
    },
    base: {
      // Network to deploy to
      network: "base",
      // Wallet to use for deployment
      wallet: "deployer_wallet",
      // Initialization function arguments
      initArgs: [
        // TRIBAL token - see https://github.com/Tribally-Games/tribal-token
        "0xD55592FB0907E505C361Ef6D007424f105CcBD93", 
        // null signer initially
        "0x000000000000000000000000000000000000dead"
      ],
      // CREATE3 salt
      create3Salt: SALT,
      // upgrades config
      upgrades: {
        // Whether the diamondCut() call will be done manually.
        manualCut: true
      }      
    },
    baseFork: {
      network: 'baseFork',
      wallet: 'deployer_wallet',
      initArgs: [],
      // upgrades config
      upgrades: {
        // Whether the diamondCut() call will be done manually.
        manualCut: true
      }
    }
  },
};
