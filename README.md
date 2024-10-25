[![Build status](https://github.com/tribally-games/contracts/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/Tribally-Games/contracts/actions/workflows/ci.yml)
[![Coverage Status](https://coveralls.io/repos/github/Tribally-Games/contracts/badge.svg?branch=master)](https://coveralls.io/github/Tribally-Games/contracts?branch=master)

# @tribally.games/contracts

Core smart contracts for [Tribally Games](https://tribally.games). 

This is a [Diamond Standard](https://eips.ethereum.org/EIPS/eip-2535) upgradeable proxy contract managed using [Gemforge](https://gemforge.xyz/). 

_Note: the [TRIBAL token contract](https://github.com/Tribally-Games/tribal-token) is separate to this one._

## On-chain addresses

* Base: `0x756B16467553c68e5a8bAB9146661C07745410Cb` ([Basescan](https://basescan.org/address/0x756B16467553c68e5a8bAB9146661C07745410Cb), [Louper](https://louper.dev/diamond/0x756B16467553c68e5a8bAB9146661C07745410Cb?network=base))
* Base Sepolia: `0x756B16467553c68e5a8bAB9146661C07745410Cb` ([Basescan](https://sepolia.basescan.org/address/0x756B16467553c68e5a8bAB9146661C07745410Cb), [Louper](https://louper.dev/diamond/0x756B16467553c68e5a8bAB9146661C07745410Cb?network=baseSepolia))

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

For verbose output simply add `-v`:

```shell
$ pnpm build -v
$ pnpm dep -v
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