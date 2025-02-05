pragma solidity ^0.8.24;

import { IERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { AuthSignature, Transaction, StakeMultiplierCurve } from "src/shared/Structs.sol";
import { AppStorage, LibAppStorage } from "src/libs/LibAppStorage.sol";
import { LibErrors } from "src/libs/LibErrors.sol";
import { LibAuth } from "../libs/LibAuth.sol";
import { AccessControl } from "src/shared/AccessControl.sol";

contract StakingFacet is AccessControl {
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

        _userDeposit(user, amount);

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

        _userWithdraw(user, amount);

        if (!IERC20(s.stakingToken).transfer(user, amount)) {
            revert LibErrors.TransferFailed();
        }

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
            msg.sender,
            s.signer,
            signature,
            abi.encodePacked(amount, claimToken, user)
        );

        _userClaim(user, claimToken, amount);

        if (!IERC20(claimToken).transfer(user, amount)) {
          revert LibErrors.TransferFailed();
        }

        emit StakePayoutClaimed(user, claimToken, amount);
    }

    /** @dev Records a staking payout for a specific token
     * @param source Address of the user or contract that is paying out
     * @param token Address of the token being paid out
     * @param amount Amount of tokens being paid out
     */
    function stakeRecordPayout(address source, address token, uint256 amount) external {
        if (amount == 0) {
          revert LibErrors.AmountMustBeGreaterThanZero();
        }

        if (!IERC20(token).transferFrom(source, address(this), amount)) {
          revert LibErrors.TransferFailed();
        }

        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 currentDay = _getCurrentDay();
        uint256 payoutPoolLength = s.stakingPayoutPools[token].length;
        
        if (payoutPoolLength > 0 && s.stakingPayoutPools[token][payoutPoolLength - 1].timestamp == currentDay) {
            // Add to existing payout for the current day
            s.stakingPayoutPools[token][payoutPoolLength - 1].amount += amount;
        } else {
            // Create a new payout entry for the current day
            s.stakingPayoutPools[token].push(Transaction(currentDay, amount));
        }

        emit StakePayoutRecorded(token, amount, currentDay);
    }

    /** @dev Gets the total amount staked across all users for a specific day.
     * @param day The day to query (timestamp / 1 days)
     * @return Total amount staked.
     */
    function stakeGetTotalStaked(uint256 day) external view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 length = s.stakingTotalStaked.length;
        while (length > 0 && s.stakingTotalStaked[length - 1].timestamp > day) {
            length--;
        }
        if (length > 0) {
            return s.stakingTotalStaked[length - 1].amount;
        } else {
            return 0;
        }
    }

    /** @dev Gets the total amount staked by a user for a specific day.
     * @param user Address of the user
     * @param day The day to query (timestamp / 1 days)
     * @return Total amount staked by the user
     */
    function stakeGetUserTotalStaked(address user, uint256 day) external view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 length = s.stakingUserTotalStaked[user].length;
        while (length > 0 && s.stakingUserTotalStaked[user][length - 1].timestamp > day) {
            length--;
        }
        if (length > 0) {
            return s.stakingUserTotalStaked[user][length - 1].amount;
        } else {
            return 0;
        }
    }

    /** @dev Gets the number of stake deposits made by a user
     * @param user Address of the user
     * @return Number of deposits
     */
    function stakeGetUserDepositCount(address user) external view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.stakingUserDeposits[user].length;
    }

    /** @dev Gets all stake deposits made by a user
     * @param user Address of the user
     * @return Array of Transaction structs representing deposits
     */
    function stakeGetUserDepositList(address user) external view returns (Transaction[] memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.stakingUserDeposits[user];
    }


    /** @dev Gets a specific stake deposit made by a user
     * @param user Address of the user
     * @param index Index in the list
     * @return Transaction struct at the specified index
     */
    function stakeGetUserDepositAt(address user, uint256 index) external view returns (Transaction memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.stakingUserDeposits[user][index];
    }

    /** @dev Gets the number of stake withdrawals made by a user
     * @param user Address of the user
     * @return Number of withdrawals
     */
    function stakeGetUserWithdrawalCount(address user) external view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.stakingUserWithdrawals[user].length;
    }

    /** @dev Gets all stake withdrawals made by a user
     * @param user Address of the user
     * @return Array of Transaction structs representing withdrawals
     */
    function stakeGetUserWithdrawalList(address user) external view returns (Transaction[] memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.stakingUserWithdrawals[user];
    }    

    /** @dev Gets a specific stake withdrawal made by a user
     * @param user Address of the user
     * @param index Index in the list
     * @return Transaction struct at the specified index
     */
    function stakeGetUserWithdrawalAt(address user, uint256 index) external view returns (Transaction memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.stakingUserWithdrawals[user][index];
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

    /** @dev Gets all stake claims made by a user for a specific token
     * @param user Address of the user
     * @param token Address of the token
     * @return Array of Transaction structs representing claims
     */
    function stakeGetUserClaimList(address user, address token) external view returns (Transaction[] memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.stakingUserClaims[user][token];
    }

    /** @dev Gets a specific stake claim made by a user for a specific token
     * @param user Address of the user
     * @param token Address of the token
     * @param index Index in the list
     * @return Transaction struct at the specified index
     */
    function stakeGetUserClaimAt(address user, address token, uint256 index) external view returns (Transaction memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.stakingUserClaims[user][token][index];
    }

    /** @dev Gets the timestamp of the last stake claim made by a user for a specific token
     * @param user Address of the user
     * @param token Address of the token
     * @return Timestamp of the last claim
     */
    function stakeGetLastClaimTime(address user, address token) external view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 length = s.stakingUserClaims[user][token].length;
        if (length > 0) {
            return s.stakingUserClaims[user][token][length - 1].timestamp;
        } else {
            return 0;
        }
    }

    /** @dev Gets the stake payout pool amount for a specific token on a given day
     * @param token Address of the token
     * @param day The day to query (timestamp / 1 days)
     * @return Amount in the payout pool for the specified day
     */
    function stakeGetPayoutPoolAmountAtDay(address token, uint256 day) external view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 payoutPoolLength = s.stakingPayoutPools[token].length;
        while (payoutPoolLength > 0 && s.stakingPayoutPools[token][payoutPoolLength - 1].timestamp > day) {
            payoutPoolLength--;
        }
        if (payoutPoolLength > 0) {
            return s.stakingPayoutPools[token][payoutPoolLength - 1].amount;
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


    /** @dev Gets the stake multiplier curve
     * @return Coefficient value (scaled by 1e8)
     */
    function stakeGetMultiplierCurve() external view returns (StakeMultiplierCurve memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.stakeMultiplierCurve;
    }

    /** @dev Updates the stake multiplier curve
     * @param newCurve The new stake multiplier curve
     */
    function stakeUpdateMultiplierCurve(StakeMultiplierCurve calldata newCurve) external isAdmin {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.stakeMultiplierCurve = newCurve;
    }

    /// PRIVATE FUNCTIONS ///   

    /** @dev Gets the current day number from timestamp
     * @return Current day number
     */
    function _getCurrentDay() private view returns (uint256) {
        return block.timestamp / 1 days;
    }


    function _userDeposit(address user, uint256 amount) private {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 currentDay = _getCurrentDay();

        s.stakingUserDeposits[user].push(Transaction(block.timestamp, amount));

        if (s.stakingUserTotalStaked[user].length > 0) {
            Transaction storage lastUserTotalStaked = s.stakingUserTotalStaked[user][s.stakingUserTotalStaked[user].length - 1];

            if (lastUserTotalStaked.timestamp == currentDay) {
                lastUserTotalStaked.amount += amount;
            } else {
                s.stakingUserTotalStaked[user].push(Transaction(currentDay, lastUserTotalStaked.amount + amount));
            }
        } else {
            s.stakingUserTotalStaked[user].push(Transaction(currentDay, amount));
        }

        if (s.stakingTotalStaked.length > 0) {
            Transaction storage lastTotalStaked = s.stakingTotalStaked[s.stakingTotalStaked.length - 1];
            if (lastTotalStaked.timestamp == currentDay) {
                lastTotalStaked.amount += amount;
            } else {
                s.stakingTotalStaked.push(Transaction(currentDay, lastTotalStaked.amount + amount));
            }
        } else {
            s.stakingTotalStaked.push(Transaction(currentDay, amount));
        }
    }


    function _userWithdraw(address user, uint256 amount) private {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 currentDay = _getCurrentDay();

        s.stakingUserWithdrawals[user].push(Transaction(block.timestamp, amount));

        uint256 userTotalStaked = s.stakingUserTotalStaked[user][s.stakingUserTotalStaked[user].length - 1].amount;
        if (userTotalStaked < amount) {
            revert LibErrors.InsufficientBalanceError();
        }
        s.stakingUserTotalStaked[user].push(Transaction(currentDay, userTotalStaked - amount));

        uint256 totalStaked = s.stakingTotalStaked[s.stakingTotalStaked.length - 1].amount;
        s.stakingTotalStaked.push(Transaction(currentDay, totalStaked - amount));
    }


    function _userClaim(address user, address claimToken, uint256 amount) private {
        AppStorage storage s = LibAppStorage.diamondStorage();

        s.stakingUserClaims[user][claimToken].push(Transaction(block.timestamp, amount));
        s.stakingTotalClaimed[claimToken] += amount;
    }
}
