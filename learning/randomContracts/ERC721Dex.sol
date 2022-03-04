// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ERC721 {

    function safeTransferFrom(address, address, uint) external;
}

contract nftDex {

    event NewOrder(address, address, uint, uint);
    event tokenSold(address, address, uint, uint, address);
    event orderCancelled(address, address, uint);

    uint orderCounter;

    address owner;

    struct Order {
        uint price;
        uint tokenID;
        address tokenCollection;
        address creator;
    }

    mapping (uint => Order) public orders;

    constructor() {
        owner = msg.sender;
    }

    function createOrder(uint price, uint tokenID, address tokenCollection) external {
        require(price > 0 && tokenCollection != address(0));
        ERC721(tokenCollection).safeTransferFrom(msg.sender, address(this), tokenID);
        orders[orderCounter] = Order(price, tokenID, tokenCollection, msg.sender);
        orderCounter += 1;
        emit NewOrder(msg.sender, tokenCollection, tokenID, price);
    }

    function buyToken(uint orderID) external payable{
        Order memory order = orders[orderID];
        require(msg.sender != order.creator, "Can't buy your own NFT");
        require(order.tokenCollection != address(0));
        require(msg.value == order.price, "Not the right price");
        //sets the order price to 0 as a way to show the order was filled
        orders[orderID].price = 0;
        (bool success, ) = order.creator.call{value: order.price}("");
        require(success, "Couldn't transfer ETH");
        ERC721(order.tokenCollection).safeTransferFrom(address(this), msg.sender, order.tokenID);
        emit tokenSold(msg.sender, order.tokenCollection, order.tokenID, order.price, order.creator);
    }

    function cancelOrder(uint orderID) external {
        Order memory order = orders[orderID];
        require(order.creator == msg.sender && order.price > 0);
        orders[orderID].price = 0;
        ERC721(order.tokenCollection).safeTransferFrom(address(this), order.creator, order.tokenID);
        emit orderCancelled(msg.sender, order.tokenCollection, order.tokenID);
    }
}