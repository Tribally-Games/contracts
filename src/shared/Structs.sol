// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

struct AuthSignature {
    /** Signature bytes. */
    bytes signature;
    /** Deadline (block timestamp) */
    uint256 deadline;
}

struct Transaction {
    uint256 timestamp;
    uint256 amount;
}

struct StakeMultiplierCurve {
    uint64 coefficient;
    uint64 coefficientScale;
}
