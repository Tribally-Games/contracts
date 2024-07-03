// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.24;

import { IERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { LibAppStorage } from "src/libs/LibAppStorage.sol";


library LibTribalToken {
    function transferFrom(address _from, uint256 _amount) internal {
        IERC20(LibAppStorage.diamondStorage().tribalToken).transferFrom(_from, address(this), _amount);
    }

    function transferTo(address _to, uint256 _amount) internal {
        IERC20(LibAppStorage.diamondStorage().tribalToken).transfer(_to, _amount);
    }
}
