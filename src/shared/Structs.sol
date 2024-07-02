// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.21;

struct AuthSignature {
    /** Signature bytes. */
    bytes signature;
    /** Deadline (block timestamp) */
    uint256 deadline;
}
