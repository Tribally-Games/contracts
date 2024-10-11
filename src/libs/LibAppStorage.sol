// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.27;

import {Transaction} from "../shared/Structs.sol";

struct AppStorage {
    bool diamondInitialized;
    uint256 reentrancyStatus;

    /*
    TODO: Customize storage variables here

    NOTE: Once contracts have been deployed you cannot modify the existing entries here. You can only append 
    new entries. Otherwise, any subsequent upgrades you perform will break the memory structure of your 
    deployed contracts.
    */

    /**
    * @dev Keep track of used auth signatures.
    */
    mapping(bytes32 => bool) authSignatures;


    /**
     * @dev The address of TRIBAL.
     */
    address tribalToken;

    /**
     * @dev The address that has the ability to approve withdrawals.
     */
    address signer;

    /**
     * @dev A user's locked balance inside the gateway.
     *
     * Depositing into the gateway increases this balance. Withdrawing from the gateway decreases it.
     */
    mapping(address => uint) locked;    

    /**
     * @dev The ERC20 token used for staking
     */
    address stakingToken;

    /**
     * @dev Total amount of tokens staked
     */
    uint256 stakingTotalStaked;

    /**
     * @dev Total amount claimed per payout token
     */
    mapping(address => uint256) stakingTotalClaimed;

    /**
     * @dev Mapping of user addresses to their claim transactions per payout token
     */
    mapping(address => mapping(address => Transaction[])) stakingUserClaims;

    /**
     * @dev Mapping of user addresses to their last claim time per payout token
     */
    mapping(address => mapping(address => uint256)) stakingUserLastClaimTime;

    /**
     * @dev Mapping of token addresses to their list of payouts
     */
    mapping(address => Transaction[]) stakingPayoutPool;

    /**
     * @dev Mapping of user addresses to their stakingdeposit transactions
     */
    mapping(address => Transaction[]) stakingUserDeposits;
    
    /**
     * @dev Mapping of user addresses to their total staked amount
     */
    mapping(address => uint256) stakingUserTotalStaked;
    
    /**
     * @dev Mapping of user addresses to their staking withdrawal transactions
     */
    mapping(address => Transaction[]) stakingUserWithdrawals;
}


library LibAppStorage {
    bytes32 internal constant DIAMOND_APP_STORAGE_POSITION = keccak256("diamond.app.storage");

    function diamondStorage() internal pure returns (AppStorage storage ds) {
        bytes32 position = DIAMOND_APP_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}
