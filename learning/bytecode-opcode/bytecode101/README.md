# Dissecting EVM bytecode  

## Compile contract and returned bytecode

A very simple contract:
```
contract ruturnOpcode {
    constructor() public payable {

    }

}
```
once compiled, will return a bytecode. In this example, this contract will return
```
6080604052603f8060116000396000f3fe6080604052600080fdfea26469706673582212209da86916af98aae2b88dd73cde282a5e66f3106301696607b02046b8e1bf6f0164736f6c63430007000033
```

## Bytecode Basics
The EVM uses a set of instructions (called opcodes) to execute specific tasks. At the time of writing, there are 140 unique opcodes. Together, these opcodes allow the EVM to be Turing-complete. This means the EVM is able to compute (almost) anything, given enough resources. Because opcodes are 1 byte, there can only be a maximum of 256 (16²) opcodes. For simplicity's sake, we can split all opcodes into the following categories:  
Stack-manipulating opcodes (POP, PUSH, DUP, SWAP)  
Arithmetic/comparison/bitwise opcodes (ADD, SUB, GT, LT, AND, OR)  
Environmental opcodes (CALLER, CALLVALUE, NUMBER)  
Memory-manipulating opcodes (MLOAD, MSTORE, MSTORE8, MSIZE)  
Storage-manipulating opcodes (SLOAD, SSTORE)  
Program counter related opcodes (JUMP, JUMPI, PC, JUMPDEST)  
Halting opcodes (STOP, RETURN, REVERT, INVALID, SELFDESTRUCT)  

ref: https://medium.com/mycrypto/the-ethereum-virtual-machine-how-does-it-work-9abac2b7c9e

## First part

Every compiled Smart Contract bytecode start with 6080604052.  
Opcode 60 is 'push1', so it push the next byte to the stack. 80 is now at position 00 of the stack.  
Again, opcode 60, push1, with 40, so now 40 is at 00 of stack and 80 is at 01.  
Opcode 52, 'mstore', store in memory the second value of the stack at the address that is the first value of the stack, which means that mstore stores value '80' at address ('40' + 32bytes) and burns those 2 values. So now the stack is empty and memory slot 0x50 has the value '0x00000000000000000000000000000080'.    
So '6080604052' is 'PUSH1 0x60 PUSH1 0x40 MSTORE'.  

## Second part

The second part of this bytecode is 603f8060116000396000f3fe.  
Opcode 60, 'push1', pushes byte 3f (value 63) to the empty stack.  
Opcode 80, 'dup1', clones the last value of the stack, so now the stack has 3f at location 0 and 1.  
Opcode 60, 'push1', pushes byte 11 (value 17) to the stack. Stack is now 11, 3f, 3f.  
Opcode 60, 'push1', pushes byte 00 to the stack. Stack is now 00, 11, 3f, 3f.  
Opcode 39, 'codecopy', takes the 3 lowest value of the stack (00 (destOffset), 11 (offset), 3f (length)), burns them, and copy the code like so: 'memory[destOffset:destOffset+length] = address(this).code[offset:offset+length]', so it copies to memory from location 00 to 3f the code from the calldata from position 11 to 11+3f.  
So bytes from value 18 to 18+63 = 81 from the calldata:  
6080604052600080fdfea26469706673582212209da86916af98aae2b88dd73cde282a5e66f3106301696607b02046b8e1bf6f0164736f6c63430007000033  
are now in the memory and the stack is now 3f.  
Opcode 60, 'push1', pushes byte 00 to the stack, that is now 00, 3f.  
Opcode f3, 'return', returns memory bytes by taking the 2 lowest value of the stack ('p': the position where your value is stored in memory, 's': the size of your stored data) and burns those 2 values, so opcode f3 with '00, 3f' in the stack will return from byte 00 to byte 00 + 3f (value 63).  
Opcode fe is an invalid opcode, just to be sure that IF the code keep executing after opcode 'fd' the line before, the code would ends here. Better safe than sorry.  
So 603f8060116000396000f3fe is 'PUSH1 3f DUP1 PUSH1 11 PUSH1 00 CODECOPY PUSH1 00 RETURN INVALID'

That stops the code from running.

# Going deeper

The first and second part of our bytecode pushed that huge chunck of bytecode:  
6080604052600080fdfea26469706673582212209da86916af98aae2b88dd73cde282a5e66f3106301696607b02046b8e1bf6f0164736f6c63430007000033
to the memory, filling up positions 0x0, 0x10, 0x20 and 0x30 of the memory.
But what does that bytecode means.

'6080604052600080fdfe', the very beginning of the bytecode left, looks familiar. After that part, the rest of the bytecode doesn't look like anything usefull.  
So let's focuse on '6080604052600080fdfe'.  
Opcode 60, 'push1', pushes byte 80 to the stack.  
Opcode 60, 'push1', pushes byte 40 to the stack. 
Opcode 52, 'mstore', store in memory the second value of the stack at the address that is the first value of the stack, which means that mstore stores value '80' at address ('40' + 32bytes) and burns those 2 values. So now the stack is empty and memory slot 0x50 has the value '0x00000000000000000000000000000080'.  
Opcode 60, 'push1', pushes byte 00 to the stack.
Opcode 80, 'dup1', clones the last value of the stack, so now the stack has 00 at location 0 and 1. 
Opcode fd, 'revert', reverts the call and end the execution of the code, so we have reach the end of our code.
Opcode fe is an invalid opcode.  