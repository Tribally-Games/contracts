// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.21;

import { LibDiamond } from "lib/diamond-2-hardhat/contracts/libraries/LibDiamond.sol";
import { LibErrors } from "../libs/LibErrors.sol";

/**
 * @dev Access control module.
 */
abstract contract AccessControl {
  modifier isAdmin() {
    if (LibDiamond.contractOwner() != msg.sender) {
      revert LibErrors.CallerMustBeAdminError();
    }
    _;
  }
}