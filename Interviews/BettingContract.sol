// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Helpers {
    event NewModerator(address newModerator);

    mapping (address => bool) moderators;

    constructor() {
        moderators[msg.sender] = true;
    }

    modifier onlyMod() {
        require(moderators[msg.sender] == true, "you must be a moderator to do this");
        _;
    }

    function addModerator(address newModerator) public onlyMod {
        require(moderators[newModerator] == false, "Address already a moderator");
        moderators[newModerator] = true;
        emit NewModerator(newModerator);
    }

    function isModerator(address moderator) public view returns(bool) {
        return(moderators[moderator]);
    }

    function getTimestamp() public view returns(uint) {
        return(block.timestamp);
    }
}

contract BettingContract is Helpers {

    event ContestCreated(uint256 contestId, uint256 startTime, uint256 endTime, uint256 maxBets, address moderator);
    event ContestStarted(uint contestId);
    event ContestEnded(uint contestId, bool homeWin);
    event BetCreated(uint contestId, uint256 betAmount, bool homeWin);
    event Payout(uint256 contestId, uint256 amountPaid, address userPaid);

    uint256 contestCounter;

    enum Status { NotStarted, Started, Ended }

    struct Contest {
        uint256 startTime;
        uint256 endTime;
        uint256 maxBets;
        uint256 currentBets;
        uint256 numberBetsFor;
        uint256 numberBetsAgainst;
        uint256 valueFor;
        uint256 valueAgainst;
        bool result;
        Status status;
    }

    struct Bet {
        uint256 betValue;
        bool homeWin;
        bool exist;
        bool paid;
    }

    mapping (uint => Contest) contests;
    mapping (address => mapping (uint => Bet)) existingBets;

    modifier onlyValidBetTime(uint256 contestId) {
        require(contests[contestId].startTime < block.timestamp && contests[contestId].endTime > block.timestamp, "Too early or too late to bet on this contest");
        _;
    }
    
    constructor() {
        moderators[msg.sender] = true;
    }

    function createContest(uint256 startTime, uint256 endTime, uint256 maxBets) public onlyMod() {
        require(startTime > block.timestamp && startTime < endTime, "this contest timing is wrong");
        require(maxBets > 0, "maxBets cannot be 0");
        contests[contestCounter] = Contest(startTime, endTime, maxBets, 0, 0, 0, 0, 0, false, Status.NotStarted);
        emit ContestCreated(contestId, startTime, endTime, maxBets, msg.sender);
        contestCounter += 1;
    }

    function bet(uint256 contestId, bool homeWin) public payable onlyValidBetTime(contestId) {
        require(contests[contestId].status == Status.Started, "Contest hasn't started or is already finished");
        require(contests[contestId].maxBets > contests[contestId].currentBets, "Max amount of bets reached for this contest");
        require(existingBets[msg.sender][contestId].exist == false, "You already have a existing bet for this contest");
        require(msg.value > 0, "You need to bet some in order to win some");

        contests[contestId].currentBets += 1;
        existingBets[msg.sender][contestId].exist = true;
        existingBets[msg.sender][contestId].homeWin = homeWin;
        existingBets[msg.sender][contestId].betValue = msg.value;
        if(homeWin == true) {
            contests[contestId].numberBetsFor += 1;
            contests[contestId].valueFor += msg.value;
        } else {
            contests[contestId].numberBetsAgainst += 1;
            contests[contestId].valueAgainst += msg.value;
        }
        emit BetCreated(contestId, msg.value, homeWin);
    }

    function beginContest(uint256 contestId) public onlyMod onlyValidBetTime(contestId) {
        require(contests[contestId].status == Status.NotStarted, "Contest already started");
        contests[contestId].status = Status.Started;
        emit ContestStarted(contestId);
    }

    function endContest(uint256 contestId, bool homeWin) public onlyMod {
        require(contests[contestId].endTime < block.timestamp, "Too early to close this contest");
        require(contests[contestId].status == Status.Started);
        contests[contestId].status = Status.Ended;
        contests[contestId].result = homeWin;
        emit ContestEnded(contestId, homeWin);
    }

    function getPayout(uint contestId) public  {
        require(contests[contestId].status == Status.Ended, "this contest has not ended yet");
        require(existingBets[msg.sender][contestId].exist == true, "you didn't bet on this contest");
        require(existingBets[msg.sender][contestId].homeWin == contests[contestId].result, "You didn't win this bet");
        require(existingBets[msg.sender][contestId].paid == false);
        uint256 betEarnings;

        if (contests[contestId].result == true) {
            betEarnings = existingBets[msg.sender][contestId].betValue * contests[contestId].valueAgainst / contests[contestId].valueFor;
        } else {
            betEarnings = existingBets[msg.sender][contestId].betValue *contests[contestId].valueFor / contests[contestId].valueAgainst;
        }

        uint totalPayoutToBetter = existingBets[msg.sender][contestId].betValue + betEarnings;
        existingBets[msg.sender][contestId].paid = true;
        payable(msg.sender).transfer(totalPayoutToBetter);
        emit Payout(contestId, totalPayoutToBetter, msg.sender);
    }

    function getBalance() public view returns(uint) {
        return(address(this).balance);
    }

    function getContestStatus(uint contestId) public view returns(Status) {
        return(contests[contestId].status);
    }

    function getContestInfos(uint contestId) public view onlyValidBetTime(contestId) returns(Contest) {
        return(contests[contestId]);
    }
}