

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ERC20 {
    function transferFrom(address, address, uint) external;
}

contract olivierSwap {

    uint idCounter;

    struct Order {
        uint Id;
        uint amountA;
        uint amountB;
        address tokenA;
        address tokenB;
        address creator;
    }

    mapping (uint => Order) orders;

    function createOrder(address _tokenA, address _tokenB, uint _amountA, uint _amountB) external {
        ERC20(_tokenA).transferFrom(msg.sender, address(this), _amountA);
        idCounter += 1;
        Order memory newOrder = Order(idCounter, _amountA, _amountB, _tokenA, _tokenB);
        orders[idCounter] = newOrder;
    }

    function acceptOrder(uint orderId) external {
        require(orders[orderId].Id != 0);
        bool success = orders[orderId].tokenA.transfer(msg.sender, orders[orderId].amountA);
        require(success == true);
        orders[orderId].tokenB.transferFrom(msg.sender, orders[orderId].creator, orders[orderId].amountB);
        orders[orderId].Id = 0;
    }

    function cancelOrder(uint orderId) external {
        require(orders[orderId].Id != 0, "Not existing or already deleted order");
        require(orders[orderId].creater == msg.sender, "can't cancel order you didn't create");
        orders[orderId].tokenA.transfer(address(this), msg.sender, orders[orderId].amountA);
        orders[orderId].Id = 0;
    }

}