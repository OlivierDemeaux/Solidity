// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract SelfDestructor {

    constructor() public payable {
    }
  function kamikaze(address payable _target) public {
      selfdestruct(_target);
  }
}
