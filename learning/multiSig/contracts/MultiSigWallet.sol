// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

contract MultiSigWallet {
    
    event Deposit(address depositer, uint amount, uint balance);
    event SubmitTransaction(address indexed owner, uint indexed txId, address indexed to, uint value, bytes data);
    event ConfirmTransaction(address indexed owner, uint indexed txId);
    event ExecuteTransaction(address indexed owner, uint indexed txId);
    event RevokeConfirmation(address indexed owner, uint indexed txId);
    
    address[] public owners;
    mapping (address => bool) public isOwner;
    uint public numConfirmationsRequired;
    
    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numConfirmations;
    }
    
    // mapping from tx id => owner => bool
    mapping(uint => mapping(address => bool)) public isConfirmed;
    
    Transaction[] public transactions;
    
    modifier onlyOwner() {
        require(isOwner[msg.sender]);
        _;
    }
    
    modifier txExists(uint _txId) {
        require (_txId < transactions.length, "transaction doesn't exist");
        _;
    }
    
    modifier notExecuted(uint _txId) {
        require(!transactions[_txId].executed, "tx already executed");
        _;
    }
    
    modifier notConfirmed(uint _txId) {
        require (!isConfirmed[_txId][msg.sender], "owner already confirmed this tx");
        _;
    }
    
    constructor (address[] memory _owners, uint _numConfirmationsRequired) {
        
        require(_owners.length > 0, "at least one owner is needed");
        require(_numConfirmationsRequired > 0 && _owners.length >= _numConfirmationsRequired);
        
        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            
            require(owner != address(0), "owner can't be 0 address");
            require(!isOwner[owner], "address already owner");
            
            isOwner[owner] = true;
            owners.push(owner);
        }
        
        numConfirmationsRequired = _numConfirmationsRequired;
    }
    
    function submitTransaction(address _to, uint _value, bytes memory _data) public onlyOwner {
        
        uint txId = transactions.length;
        
        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false,
            numConfirmations: 0
        }));
        
        emit SubmitTransaction(msg.sender, txId, _to, _value, _data);
    }
    
    function confirmTransaction(uint _txId) public onlyOwner txExists(_txId) notExecuted(_txId) notConfirmed(_txId) {
        
        Transaction storage transaction = transactions[_txId];
        transaction.numConfirmations += 1;
        isConfirmed[_txId][msg.sender] = true;
        
        emit ConfirmTransaction(msg.sender, _txId);
    }
    
    function executeTransaction(uint _txId) public onlyOwner txExists(_txId) notExecuted(_txId) {
        
        Transaction storage transaction = transactions[_txId];
        
        require (transaction.numConfirmations >= numConfirmationsRequired, "cannot execute tx");
        
        transaction.executed = true;
        
        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "tx failed");
        
        emit ExecuteTransaction(msg.sender, _txId);
        
    }
    
    function revokeConfirmation(uint _txId) public onlyOwner txExists(_txId) notExecuted(_txId) {
        
        Transaction storage transaction = transactions[_txId];
        
        require(isConfirmed[_txId][msg.sender], "owner has not confirmed this tx");
        
        transaction.numConfirmations -= 1;
        isConfirmed[_txId][msg.sender] = false;
        
        emit RevokeConfirmation(msg.sender, _txId);
    }
    
    receive() payable external {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }
    
     function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    function getTransaction(uint _txId)
        public
        view
        returns (address to, uint value, bytes memory data, bool executed, uint numConfirmations)
    {
        Transaction storage transaction = transactions[_txId];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }
    
}