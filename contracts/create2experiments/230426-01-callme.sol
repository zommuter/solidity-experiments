// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../ethernaut/3-coinflip.sol";
address constant cheaterContract = 0xAC89a249e6148FEbFB045e49fcb875BAD918EDd2;

contract Caller {
    constructor() {
        CoinFlip(cheaterContract).cheat();
    }

    function selfdestroy() public {
        selfdestruct(payable(msg.sender));
    }
}