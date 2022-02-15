pragma solidity ^0.4.24;

import "./Ownable.sol";

contract Stoppable is Ownable{

  bool private stopped = false;

  event ToggleContractActive(bool);

  function toggleConctractActive() onlyOwner() public {
      stopped = !stopped;
      emit ToggleContractActive(stopped);
  }

  modifier notInStoppedState { if (!stopped) _; }
}
