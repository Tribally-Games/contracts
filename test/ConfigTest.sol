// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "forge-std/Test.sol";
import { TestBaseContract } from "./utils/TestBaseContract.sol";
import { LibErrors } from "src/libs/LibErrors.sol";

contract ConfigTest is TestBaseContract {
    function setUp() public virtual override {
        super.setUp();
    }

  function test_SetSigner_FailsIfNotAdmin() public {
    assertEq(diamond.signer(), signer);

    vm.prank(account1);
    vm.expectRevert(abi.encodeWithSelector(LibErrors.CallerMustBeAdminError.selector));
    diamond.setSigner(account2);
  }

  function test_SetSigner_FailsIfZeroAddress() public {
    assertEq(diamond.signer(), signer);

    vm.prank(owner);
    vm.expectRevert(abi.encodeWithSelector(LibErrors.InvalidSignerError.selector));
    diamond.setSigner(address(0));
  }

  function test_SetSigner_Success() public {
    assertEq(diamond.signer(), signer);

    vm.prank(owner);
    diamond.setSigner(account2);

    assertEq(diamond.signer(), account2);
  }

  function test_SetSigner_EmitsEvent() public { 
    vm.recordLogs();

    vm.prank(owner);
    diamond.setSigner(account2);

    Vm.Log[] memory entries = vm.getRecordedLogs();

    assertEq(entries.length, 1, "Invalid entry count");
    assertEq(
        entries[0].topics[0],
        keccak256("SignerChanged(address)"),
        "Invalid event signature"
    );
    (address user) = abi.decode(entries[0].data, (address));  
    assertEq(user, account2, "Invalid signer");
  }

    function test_SetStakingToken_FailsIfNotAdmin() public {
        vm.prank(account1);
        vm.expectRevert(abi.encodeWithSelector(LibErrors.CallerMustBeAdminError.selector));
        diamond.setStakingToken(address(0xABC));
    }

    function test_SetStakingToken_FailsIfZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(LibErrors.InvalidStakingTokenError.selector));
        diamond.setStakingToken(address(0));
    }

    function test_SetStakingToken_Success() public {
        address newStakingToken = address(0xABC);

        vm.prank(owner);
        diamond.setStakingToken(newStakingToken);

        assertEq(diamond.stakingToken(), newStakingToken);
    }

    function test_SetStakingToken_EmitsEvent() public {
        vm.recordLogs();

        address newStakingToken = address(0xABC);

        vm.prank(owner);
        diamond.setStakingToken(newStakingToken);

        Vm.Log[] memory entries = vm.getRecordedLogs();

        assertEq(entries.length, 1, "Invalid entry count");
        assertEq(
            entries[0].topics[0],
            keccak256("StakingTokenChanged(address)"),
            "Invalid event signature"
        );
        (address changedStakingToken) = abi.decode(entries[0].data, (address));
        assertEq(changedStakingToken, newStakingToken, "Invalid new staking token");
    }
}
