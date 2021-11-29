pragma solidity ^0.7.0;

interface Challenge {
    function setSolver(address) external;
}

contract solverContract {
    
    //Where yourAddress is the targeted address instance you get from Ethernaut
    Challenge challenge = Challenge(yourAddress);
    
    function attack() public {
        bytes memory bytecode = hex"600a600c600039600a6000f3602a60005260206000f3";
        bytes32 salt = 0;
        address solver;
    
        assembly {
            solver := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
    
        challenge.setSolver(solver);
    }   
}