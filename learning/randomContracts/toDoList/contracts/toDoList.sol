// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract ToDo {
    
    struct toDo {
        string message;
        bool done;
    }
    
    mapping(uint => toDo) toDos;
    mapping(address => toDo[]) ownerToDos;
    mapping(address => uint) public counter;
    
    event toDoCreated(address owner, string message, uint id);
    event toDoFinished(address owner, string message, uint id);
    
    modifier toDoExists(uint _id) {
        require (counter[msg.sender] > _id, 'no toDo with matching id');
        _;
    }
    
    function getToDo(uint _id) public view toDoExists(_id) returns(string memory message, bool done) {
        return (ownerToDos[msg.sender][_id].message, ownerToDos[msg.sender][_id].done);
    }
    
    function createToDo(string memory _message) public {

        ownerToDos[msg.sender].push(toDo(_message, false));
        
        emit toDoCreated(msg.sender, _message, counter[msg.sender]);
        counter[msg.sender]++;
    }
    
    function finishedToDo(uint _id) public toDoExists(_id) {
        require(ownerToDos[msg.sender][_id].done == false, 'toDo already done');
        
        ownerToDos[msg.sender][_id].done = true;
        emit toDoFinished(msg.sender, ownerToDos[msg.sender][_id].message, _id);
    }
    
    function getMyToDos() public view returns(string memory ) {
        uint i = 0;
        string memory myToDos;
        
        while( i < counter[msg.sender] ) {
            if (ownerToDos[msg.sender][i].done != true) {
                // check if myToDos string is empty to avoid starting the string with a ','
                if (bytes(myToDos).length == 0) {
                    myToDos =  ownerToDos[msg.sender][i].message;
                }
                else {
                    myToDos =  string(abi.encodePacked(myToDos, ', ', ownerToDos[msg.sender][i].message));
                }
            }
            i++;
        }
        
        return (myToDos);
    }
}