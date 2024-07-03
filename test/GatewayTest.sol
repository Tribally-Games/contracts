// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import "forge-std/Test.sol";
import { IERC20Errors } from "lib/openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol";
import { TestBaseContract } from "./utils/TestBaseContract.sol";
import { LibErrors } from "src/libs/LibErrors.sol";
import { AuthSignature } from "src/shared/Structs.sol";

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

  function _setupDeposit() internal {
    diamond.deposit(account1, 100);

    assertEq(0, tribalToken.balanceOf(account1));
    assertEq(100, tribalToken.balanceOf(address(diamond)));
    assertEq(100, diamond.locked(account1));
  }

  function test_Withdraw_Fails_IfBadSignature() public {
    _setupDeposit();
  
    vm.prank(account1);
    vm.expectRevert(abi.encodeWithSelector(LibErrors.SignatureInvalid.selector, account1));
    diamond.withdraw(account1, 100, _computeDefaultSig(
      bytes(""),
      block.timestamp + 10 seconds
    ));
  }

  function test_Withdraw_Fails_IfExpiredSignature() public {
    _setupDeposit();
  
    vm.prank(account1);
    vm.expectRevert(abi.encodeWithSelector(LibErrors.SignatureExpired.selector, account1));
    diamond.withdraw(account1, 100, _computeDefaultSig(
      abi.encodePacked(account1, uint(100)),
      block.timestamp - 1 seconds
    ));
  }

  function test_Withdraw_Fails_IfWrongSigner() public {
    _setupDeposit();
  
    vm.prank(account1);
    vm.expectRevert(abi.encodeWithSelector(LibErrors.SignatureInvalid.selector, account1));
    diamond.withdraw(account1, 1, _computeSig(
      account2_key,
      abi.encodePacked(account1, uint(1)),
      block.timestamp + 10 seconds
    ));
  }

  function test_Withdraw_Fails_IfSignatureAlreadyUsed() public {
    _setupDeposit();

    AuthSignature memory sig = _computeDefaultSig(
      abi.encodePacked(account1, uint(1)),
      block.timestamp + 10 seconds
    );
  
    vm.startPrank(account1);

    diamond.withdraw(account1, 1, sig);

    vm.expectRevert(abi.encodeWithSelector(LibErrors.SignatureAlreadyUsed.selector, account1));
    diamond.withdraw(account1, 1, sig);

    vm.stopPrank();
  }

  function test_Withdraw_Fails_IfNotEnoughBalance() public {
    _setupDeposit();

    vm.expectRevert(abi.encodeWithSelector(LibErrors.InsufficientBalanceError.selector));
    diamond.withdraw(account1, 101, _computeDefaultSig(
      abi.encodePacked(account1, uint(101)),
      block.timestamp + 10 seconds
    ));
  }

  function test_Withdraw_Succeeds_UpdatesBalances() public {
    _setupDeposit();

    diamond.withdraw(account1, 1, _computeDefaultSig(
      abi.encodePacked(account1, uint(1)),
      block.timestamp + 10 seconds
    ));

    assertEq(1, tribalToken.balanceOf(account1));
    assertEq(99, tribalToken.balanceOf(address(diamond)));
    assertEq(99, diamond.locked(account1));
  }

  function test_Withdraw_Succeeds_EmitsEvent() public {
    _setupDeposit();

    vm.recordLogs();

    diamond.withdraw(account1, 1, _computeDefaultSig(
      abi.encodePacked(account1, uint(1)),
      block.timestamp + 10 seconds
    ));

    Vm.Log[] memory entries = vm.getRecordedLogs();

    assertEq(entries.length, 2, "Invalid entry count");
    assertEq(
        entries[1].topics[0],
        keccak256("Withdraw(address,uint256)"),
        "Invalid event signature"
    );
    (address user, uint amount) = abi.decode(entries[1].data, (address,uint256));
    assertEq(user, account1, "Invalid user");
    assertEq(amount, 1, "Invalid amount");
  }
}
