// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface ERC721 {
   //function balanceOf(address) external;
    //function ownerOf(uint)external;
    //function safeTransferFrom(address, address, uint)external;
    //function transferFrom(address, address, uint) external;
    //function approve(address, uint) external;
    //function getApproved(uint) external;
    //function setApprovalForAll(address, address) external;
    //function isApprovedForAll(address, address) external;
    function safeTransferFrom(address, address, uint, bytes calldata) external;
}

contract nftDex {

    uint orderCounter;

    address owner;

    struct Order {
        uint price;
        uint tokenId;
        address tokenCollection;
        address creator;
    }

    mapping (uint => Order) public orders;

    constructor() {
        owner = msg.sender;
    }

    function createOrder(uint price, uint tokenId, address tokenCollection) external {
        require(price > 0 && tokenCollection != address(0));
        ERC721(tokenCollection).safeTransferFrom(msg.sender, address(this), tokenId, "");
        orders[orderCounter] = Order(price, tokenId, tokenCollection, msg.sender);
        orderCounter += 1;
    }

    function acceptOrder(uint orderId) external payable{
        Order memory curOrd = orders[orderId];
        require(msg.sender != curOrd.creator, "Can't buy your own NFT");
        require(curOrd.tokenCollection != address(0));
        require(msg.value == curOrd.price, "Not the right price");
        (bool success, ) = address(this).call{value: curOrd.price}("");
        if (success) {
            ERC721(curOrd.tokenCollection).safeTransferFrom(address(this), msg.sender, curOrd.tokenId, "");
            orders[orderId].tokenCollection = address(0);
        }
    }

    function cancelOrder(uint orderId) external {
        require(msg.sender == orders[orderId].creator);
        orders[orderId].tokenCollection = address(0);
    }
}