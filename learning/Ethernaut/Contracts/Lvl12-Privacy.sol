// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Privacy {

  bool public locked = true;
  uint256 public ID = block.timestamp;
  uint8 private flattening = 10;
  uint8 private denomination = 255;
  uint16 private awkwardness = uint16(now);
  bytes32[3] private data;

  constructor(bytes32[3] memory _data) public {
    data = _data;
  }
  
  function unlock(bytes16 _key) public {
    require(_key == bytes16(data[2]));
    locked = false;
  }

  function show() public returns(bytes16) {
      bytes16 pass = bytes16(bytes32(0x03461a4bc4ff2ab34b4e8bac33aa8bd3cb85d77ed7dc524c78ddb42b3eac5001));
      return(pass);
  }
}