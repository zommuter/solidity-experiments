// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract StorageCreate2 {
    bytes public storedCode;

    function create2(bytes calldata _code, bytes32 salt) external payable {  // payable saves some bytes for checking msg.value. Don't blame me for loss.
        storedCode = _code;
        // do magic
        delete storedCode;  // small gas refund for not permanently storing the storedCode
    }
}

contract ConstructorFromStorage {
    address constant storageContractAddress = 0xDA0bab807633f07f013f94DD0E6A4F96F8742B53; // TBD
    StorageCreate2 constant storageContract = StorageCreate2(storageContractAddress);

    constructor() payable {  // if you sent ETH it's your own vault, we want to save bytes!
        bytes memory storedCode = storageContract.storedCode();
        assembly {
            return(add(storedCode, 0x20), mload(storedCode))
        }
    }
}
// bytecode
// 6080604081905263a93c7c4360e01b815260009073da0bab807633f07f013f94dd0e6a4f96f8742b539063a93c7c43906084908490600481865afa15801561004b573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f191682016040526100739190810190610093565b9050805160208201f35b634e487b7160e01b600052604160045260246000fd5b600060208083850312156100a657600080fd5b82516001600160401b03808211156100bd57600080fd5b818501915085601f8301126100d157600080fd5b8151818111156100e3576100e361007d565b604051601f8201601f19908116603f0116810190838211818310171561010b5761010b61007d565b81604052828152888684870101111561012357600080fd5b600093505b828410156101455784840186015181850187015292850192610128565b60008684830101528096505050505050509291505056fe

