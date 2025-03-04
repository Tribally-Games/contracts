[![Build status](https://github.com/tribally-games/contracts/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/Tribally-Games/contracts/actions/workflows/ci.yml)
[![Coverage Status](https://coveralls.io/repos/github/Tribally-Games/contracts/badge.svg?branch=master)](https://coveralls.io/github/Tribally-Games/contracts?branch=master)

# @tribally.games/contracts

Core smart contracts for [Tribally Games](https://tribally.games). 

This is a [Diamond Standard](https://eips.ethereum.org/EIPS/eip-2535) upgradeable proxy contract managed using [Gemforge](https://gemforge.xyz/). 

_Note: the [TRIBAL token contract](https://github.com/Tribally-Games/tribal-token) is separate to this one._

## On-chain addresses

* Base: `0x3249787E176d97298f5137A1C50CD33ae23EBd97` ([Basescan](https://basescan.org/address/0x3249787E176d97298f5137A1C50CD33ae23EBd97), [Louper](https://louper.dev/diamond/0x3249787E176d97298f5137A1C50CD33ae23EBd97?network=base))
* Base Sepolia: `0x999C1045C7430642e6D05cb4Be30C0b3D310a2E7` ([Basescan](https://sepolia.basescan.org/address/0x999C1045C7430642e6D05cb4Be30C0b3D310a2E7), [Louper](https://louper.dev/diamond/0x999C1045C7430642e6D05cb4Be30C0b3D310a2E7?network=baseSepolia))

## Usage guide

Install the NPM package:

* NPM: `npm install @tribally.games/contracts`
* Yarn: `yarn add @tribally.games/contracts`
* PNPM: `pnpm add @tribally.games/contracts`
* Bun: `bun add @triballuy.games/contracts`

Use it within your code:

```js
const { abi, diamondProxy } = require('@tribally.games/contracts');

console.log(abi) // JSON ABI of the diamond proxy
console.log(diamondProxy.baseSepolia) // address of contracts on Base Sepolia
```

## Development guide

If you're working on this repo itself then these instructions are for you.

Ensure the following pre-requisites are installed

* [Node.js 20+](https://nodejs.org)
* [PNPM](https://pnpm.io/) _(NOTE: `yarn` and `npm` can also be used)_
* [Foundry](https://github.com/foundry-rs/foundry/blob/master/README.md)

### Setup

```shell
$ foundryup
$ pnpm i
$ pnpm bootstrap
```

Create `.env` and set the following within:

```
DEPLOYER_PRIVATE_KEY=<your deployment wallet private key>
BASESCAN_API_KEY=<your basescan api key>
```

### Usage

Run a local dev node in a separate terminal:

```shell
pnpm devnet
```

To build the code:

```shell
$ pnpm build
```

To run the tests:

```shell
$ pnpm test
```

To deploy to the local target:

```shell
$ pnpm dep local
```

To deploy to public networks:

* Base sepolia: `pnpm dep base_sepolia`
* Base mainnet: `pnpm dep base`

Once deployed you can verify contract source-codes on Basescan using:

* Base sepolia: `pnpm verify base_sepolia`
* Base: `pnpm verify base`

For verbose output simply add `-v`:

```shell
$ pnpm build -v
$ pnpm dep -v
```

### Simulating live upgrades

You can simulate a live upgrade locally.

Run a local fork of the Base mainnet:

```shell
$ pnpm devnet-baseFork
```

The RPC server will now be running at http://localhost:8545

Now try deploying to this fork:

```shell
$ pnpm dep baseFork --verbose
```

This will go though the upgrade process for the Diamond in the locally running Base fork

You should see output that looks like the following:

```
GEMFORGE: Resolving what changes need to be applied ...
GEMFORGE: Resolving methods on-chain ...
GEMFORGE: Calling facets() on contract IDiamondProxy deployed at 0x3249787E176d97298f5137A1C50CD33ae23EBd97 with args () ...
GEMFORGE: Resolving methods in artifacts ...
GEMFORGE: Getting bytecode for contract at address 0xb16B2f6396185a516f1D8DD70A0E30c174559A4f ...
GEMFORGE: [Replace] method setSigner(address) [0x6c19e783] by deploying new facet ConfigFacet
GEMFORGE: [Replace] method setStakingToken(address) [0x1e9b12ef] by deploying new facet ConfigFacet
```

Note that it will not actually call `diamondCut()` and upgrade the Diamond since the owner is the SAFE multisig. Instead it will output the parameters for you to send the transaction manually:

```
GEMFORGE: Outputting upgrade tx params so that you can do the upgrade manually...

GEMFORGE: ================================================================================

GEMFORGE: Diamond: 0x3249787E176d97298f5137A1C50CD33ae23EBd97

GEMFORGE: Tx data: 0x1f931c1c00000000000000000000000000000000000000000000000000000000..
.......................................................................................
.......................................................................................

```

So now we can pretend to the SAFE multisig and send this tx through:

```shell
$ cast rpc anvil_impersonateAccount 0x4b78Bc43E63AD6524A411F17Ff376Fd362DBB531 # base multisig wallet
$ cast send --from 0x4b78Bc43E63AD6524A411F17Ff376Fd362DBB531 --unlocked 0x3249787E176d97298f5137A1C50CD33ae23EBd97 0x.... # final arg is the tx data blob from above
```

This transaction should succeed. At this point, the Diamond in the locally running Base fork should be fully upgraded. Check using:

```shell
$ pnpm query baseFork
```

You should hopefully see at the end:

```
Unrecognized facets: 0
Unrecognized functions: 0
```



### Publishing releases

To create a new release of the package, first set your Github token env var:

```shell
$ export GITHUB_TOKEN=<use a Personal Access Token created in Github that gives access to public repos>
```

Now create a release PR:

```shell
$ pnpm create-release-pr
```

This will create a new release PR. The PR can be updated with new commits by again calling the same command.

Once the PR is merged into the `master` branch, run:

```shell
$ pnpm finalize-release
```

 This will create a release tag and cause the [`npm-publish`](https://github.com/Tribally-Games/contracts/blob/master/.github/workflows/npm-publish.yml) workflow to run, publishing the package to NPM.


## License

AGPLv3 - see [LICENSE.md](LICENSE.md)

Tribally Games smart contracts
Copyright (C) 2024  [Tribally Games](https://tribally.games)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.