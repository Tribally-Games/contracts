// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.27;

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
