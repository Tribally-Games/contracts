// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.24;

import { AppStorage, LibAppStorage } from "src/libs/LibAppStorage.sol";
import { LibErrors } from "src/libs/LibErrors.sol";
import { LibAuth } from "src/libs/LibAuth.sol";
import { LibTribalToken } from "src/libs/LibTribalToken.sol";
import { AuthSignature } from "src/shared/Structs.sol";
import { ReentrancyGuard } from "src/shared/ReentrancyGuard.sol";

/**
 * @dev The main gateway facet.
 */
contract GatewayFacet is ReentrancyGuard {
  /**
   * @dev Emitted when a deposit is made.
   */
  event Deposit(address user, uint amount);

  /**
   * @dev Emitted when a withdrawal is made.
   */
  event Withdraw(address user, uint amount);

  /**
   * @dev Get the amount of tokens locked for a user.
   */
  function locked(address _user) external view returns (uint) {
    return LibAppStorage.diamondStorage().locked[_user];
  }

  /**
   * @dev Deposit an amount into the gateway.
   * 
   * @param _user The user to deposit for.   
   * @param _amount The amount to deposit.
   */
  function deposit(address _user, uint _amount) external {
    AppStorage storage s = LibAppStorage.diamondStorage();

    s.locked[_user] += _amount;

    LibTribalToken.transferFrom(_user, _amount);
    
    emit Deposit(_user, _amount);
  }

  /**
    * @dev Withdraw an amount from the gateway.
    *
    * @param _user The user to withdraw from.
    * @param _amount The amount to withdraw.
   */
  function withdraw(address _user, uint _amount,  AuthSignature calldata _sig) external nonReentrant {
    AppStorage storage s = LibAppStorage.diamondStorage();

    LibAuth.assertValidSignature(msg.sender, s.signer, _sig, abi.encodePacked(_user, _amount));

    if (s.locked[_user] < _amount) {
      revert LibErrors.InsufficientBalanceError();
    }

    s.locked[_user] -= _amount;

    LibTribalToken.transferTo(_user, _amount);

    emit Withdraw(_user, _amount);
  }
}
