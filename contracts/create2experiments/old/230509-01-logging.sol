// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Logging {
    event Msg(address origin, address sender, uint value, uint gas, bytes data, bytes4 sig);
    
    constructor() payable {
        emit Msg(tx.origin, msg.sender, msg.value, gasleft(), msg.data, msg.sig);
    }
}

contract Factory is Logging {
    Logging public loggingcontract;

    constructor() payable {
        emit Msg(tx.origin, msg.sender, msg.value, gasleft(), msg.data, msg.sig);
        loggingcontract = new Logging();
    }

    function createNewLogging() external payable returns (Logging) {
        emit Msg(tx.origin, msg.sender, msg.value, gasleft(), msg.data, msg.sig);
        return new Logging();
    }
}