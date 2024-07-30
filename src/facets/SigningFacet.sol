// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

import { LibAuth } from "src/libs/LibAuth.sol";
import { AuthSignature } from "src/shared/Structs.sol";

/**
 * @dev Signing facet.
 */
contract SigningFacet {
  /**
   * @dev Generate signature payload.
   *
   * @param _data The data to sign.
   * @param _deadline The deadline for the signature.
   */
  function generateSignaturePayload(bytes calldata _data, uint _deadline) external view returns (bytes memory) {
    return LibAuth.generateSignaturePayload(_data, _deadline);
  }
}