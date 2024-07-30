// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

import { SignatureChecker } from "lib/openzeppelin-contracts/contracts/utils/cryptography/SignatureChecker.sol";
import { MessageHashUtils } from "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import { LibErrors } from "src/libs/LibErrors.sol";
import { AuthSignature } from "src/shared/Structs.sol";
import { AppStorage, LibAppStorage } from "src/libs/LibAppStorage.sol";

/**
 * @dev Authentication stuff.
 *
 * This contract provides ECDSA signature validation. Signatures have expiry deadlines and can only be used once.
 */
library LibAuth {
  /**
   * @dev Generate signature payload.
   */
  function generateSignaturePayload(bytes memory _data, uint _deadline) internal view returns (bytes memory) { 
    return abi.encodePacked(_data, _deadline, block.chainid); 
  }

  /**
   * @dev Assert validity of given signature.
   */
  function assertValidSignature(address _caller, address _signer, AuthSignature memory _sig, bytes memory _data) internal {
    AppStorage storage s = LibAppStorage.diamondStorage();

    if(_sig.deadline < block.timestamp) {
      revert LibErrors.SignatureExpired(_caller); 
    }

    bytes32 digest = MessageHashUtils.toEthSignedMessageHash(
      LibAuth.generateSignaturePayload(_data, _sig.deadline)
    );

    if (!SignatureChecker.isValidSignatureNow(_signer, digest, _sig.signature)) {
      revert LibErrors.SignatureInvalid(_caller);
    }

    if(s.authSignatures[digest]) {
      revert LibErrors.SignatureAlreadyUsed(_caller);
    }

    s.authSignatures[digest] = true;
  }
}