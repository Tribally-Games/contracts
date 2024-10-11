// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "forge-std/Test.sol";
import { ERC20Mock } from "lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
import { IERC20Errors } from "lib/openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol";
import { TestBaseContract } from "./utils/TestBaseContract.sol";
import { LibErrors } from "src/libs/LibErrors.sol";
import { AuthSignature, Transaction } from "src/shared/Structs.sol";

contract StakingFacetTest is TestBaseContract {
    ERC20Mock public stakingToken;
    ERC20Mock public payoutToken;    
    address public user1;
    address public user2;

    function setUp() public virtual override {
        super.setUp();

        stakingToken = new ERC20Mock();
        stakingToken.mint(account1, 1000);
        stakingToken.mint(account2, 1000);

        vm.prank(account1);
        stakingToken.approve(address(diamond), 1000);

        vm.prank(account2);
        stakingToken.approve(address(diamond), 1000);

        // Create and set up a new token for payouts
        payoutToken = new ERC20Mock();
        payoutToken.mint(address(this), 1000);
        payoutToken.approve(address(diamond), 1000);

        // set staking token
        vm.prank(owner);
        diamond.setStakingToken(address(stakingToken));
    }

    // ================================================
    // Deposits
    // ================================================

    function test_StakeDeposit_FailsIfAmountZero() public {
        vm.expectRevert(abi.encodeWithSelector(LibErrors.AmountMustBeGreaterThanZero.selector));
        diamond.stakeDeposit(account1, 0);
    }

    function test_StakeDeposit_FailsIfNotEnoughBalance() public {
        vm.prank(account1);
        stakingToken.approve(address(diamond), 1001);

        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, account1, 1000, 1001));
        diamond.stakeDeposit(account1, 1001);
    }

    function test_StakeDeposit_Success() public {
        diamond.stakeDeposit(account1, 100);

        assertEq(900, stakingToken.balanceOf(account1));
        assertEq(100, stakingToken.balanceOf(address(diamond)));
        assertEq(100, diamond.stakeGetUserTotalStaked(account1));
        assertEq(1, diamond.stakeGetUserDepositCount(account1));

        Transaction[] memory deposits = diamond.stakeGetUserDeposits(account1);
        assertEq(1, deposits.length);
        assertEq(100, deposits[0].amount);
        assertEq(block.timestamp, deposits[0].timestamp);
    }

    function test_StakeDeposit_EmitsEvent() public {
        vm.recordLogs();

        diamond.stakeDeposit(account1, 100);

        Vm.Log[] memory entries = vm.getRecordedLogs();

        assertEq(entries.length, 2, "Invalid entry count");
        assertEq(
            entries[1].topics[0],
            keccak256("StakeDeposited(address,uint256)"),
            "Invalid event signature"
        );
        (address user, uint256 amount) = abi.decode(entries[1].data, (address, uint256));
        assertEq(user, account1, "Invalid user");
        assertEq(amount, 100, "Invalid amount");
    }

    // ================================================
    // Withdraws
    // ================================================

    function test_StakeWithdraw_FailsIfAmountZero() public {
        vm.expectRevert(abi.encodeWithSelector(LibErrors.AmountMustBeGreaterThanZero.selector));
        diamond.stakeWithdraw(account1, 0);
    }

    function test_StakeWithdraw_FailsIfInsufficientBalance() public {
        diamond.stakeDeposit(account1, 100);

        vm.expectRevert(abi.encodeWithSelector(LibErrors.InsufficientBalanceError.selector));
        diamond.stakeWithdraw(account1, 101);
    }

    function test_StakeWithdraw_Success() public {
        diamond.stakeDeposit(account1, 100);
        diamond.stakeWithdraw(account1, 50);

        assertEq(950, stakingToken.balanceOf(account1));
        assertEq(50, stakingToken.balanceOf(address(diamond)));
        assertEq(50, diamond.stakeGetUserTotalStaked(account1));
        assertEq(1, diamond.stakeGetUserWithdrawalCount(account1));

        Transaction[] memory withdrawals = diamond.stakeGetUserWithdrawals(account1);
        assertEq(1, withdrawals.length);
        assertEq(50, withdrawals[0].amount);
        assertEq(block.timestamp, withdrawals[0].timestamp);
    }

    function test_StakeWithdraw_EmitsEvent() public {
        diamond.stakeDeposit(account1, 100);

        vm.recordLogs();

        diamond.stakeWithdraw(account1, 50);

        Vm.Log[] memory entries = vm.getRecordedLogs();

        assertEq(entries.length, 2, "Invalid entry count");
        assertEq(
            entries[1].topics[0],
            keccak256("StakeWithdrawn(address,uint256)"),
            "Invalid event signature"
        );
        (address user, uint256 amount) = abi.decode(entries[1].data, (address, uint256));
        assertEq(user, account1, "Invalid user");
        assertEq(amount, 50, "Invalid amount");
    }

    // ================================================
    // Record Payouts
    // ================================================


    function test_StakeRecordPayout_FailsIfAmountZero() public {
        vm.expectRevert(abi.encodeWithSelector(LibErrors.AmountMustBeGreaterThanZero.selector));
        diamond.stakeRecordPayout(address(this), address(payoutToken), 0);
    }

    function test_StakeRecordPayout_Success_SameDay() public {
        payoutToken.mint(address(this), 1500);
        payoutToken.approve(address(diamond), 1500);

        diamond.stakeRecordPayout(address(this), address(payoutToken), 1000);
        
        // Record another payout on the same day
        diamond.stakeRecordPayout(address(this), address(payoutToken), 500);

        uint256 currentDay = block.timestamp / 1 days;
        assertEq(1500, diamond.stakeGetDailyPayoutPoolAmount(address(payoutToken), currentDay));
    }

    function test_StakeRecordPayout_Success_DifferentDays() public {
        payoutToken.mint(address(this), 1500);
        payoutToken.approve(address(diamond), 1500);

        diamond.stakeRecordPayout(address(this), address(payoutToken), 1000);
        
        // Move to the next day
        vm.warp(block.timestamp + 1 days);

        diamond.stakeRecordPayout(address(this), address(payoutToken), 500);

        uint256 previousDay = (block.timestamp - 1 days) / 1 days;
        uint256 currentDay = block.timestamp / 1 days;

        assertEq(1000, diamond.stakeGetDailyPayoutPoolAmount(address(payoutToken), previousDay));
        assertEq(500, diamond.stakeGetDailyPayoutPoolAmount(address(payoutToken), currentDay));
    }

    function test_StakeRecordPayout_EmitsEvent() public {
        vm.recordLogs();

        diamond.stakeRecordPayout(address(this), address(payoutToken), 1000);

        Vm.Log[] memory entries = vm.getRecordedLogs();

        assertEq(entries.length, 2, "Invalid entry count");
        assertEq(
            entries[1].topics[0],
            keccak256("StakePayoutRecorded(address,uint256,uint256)"),
            "Invalid event signature"
        );
        (address token, uint256 amount, uint256 currentDay) = abi.decode(entries[1].data, (address, uint256, uint256));
        assertEq(token, address(payoutToken), "Invalid token");
        assertEq(amount, 1000, "Invalid amount");
        assertEq(currentDay, block.timestamp / 1 days, "Invalid current day");
    }


    // ================================================
    // Claim Payouts
    // ================================================

    function test_StakeClaimPayouts_FailsIfAmountZero() public {
        vm.expectRevert(abi.encodeWithSelector(LibErrors.AmountMustBeGreaterThanZero.selector));
        diamond.stakeClaimPayouts(0, address(payoutToken), account1, _computeDefaultSig(
            abi.encodePacked(uint(0), address(payoutToken), account1),
            block.timestamp + 10 seconds
        ));
    }

    function test_StakeClaimPayouts_FailsIfBadSignature() public {
        vm.expectRevert(abi.encodeWithSelector(LibErrors.SignatureInvalid.selector, address(this)));
        diamond.stakeClaimPayouts(100, address(payoutToken), account1, _computeDefaultSig(
            bytes(""),
            block.timestamp + 10 seconds
        ));
    }

    function test_StakeClaimPayouts_FailsIfSignatureExpired() public {
        // Setup: Record a payout
        diamond.stakeRecordPayout(address(this), address(payoutToken), 1000);

        // Create a signature that's already expired
        AuthSignature memory sig = _computeDefaultSig(
            abi.encodePacked(uint(100), address(payoutToken), account1),
            block.timestamp - 1 seconds
        );

        vm.expectRevert(abi.encodeWithSelector(LibErrors.SignatureExpired.selector, owner));
        diamond.stakeClaimPayouts(100, address(payoutToken), account1, sig);
    }

    function test_StakeClaimPayouts_Success() public {
        // Setup: Record a payout
        diamond.stakeRecordPayout(address(this), address(payoutToken), 1000);

        AuthSignature memory sig = _computeDefaultSig(
            abi.encodePacked(uint(100), address(payoutToken), account1),
            block.timestamp + 10 seconds
        );

        diamond.stakeClaimPayouts(100, address(payoutToken), account1, sig);

        assertEq(100, payoutToken.balanceOf(account1));
        assertEq(1, diamond.stakeGetUserClaimCount(account1, address(payoutToken)));
        assertEq(block.timestamp, diamond.stakeGetLastClaimTime(account1, address(payoutToken)));
        assertEq(100, diamond.stakeGetTotalClaimedForToken(address(payoutToken)));

        Transaction[] memory claims = diamond.stakeGetUserClaims(account1, address(payoutToken));
        assertEq(1, claims.length);
        assertEq(100, claims[0].amount);
        assertEq(block.timestamp, claims[0].timestamp);
    }

    function test_StakeClaimPayouts_EmitsEvent() public {
        // Setup: Record a payout
        diamond.stakeRecordPayout(address(this), address(payoutToken), 1000);

        AuthSignature memory sig = _computeDefaultSig(
            abi.encodePacked(uint(100), address(payoutToken), account1),
            block.timestamp + 10 seconds
        );

        vm.recordLogs();

        diamond.stakeClaimPayouts(100, address(payoutToken), account1, sig);

        Vm.Log[] memory entries = vm.getRecordedLogs();

        assertEq(entries.length, 2, "Invalid entry count");
        assertEq(
            entries[1].topics[0],
            keccak256("StakePayoutClaimed(address,address,uint256)"),
            "Invalid event signature"
        );
        (address user, address token, uint256 amount) = abi.decode(entries[1].data, (address, address, uint256));
        assertEq(user, account1, "Invalid user");
        assertEq(token, address(payoutToken), "Invalid token");
        assertEq(amount, 100, "Invalid amount");
    }

    // ================================================
    // Multiple users
    // ================================================

    function test_StakingTotalStaked_MultipleUsers() public {
        // Initial total staked should be 0
        assertEq(diamond.stakeGetTotalStaked(), 0);

        // User1 deposits 100
        diamond.stakeDeposit(account1, 100);
        assertEq(diamond.stakeGetTotalStaked(), 100);

        // User2 deposits 150
          diamond.stakeDeposit(account2, 150);
        assertEq(diamond.stakeGetTotalStaked(), 250);

        // User1 withdraws 50
        diamond.stakeWithdraw(account1, 50);
        assertEq(diamond.stakeGetTotalStaked(), 200);

        // User2 deposits another 100
        diamond.stakeDeposit(account2, 100);
        assertEq(diamond.stakeGetTotalStaked(), 300);

        // User1 withdraws remaining 50
        diamond.stakeWithdraw(account1, 50);
        assertEq(diamond.stakeGetTotalStaked(), 250);

        // User2 withdraws 200
        diamond.stakeWithdraw(account2, 200);
        assertEq(diamond.stakeGetTotalStaked(), 50);

        // Final check
        assertEq(diamond.stakeGetUserTotalStaked(account1), 0);
        assertEq(diamond.stakeGetUserTotalStaked(account2), 50);
    }
}