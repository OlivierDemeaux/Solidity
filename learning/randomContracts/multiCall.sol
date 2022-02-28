// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

//Simple contract to show a multicall
//To make the call of the 'multiCall' function you need TestMultiCall's Address and the selectors of call1 and call2

contract TestMultiCall {

    function call1() external view returns(uint, uint){
        return(1, block.timestamp);
    }

    function call2() external view returns(uint, uint) {
        return(2, block.timestamp);
    }

    function getSignCall1() external pure returns(bytes memory) {
        return(abi.encodeWithSelector(this.call1.selector));
    }

    function getSignCall2() external pure returns(bytes memory) {
        return(abi.encodeWithSelector(this.call2.selector));
    }
}

contract MultiCall {

    function multiCall(address[] calldata targets, bytes[] calldata data) external view returns(bytes[] memory) {
        require(targets.length == data.length, "not same length");
        bytes[] memory results = new bytes[](data.length);

        for(uint i; i < data.length; i++) {
            (bool success, bytes memory result) = targets[i].staticcall(data[i]);
            require(success, "failed");
            results[i] = result;
        }
        return(results);
    }
}