// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import "forge-std/Test.sol";

import { ERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import { IDiamondCut } from "lib/diamond-2-hardhat/contracts/interfaces/IDiamondCut.sol";
import { DiamondProxy } from "src/generated/DiamondProxy.sol";
import { IDiamondProxy } from "src/generated/IDiamondProxy.sol";
import { LibDiamondHelper } from "src/generated/LibDiamondHelper.sol";
import { InitDiamond } from "src/init/InitDiamond.sol";

contract MockERC20 is ERC20 {
  constructor() ERC20("MockERC20", "MOCKERC20") {}
  function mint(address account, uint256 value) external {
    _mint(account, value);
  }  
}

abstract contract TestBaseContract is Test {
  address public immutable account0 = address(this);
  address public account1;
  address public account2;

  IDiamondProxy public diamond;
  MockERC20 public tribalToken;

  function setUp() public virtual {
    console2.log("\n -- Test Base\n");

    console2.log("Test contract address, aka account0", address(this));
    console2.log("msg.sender during setup", msg.sender);

    vm.label(account0, "Account 0");
    account1 = vm.addr(1);
    vm.label(account1, "Account 1");
    account2 = vm.addr(2);
    vm.label(account2, "Account 2");

    console2.log("Deploy diamond");
    diamond = IDiamondProxy(address(new DiamondProxy(account0)));

    console2.log("Deploy Mock ERC20");
    tribalToken = new MockERC20();

    console2.log("Cut and init");
    IDiamondCut.FacetCut[] memory cut = LibDiamondHelper.deployFacetsAndGetCuts(address(diamond));
    InitDiamond init = new InitDiamond();
    diamond.diamondCut(cut, address(init), abi.encodeWithSelector(init.init.selector, address(tribalToken), account0));
  }
}
