pragma solidity ^0.8.27;

import { IERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { AuthSignature, Transaction } from "src/shared/Structs.sol";
import { AppStorage, LibAppStorage } from "src/libs/LibAppStorage.sol";
import { LibErrors } from "src/libs/LibErrors.sol";
import { LibAuth } from "../libs/LibAuth.sol";

contract StakingFacet {
    event Deposited(address user, uint256 amount);
    event Withdrawn(address user, uint256 amount);
    event Claimed(address user, address claimToken, uint256 amount);
    event PayoutRecorded(address token, uint256 amount, uint256 day);

    function depositStake(address user, uint256 amount) external {
        if (amount == 0) {
          revert LibErrors.AmountMustBeGreaterThanZero();
        }

        AppStorage storage s = LibAppStorage.diamondStorage();

        if (!IERC20(s.stakingToken).transferFrom(user, address(this), amount)) {
          revert LibErrors.TransferFailed();
        }

        s.stakingUserDeposits[user].push(Transaction(block.timestamp, amount));
        s.stakingUserTotalStaked[user] += amount;
        s.stakingTotalStaked += amount;

        emit Deposited(user, amount);
    }

    function withdrawStake(address user, uint256 amount) external {
        if (amount == 0) {
          revert LibErrors.AmountMustBeGreaterThanZero();
        }

        AppStorage storage s = LibAppStorage.diamondStorage();

        if (s.stakingUserTotalStaked[user] < amount) {
          revert LibErrors.InsufficientBalanceError();
        }

        if (!IERC20(s.stakingToken).transferFrom(address(this), user, amount)) {
          revert LibErrors.TransferFailed();
        }

        s.stakingUserWithdrawals[user].push(Transaction(block.timestamp, amount));
        s.stakingUserTotalStaked[user] -= amount;
        s.stakingTotalStaked -= amount;

        emit Withdrawn(user, amount);
    }

    function claimPayouts(uint256 amount, address claimToken, address user, AuthSignature calldata signature) external {
        AppStorage storage s = LibAppStorage.diamondStorage();
        
        if (amount == 0) {
          revert LibErrors.AmountMustBeGreaterThanZero();
        }
        
        // Use LibAuth.assertValidSignature instead of verifySignature
        LibAuth.assertValidSignature(
            user,
            s.signer,
            signature,
            abi.encodePacked(amount, claimToken, user)
        );

        if (!IERC20(claimToken).transferFrom(address(this), user, amount)) {
          revert LibErrors.TransferFailed();
        }

        s.stakingUserClaims[user][claimToken].push(Transaction(block.timestamp, amount));
        s.stakingUserLastClaimTime[user][claimToken] = block.timestamp;
        s.stakingTotalClaimed[claimToken] += amount;

        emit Claimed(user, claimToken, amount);
    }

    function recordPayout(address token, uint256 amount) external {
        if (amount == 0) {
          revert LibErrors.AmountMustBeGreaterThanZero();
        }

        if (!IERC20(token).transferFrom(msg.sender, address(this), amount)) {
          revert LibErrors.TransferFailed();
        }

        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 currentDay = block.timestamp / 1 days;
        uint256 payoutPoolLength = s.stakingPayoutPool[token].length;
        
        if (payoutPoolLength > 0 && s.stakingPayoutPool[token][payoutPoolLength - 1].timestamp / 1 days == currentDay) {
            // Add to existing payout for the current day
            s.stakingPayoutPool[token][payoutPoolLength - 1].amount += amount;
        } else {
            // Create a new payout entry for the current day
            s.stakingPayoutPool[token].push(Transaction(block.timestamp, amount));
        }

        emit PayoutRecorded(token, amount, currentDay);
    }

    function getUserTotalStaked(address user) external view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.stakingUserTotalStaked[user];
    }

    function getUserDepositCount(address user) external view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.stakingUserDeposits[user].length;
    }

    function getUserWithdrawalCount(address user) external view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.stakingUserWithdrawals[user].length;
    }

    function getUserClaimCount(address user, address token) external view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.stakingUserClaims[user][token].length;
    }

    function getUserDeposits(address user) external view returns (Transaction[] memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.stakingUserDeposits[user];
    }

    function getUserWithdrawals(address user) external view returns (Transaction[] memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.stakingUserWithdrawals[user];
    }

    function getUserClaims(address user, address token) external view returns (Transaction[] memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.stakingUserClaims[user][token];
    }

    function getLastClaimTime(address user, address token) external view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.stakingUserLastClaimTime[user][token];
    }

    function getDailyPayoutPoolAmount(address token, uint256 day) external view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 payoutPoolLength = s.stakingPayoutPool[token].length;
        for (uint256 i = 0; i < payoutPoolLength; i++) {
            if (s.stakingPayoutPool[token][i].timestamp / 1 days == day) {
                return s.stakingPayoutPool[token][i].amount;
            }
        }
        return 0;
    }

    function getTotalClaimedForToken(address token) external view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.stakingTotalClaimed[token];
    }
}
