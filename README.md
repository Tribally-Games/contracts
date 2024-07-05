[![Build status](https://github.com/tribally-games/contracts/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/Tribally-Games/contracts/actions/workflows/ci.yml)
[![Coverage Status](https://coveralls.io/repos/github/Tribally-Games/contracts/badge.svg?branch=master)](https://coveralls.io/github/Tribally-Games/contracts?branch=master)

# @tribally-games/contracts

Smart contracts for [Tribally Games](https://tribally.games).

This is a [Diamond Standard](https://eips.ethereum.org/EIPS/eip-2535) upgradeable proxy contract managed using [Gemforge](https://gemforge.xyz/). 

Current ABI:

- `deposit(address user, uint amount)` - deposit TRIBAL token into the gateway for the given wallet.
- `withdraw(address user, uint amount, bytes authSig)` - withdraw TRIBAL token from the gateway to the given wallet.

## On-chain addresses

_TODO_

## Development guide

Ensure the following pre-requisites are installed

* [Node.js 20+](https://nodejs.org)
* [PNPM](https://pnpm.io/) _(NOTE: `yarn` and `npm` can also be used)_
* [Foundry](https://github.com/foundry-rs/foundry/blob/master/README.md)

### Setup

```
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

To deploy to Base Sepolia:

```
$ pnpm dep base_sepolia
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