// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import "forge-std/Test.sol";
import { IERC20Errors } from "lib/openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol";
import { TestBaseContract } from "./utils/TestBaseContract.sol";
import { LibErrors } from "src/libs/LibErrors.sol";

contract GatewayTest is TestBaseContract {
  function setUp() public virtual override {
    super.setUp();

    tribalToken.mint(account1, 100);
    
    vm.prank(account1);
    tribalToken.approve(address(diamond), 101);
  }

  function test_Deposit_FailsIfNotEnoughBalance() public {
    vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, account1, 100, 101));
    diamond.deposit(account1, 101);
  }

  function test_Deposit_FailsIfNotEnoughAllowance() public {
    vm.prank(account1);
    tribalToken.approve(address(diamond), 99);

    vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, address(diamond), 99, 100));
    diamond.deposit(account1, 100);
  }

  function test_Deposit_Success_TransfersTokens() public {
    diamond.deposit(account1, 100);

    assertEq(0, tribalToken.balanceOf(account1));
    assertEq(100, tribalToken.balanceOf(address(diamond)));
    assertEq(100, diamond.locked(account1));
  }

  function test_Deposit_Success_EmitsEvent() public {
    vm.recordLogs();

    diamond.deposit(account1, 100);

    Vm.Log[] memory entries = vm.getRecordedLogs();

    assertEq(entries.length, 2, "Invalid entry count");
    assertEq(
        entries[1].topics[0],
        keccak256("Deposit(address,uint256)"),
        "Invalid event signature"
    );
    (address user, uint amount) = abi.decode(entries[1].data, (address,uint256));
    assertEq(user, account1, "Invalid user");
    assertEq(amount, 100, "Invalid amount");
  }
}
