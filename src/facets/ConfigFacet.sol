// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.24;

import { AppStorage, LibAppStorage } from "src/libs/LibAppStorage.sol";
import { AccessControl } from "src/shared/AccessControl.sol";

/**
 * @dev The config facet.
 */
contract ConfigFacet is AccessControl {
  /**
   * @dev Get the signer address.
   */
  function signer() external view returns (address) {
    return LibAppStorage.diamondStorage().signer;
  }

  /**
   * @dev Set the signer address.
   *
   * @param _signer The new signer address.
   */
  function setSigner(address _signer) external isAdmin {
    LibAppStorage.diamondStorage().signer = _signer;
  }
}
