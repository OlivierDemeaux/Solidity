pragma solidity ^0.7.0;

contract revertContract {
    
    fallback() external payable {
        assert(false);
    }
}