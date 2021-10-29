pragma solidity ^0.4.0;

contract Election {

    struct Class {
        string name;
        uint voteCount;
    }

    struct Voter {
        bool voted;
        uint voteIndex;
        uint weight;
    }
    address public owner;
    string public name;
    mapping(address => Voter) public voters;
    Class[] public classes;
    uint public auctionEnd;

    event ElectionResult(string name, uint voteCount);

    function Election(string _name, uint durationMinutes, string class1, string class2) public {
        owner = msg.sender;
        name = _name;
        auctionEnd = now + (durationMinutes * 1 minutes);

        classes.push(Class(class1, 0));
        classes.push(Class(class2, 0));
    }

    function authorize (address voter) public {
        require(msg.sender == owner);
        require(!voters[voter].voted);

        voters[voter].weight = 1;
    }

    function vote(uint voteIndex) public {
        require (now < auctionEnd);
        require(!voters[msg.sender].voted);

        voters[msg.sender].voted = true;
        voters[msg.sender].voteIndex = voteIndex;

        classes[voteIndex].voteCount += voters[msg.sender].weight;
    }

    function end() public {
        require(msg.sender == owner);
        require(now >= auctionEnd);

        for(uint i=0; i < classes.length; i++) {
            emit ElectionResult(classes[i].name, classes[i].voteCount);
        }
    }
}
