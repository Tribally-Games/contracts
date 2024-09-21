// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.27;

import { AppStorage, LibAppStorage } from "../libs/LibAppStorage.sol";

error DiamondAlreadyInitialized();

contract InitDiamond {
  event InitializeDiamond(address sender);

  function init(address _tribalToken, address _signer) external {
    AppStorage storage s = LibAppStorage.diamondStorage();
    if (s.diamondInitialized) {
      revert DiamondAlreadyInitialized();
    }
    s.diamondInitialized = true;

    /*
     * NOTE: no need to check for zero address as these are only called once during deployment.
     */
    s.tribalToken = _tribalToken;
    s.signer = _signer;

    emit InitializeDiamond(msg.sender);
  }
}
