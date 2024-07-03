// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.24;

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
