// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Logging {
    event Msg(address origin, address sender, uint value, uint gas, bytes data, bytes4 sig);

    modifier logging {
        emit Msg(tx.origin, msg.sender, msg.value, gasleft(), msg.data, msg.sig);
        _;
    }
}