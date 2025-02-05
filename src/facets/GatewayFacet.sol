// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

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
   * @param user The user that the deposit is for.
   * @param amount The amount that was deposited.
   */
  event Deposit(address user, uint amount);

  /**
   * @dev Emitted when a withdrawal is made.
   * @param user The user that the withdrawal is for.
   * @param amount The amount that was withdrawn.
   */
  event Withdraw(address user, uint amount);

  /**
   * @dev Get the amount in the pool.
   */
  function gatewayPoolBalance() external view returns (uint) {
    return LibAppStorage.diamondStorage().gatewayPoolBalance;
  }

  /**
   * @dev Deposit an amount into the gateway on behalf of a user.
   * 
   * @param _user The user to deposit for. If null address then we're depositing into the pool for everyone.
   * @param _amount The amount to deposit.
   */
  function deposit(address _user, uint _amount) external {
    AppStorage storage s = LibAppStorage.diamondStorage();

    LibTribalToken.transferFrom(msg.sender, _amount);

    s.gatewayPoolBalance += _amount;

    emit Deposit(_user, _amount);
  }

  /**
    * @dev Withdraw an amount from the gateway.
    *
    * @param _user The user to withdraw for.
    * @param _amount The amount to withdraw.
    * @param _sig The authorization signature.
   */
  function withdraw(address _user, uint _amount,  AuthSignature calldata _sig) external nonReentrant {
    AppStorage storage s = LibAppStorage.diamondStorage();

    LibAuth.assertValidSignature(msg.sender, s.signer, _sig, abi.encodePacked(_user, _amount));

    if (s.gatewayPoolBalance < _amount) {
      revert LibErrors.InsufficientBalanceError();
    }

    s.gatewayPoolBalance -= _amount;

    LibTribalToken.transferTo(_user, _amount);

    emit Withdraw(_user, _amount);
  }
}
