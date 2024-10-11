// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.27;

import { AppStorage, LibAppStorage } from "src/libs/LibAppStorage.sol";
import { AccessControl } from "src/shared/AccessControl.sol";
import { LibErrors } from "src/libs/LibErrors.sol";

/**
 * @dev The config facet.
 */
contract ConfigFacet is AccessControl {
  /**
   * @dev Emitted when the staking token address is changed.
   */
  event StakingTokenChanged(address newStakingToken);


  /**
   * @dev Emitted when the signer address is changed.
   */
  event SignerChanged(address newSigner);
  
  /**
   * @dev Get the signer address.
   */
  function signer() external view returns (address) {
    return LibAppStorage.diamondStorage().signer;
  }

  /**
   * @dev Get the staking token address.
   */
  function stakingToken() external view returns (address) {
    return LibAppStorage.diamondStorage().stakingToken;
  }

  /**
   * @dev Set the signer address.
   *
   * @param _signer The new signer address.
   */
  function setSigner(address _signer) external isAdmin {
    if (_signer == address(0)) {
      revert LibErrors.InvalidSignerError();
    }

    LibAppStorage.diamondStorage().signer = _signer;

    emit SignerChanged(_signer);
  }

  /**
   * @dev Set the staking token address.
   *
   * @param _stakingToken The new staking token address.
   */
  function setStakingToken(address _stakingToken) external isAdmin {
    if (_stakingToken == address(0)) {
      revert LibErrors.InvalidStakingTokenError();
    }

    LibAppStorage.diamondStorage().stakingToken = _stakingToken;

    emit StakingTokenChanged(_stakingToken);
  }
}
