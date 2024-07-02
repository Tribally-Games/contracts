![Build status](https://github.com/tribally-games/contracts/actions/workflows/ci.yml/badge.svg?branch=main)
[![Coverage Status](https://coveralls.io/repos/github/tribally-games/contracts/badge.svg?t=wvNXqi)](https://coveralls.io/github/tribally-games/contracts)

# @tribally-games/contracts

Smart contracts for [Tribally Games](https://tribally.games).

## On-chain addresses

_TODO_

## Requirements

* [Node.js 20+](https://nodejs.org)
* [PNPM](https://pnpm.io/) _(NOTE: `yarn` and `npm` can also be used)_
* [Foundry](https://github.com/foundry-rs/foundry/blob/master/README.md)

### Setup

"prepare": "husky install && npx husky add .husky/commit-msg 'npx commitlint --edit $1'",

```
$ foundryup
$ pnpm i
$ pnpm prepare
```

Create `.env` and set the following within:

```
LOCAL_RPC_URL=http://localhost:8545
BASE_SEPOLIA_RPC_URL=<your infura/alchemy endpoint for Base Sepolia>
BASESCAN_API_KEY=<your basescan api key>
MNEMONIC=<your deployment wallet mnemonic>
```

### Usage

Run a local dev node in a separate terminal:

```
pnpm devnet
```

To build the code:

```
$ pnpm build
```

To run the tests:

```
$ pnpm test
```

To deploy to the local target:

```
$ pnpm dep local
```

To deploy to the public target (Base Sepolia):

```
$ pnpm dep testnet
```

For verbose output simply add `-v`:

```
$ pnpm build -v
$ pnpm dep -v
```

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