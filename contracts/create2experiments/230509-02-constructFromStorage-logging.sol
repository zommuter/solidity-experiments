// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Logging {
    event Msg(address origin, address sender, uint value, uint gas, bytes data, bytes4 sig);

    modifier logging {
        emit Msg(tx.origin, msg.sender, msg.value, gasleft(), msg.data, msg.sig);
        _;
    }
}

contract StorageCreate2 is Logging {
    bytes public storedCode;
    
    constructor() payable logging {
    }

    function create2(bytes calldata _code, bytes32 salt) external payable logging returns (address) {  // payable saves some bytes for checking msg.value. Don't blame me for loss.
        storedCode = _code;
        address deployedContract = address(new ConstructorFromStorage{salt: salt}(this));
        delete storedCode;  // small gas refund for not permanently storing the storedCode
        return deployedContract;
    }

    // adapted from https://docs.soliditylang.org/en/develop/control-structures.html#salted-contract-creations-create2
    function predictAdress(bytes32 salt) external view returns (address) {
        address predictedAddress = address(uint160(uint(keccak256(abi.encodePacked(
            bytes1(0xff),
            address(this),
            salt,
            keccak256(abi.encodePacked(
                type(ConstructorFromStorage).creationCode,
                abi.encode(this)
            ))
        )))));
        return predictedAddress;
    }

    function getCode(address addr) external view returns (bytes memory) {
        return addr.code;
    }
}

contract ConstructorFromStorage {
    event Msg(address origin, address sender, uint value, uint gas, bytes data, bytes4 sig);

    constructor(StorageCreate2 store) payable {  // if you sent ETH it's your own vault, we want to save bytes!
        emit Msg(tx.origin, msg.sender, msg.value, gasleft(), msg.data, msg.sig);
        bytes memory storedCode = store.storedCode();
        assembly {
            return(add(storedCode, 0x20), mload(storedCode))
        }
    }
}
