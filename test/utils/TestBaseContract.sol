// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "forge-std/Test.sol";

import { MessageHashUtils } from "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import { ERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import { IDiamondCut } from "lib/diamond-2-hardhat/contracts/interfaces/IDiamondCut.sol";
import { DiamondProxy } from "src/generated/DiamondProxy.sol";
import { IDiamondProxy } from "src/generated/IDiamondProxy.sol";
import { LibDiamondHelper } from "src/generated/LibDiamondHelper.sol";
import { InitDiamond } from "src/init/InitDiamond.sol";
import { AuthSignature } from "src/shared/Structs.sol";
import { LibAuth } from "src/libs/LibAuth.sol";

contract MockERC20 is ERC20 {
  constructor() ERC20("MockERC20", "MOCKERC20") {}
  function mint(address account, uint256 value) external {
    _mint(account, value);
  }  
}

abstract contract TestBaseContract is Test {
  address public owner = address(this);

  uint public signer_key = 0x91;
  address public signer = vm.addr(signer_key);

  uint public account1_key = 0x1234;
  address public account1 = vm.addr(account1_key);

  uint public account2_key = 0x12345;
  address public account2 = vm.addr(account2_key);

  IDiamondProxy public diamond;
  MockERC20 public tribalToken;

  function setUp() public virtual {
    // console2.log("\n -- Test Base\n");

    // console2.log("Test contract address, aka account0", address(this));
    // console2.log("msg.sender during setup", msg.sender);

    vm.label(signer, "Default signer");
    vm.label(owner, "Owner");
    vm.label(account1, "Account 1");
    vm.label(account2, "Account 2");

    // console2.log("Deploy diamond");
    diamond = IDiamondProxy(address(new DiamondProxy(owner)));

    // console2.log("Deploy Mock ERC20");
    tribalToken = new MockERC20();

    // console2.log("Cut and init");
    IDiamondCut.FacetCut[] memory cut = LibDiamondHelper.deployFacetsAndGetCuts(address(diamond));
    InitDiamond init = new InitDiamond();
    diamond.diamondCut(cut, address(init), abi.encodeWithSelector(init.init.selector, address(tribalToken), signer));
  }

  function _computeDefaultSig(bytes memory _data, uint _deadline) internal view returns (AuthSignature memory) {
    return _computeSig(signer_key, _data, _deadline);
  }

  function _computeSig(uint _key, bytes memory _data, uint _deadline) internal view returns (AuthSignature memory) {
    bytes32 sigHash = MessageHashUtils.toEthSignedMessageHash(
      LibAuth.generateSignaturePayload(_data, _deadline)
    );
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(_key, sigHash);
    return AuthSignature({
      signature: abi.encodePacked(r, s, v),
      deadline: _deadline
    });
  }  
}
