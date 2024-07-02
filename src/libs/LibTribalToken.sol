// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.21;

import { IERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { LibAppStorage } from "./LibAppStorage.sol";


library LibTribalToken {
    function transfer(address _from, address _to, uint256 _amount) internal {
        IERC20(LibAppStorage.diamondStorage().tribalToken).transferFrom(_from, _to, _amount);
    }
}
