// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.24;

library LibErrors {
  /**
  * @dev Caller/sender must be admin / contract owner.
  */
  error CallerMustBeAdminError();

  /**
  * @dev Caller does not have enough balance to withdraw.
  */
  error InsufficientBalanceError();

  /**
   * @dev The caller supplied an expired signature.
   */
  error SignatureExpired(address caller);

  /**
   @dev The caller supplied an invalid signature.
   */
  error SignatureInvalid(address caller);

  /**
   * @dev The caller supplied an already used signature.
   */
  error SignatureAlreadyUsed(address caller);
}
