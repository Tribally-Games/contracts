// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

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
        uint256 day = _getCurrentDay();
        assertEq(100, diamond.stakeGetUserTotalStaked(account1, day));
        assertEq(100, diamond.stakeGetTotalStaked(day));
        
        assertEq(1, diamond.stakeGetUserDepositCount(account1));

        Transaction[] memory deposits = diamond.stakeGetUserDepositList(account1);
        assertEq(1, deposits.length);
        assertEq(100, deposits[0].amount);
        assertEq(block.timestamp, deposits[0].timestamp);

        Transaction memory deposit = diamond.stakeGetUserDepositAt(account1, 0);
        assertEq(100, deposit.amount);
        assertEq(block.timestamp, deposit.timestamp);
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

        uint256 day = _getCurrentDay();

        assertEq(950, stakingToken.balanceOf(account1));
        assertEq(50, stakingToken.balanceOf(address(diamond)));

        assertEq(50, diamond.stakeGetUserTotalStaked(account1, day));
        assertEq(50, diamond.stakeGetTotalStaked(day));

        assertEq(1, diamond.stakeGetUserWithdrawalCount(account1));

        Transaction[] memory withdrawals = diamond.stakeGetUserWithdrawalList(account1);
        assertEq(1, withdrawals.length);
        assertEq(50, withdrawals[0].amount);
        assertEq(block.timestamp, withdrawals[0].timestamp);

        Transaction memory withdrawal = diamond.stakeGetUserWithdrawalAt(account1, 0);
        assertEq(50, withdrawal.amount);
        assertEq(block.timestamp, withdrawal.timestamp);
    }

    function test_StakeMultipleWithdrawalsLater_Success() public {
        diamond.stakeDeposit(account1, 100);

        vm.warp(block.timestamp + 1 days);
        uint w1Timestamp = block.timestamp;

        diamond.stakeWithdraw(account1, 50);

        vm.warp(block.timestamp + 1 days);
        uint w2Timestamp = block.timestamp;

        diamond.stakeWithdraw(account1, 25);

        uint256 firstDay = _getCurrentDay() - 1;
        uint256 secondDay = firstDay + 1;

        assertEq(975, stakingToken.balanceOf(account1));
        assertEq(25, stakingToken.balanceOf(address(diamond)));

        assertEq(50, diamond.stakeGetUserTotalStaked(account1, firstDay));
        assertEq(50, diamond.stakeGetTotalStaked(firstDay));

        assertEq(25, diamond.stakeGetUserTotalStaked(account1, secondDay));
        assertEq(25, diamond.stakeGetTotalStaked(secondDay));

        assertEq(2, diamond.stakeGetUserWithdrawalCount(account1));

        Transaction[] memory withdrawals = diamond.stakeGetUserWithdrawalList(account1);
        assertEq(2, withdrawals.length);
        assertEq(50, withdrawals[0].amount);
        assertEq(w1Timestamp, withdrawals[0].timestamp);
        assertEq(25, withdrawals[1].amount);
        assertEq(w2Timestamp, withdrawals[1].timestamp);

        Transaction memory withdrawal = diamond.stakeGetUserWithdrawalAt(account1, 0);
        assertEq(50, withdrawal.amount);
        assertEq(w1Timestamp, withdrawal.timestamp);
        withdrawal = diamond.stakeGetUserWithdrawalAt(account1, 1);
        assertEq(25, withdrawal.amount);
        assertEq(w2Timestamp, withdrawal.timestamp);
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
        diamond.stakeRecordPayout(address(this), address(payoutToken), 500);

        uint256 currentDay = _getCurrentDay();
        assertEq(1500, diamond.stakeGetPayoutPoolAmountAtDay(address(payoutToken), currentDay));
    }

    function test_StakeRecordPayout_Success_DifferentDays() public {
        payoutToken.mint(address(this), 1500);
        payoutToken.approve(address(diamond), 1500);

        uint256 firstDay = _getCurrentDay();

        diamond.stakeRecordPayout(address(this), address(payoutToken), 1000);
        
        // Move to the next day
        vm.warp(block.timestamp + 1 days);
        uint256 secondDay = _getCurrentDay();
        assertNotEq(firstDay, secondDay);

        diamond.stakeRecordPayout(address(this), address(payoutToken), 500);

        assertEq(1000, diamond.stakeGetPayoutPoolAmountAtDay(address(payoutToken), firstDay));
        assertEq(500, diamond.stakeGetPayoutPoolAmountAtDay(address(payoutToken), secondDay));
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


    // // ================================================
    // // Claim Payouts
    // // ================================================

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
        assertEq(100, diamond.stakeGetTotalClaimedForToken(address(payoutToken)));

        assertEq(block.timestamp, diamond.stakeGetLastClaimTime(account1, address(payoutToken)));
        assertEq(1, diamond.stakeGetUserClaimCount(account1, address(payoutToken)));

        Transaction[] memory claims = diamond.stakeGetUserClaimList(account1, address(payoutToken));
        assertEq(1, claims.length);
        assertEq(100, claims[0].amount);
        assertEq(block.timestamp, claims[0].timestamp);

        Transaction memory claim = diamond.stakeGetUserClaimAt(account1, address(payoutToken), 0);
        assertEq(100, claim.amount);
        assertEq(block.timestamp, claim.timestamp);

        // do a claim the next day
        vm.warp(block.timestamp + 1 days);
        uint256 secondClaimTime = block.timestamp;
        sig = _computeDefaultSig(
            abi.encodePacked(uint(50), address(payoutToken), account1),
            secondClaimTime + 10 seconds
        );        
        diamond.stakeClaimPayouts(50, address(payoutToken), account1, sig);

        assertEq(150, payoutToken.balanceOf(account1));
        assertEq(150, diamond.stakeGetTotalClaimedForToken(address(payoutToken)));

        assertEq(secondClaimTime, diamond.stakeGetLastClaimTime(account1, address(payoutToken)));
        assertEq(2, diamond.stakeGetUserClaimCount(account1, address(payoutToken)));

        claims = diamond.stakeGetUserClaimList(account1, address(payoutToken));
        assertEq(2, claims.length);
        assertEq(50, claims[1].amount);
        assertEq(secondClaimTime, claims[1].timestamp);

        claim = diamond.stakeGetUserClaimAt(account1, address(payoutToken), 1);
        assertEq(50, claim.amount);
        assertEq(secondClaimTime, claim.timestamp);
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

    // // ================================================
    // // Multiple users
    // // ================================================

    function test_StakingTotalStaked_MultipleUsers() public {
        // Initial total staked should be 0
        assertEq(diamond.stakeGetTotalStaked(_getCurrentDay()), 0);

        // User1 deposits 100
        diamond.stakeDeposit(account1, 100);
        assertEq(diamond.stakeGetTotalStaked(_getCurrentDay()), 100);

        // User2 deposits 150 after 1 day
        vm.warp(block.timestamp + 1 days);
        diamond.stakeDeposit(account2, 150);
        assertEq(diamond.stakeGetTotalStaked(_getCurrentDay()), 250);

        // User1 withdraws 50 after 1 day
        vm.warp(block.timestamp + 1 days);
        diamond.stakeWithdraw(account1, 50);
        assertEq(diamond.stakeGetTotalStaked(_getCurrentDay()), 200);

        // User2 deposits another 100 after 1 day
        vm.warp(block.timestamp + 1 days);
        diamond.stakeDeposit(account2, 100);
        assertEq(diamond.stakeGetTotalStaked(_getCurrentDay()), 300);

        // User1 withdraws remaining 50 after 1 day
        vm.warp(block.timestamp + 1 days);
        diamond.stakeWithdraw(account1, 50);
        assertEq(diamond.stakeGetTotalStaked(_getCurrentDay()), 250);

        // User2 withdraws 200 after 1 day
        vm.warp(block.timestamp + 1 days);
        diamond.stakeWithdraw(account2, 200);
        assertEq(diamond.stakeGetTotalStaked(_getCurrentDay()), 50);

        // Final check
        assertEq(diamond.stakeGetUserTotalStaked(account1, _getCurrentDay()), 0);
        assertEq(diamond.stakeGetUserTotalStaked(account2, _getCurrentDay()), 50);
    }
}