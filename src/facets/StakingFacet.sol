pragma solidity ^0.8.27;

import { IERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { AuthSignature, Transaction } from "src/shared/Structs.sol";
import { AppStorage, LibAppStorage } from "src/libs/LibAppStorage.sol";
import { LibErrors } from "src/libs/LibErrors.sol";
import { LibAuth } from "../libs/LibAuth.sol";

contract StakingFacet {
    /** @dev Emitted when a user deposits stake
     * @param user Address of the user who deposited
     * @param amount Amount of tokens deposited
     */
    event StakeDeposited(address user, uint256 amount);

    /** @dev Emitted when a user withdraws stake
     * @param user Address of the user who withdrew
     * @param amount Amount of tokens withdrawn
     */
    event StakeWithdrawn(address user, uint256 amount);

    /** @dev Emitted when a user claims payouts
     * @param user Address of the user who claimed
     * @param claimToken Address of the token claimed
     * @param amount Amount of tokens claimed
     */
    event StakePayoutClaimed(address user, address claimToken, uint256 amount);

    /** @dev Emitted when a payout is recorded
     * @param token Address of the token paid out
     * @param amount Amount of tokens paid out
     * @param day The day the payout was recorded (timestamp / 1 days)
     */
    event StakePayoutRecorded(address token, uint256 amount, uint256 day);

    /** @dev Deposits stake for a user
     * @param user Address of the user depositing stake
     * @param amount Amount of tokens to deposit
     */
    function stakeDeposit(address user, uint256 amount) external {
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

        emit StakeDeposited(user, amount);
    }

    /** @dev Withdraws stake for a user
     * @param user Address of the user withdrawing stake
     * @param amount Amount of tokens to withdraw
     */
    function stakeWithdraw(address user, uint256 amount) external {
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

        emit StakeWithdrawn(user, amount);
    }

    /** @dev Allows a user to claim staking payouts
     * @param amount Amount of tokens to claim
     * @param claimToken Address of the token to claim
     * @param user Address of the user claiming
     * @param signature AuthSignature for verification
     */
    function stakeClaimPayouts(uint256 amount, address claimToken, address user, AuthSignature calldata signature) external {
        AppStorage storage s = LibAppStorage.diamondStorage();
        
        if (amount == 0) {
          revert LibErrors.AmountMustBeGreaterThanZero();
        }
        
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

        emit StakePayoutClaimed(user, claimToken, amount);
    }

    /** @dev Records a staking payout for a specific token
     * @param token Address of the token being paid out
     * @param amount Amount of tokens being paid out
     */
    function stakeRecordPayout(address token, uint256 amount) external {
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

        emit StakePayoutRecorded(token, amount, currentDay);
    }

    /** @dev Gets the total amount staked by a user
     * @param user Address of the user
     * @return Total amount staked by the user
     */
    function stakeGetUserTotalStaked(address user) external view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.stakingUserTotalStaked[user];
    }

    /** @dev Gets the number of stake deposits made by a user
     * @param user Address of the user
     * @return Number of deposits
     */
    function stakeGetUserDepositCount(address user) external view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.stakingUserDeposits[user].length;
    }

    /** @dev Gets the number of stake withdrawals made by a user
     * @param user Address of the user
     * @return Number of withdrawals
     */
    function stakeGetUserWithdrawalCount(address user) external view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.stakingUserWithdrawals[user].length;
    }

    /** @dev Gets the number of stake claims made by a user for a specific token
     * @param user Address of the user
     * @param token Address of the token
     * @return Number of claims
     */
    function stakeGetUserClaimCount(address user, address token) external view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.stakingUserClaims[user][token].length;
    }

    /** @dev Gets all stake deposits made by a user
     * @param user Address of the user
     * @return Array of Transaction structs representing deposits
     */
    function stakeGetUserDeposits(address user) external view returns (Transaction[] memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.stakingUserDeposits[user];
    }

    /** @dev Gets all stake withdrawals made by a user
     * @param user Address of the user
     * @return Array of Transaction structs representing withdrawals
     */
    function stakeGetUserWithdrawals(address user) external view returns (Transaction[] memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.stakingUserWithdrawals[user];
    }

    /** @dev Gets all stake claims made by a user for a specific token
     * @param user Address of the user
     * @param token Address of the token
     * @return Array of Transaction structs representing claims
     */
    function stakeGetUserClaims(address user, address token) external view returns (Transaction[] memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.stakingUserClaims[user][token];
    }

    /** @dev Gets the timestamp of the last stake claim made by a user for a specific token
     * @param user Address of the user
     * @param token Address of the token
     * @return Timestamp of the last claim
     */
    function stakeGetLastClaimTime(address user, address token) external view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.stakingUserLastClaimTime[user][token];
    }

    /** @dev Gets the stake payout pool amount for a specific token on a given day
     * @param token Address of the token
     * @param day The day to query (timestamp / 1 days)
     * @return Amount in the payout pool for the specified day
     */
    function stakeGetDailyPayoutPoolAmount(address token, uint256 day) external view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 payoutPoolLength = s.stakingPayoutPool[token].length;
        for (uint256 i = 0; i < payoutPoolLength; i++) {
            if (s.stakingPayoutPool[token][i].timestamp / 1 days == day) {
                return s.stakingPayoutPool[token][i].amount;
            }
        }
        return 0;
    }

    /** @dev Gets the total amount claimed for a specific staking token
     * @param token Address of the token
     * @return Total amount claimed
     */
    function stakeGetTotalClaimedForToken(address token) external view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.stakingTotalClaimed[token];
    }
}
