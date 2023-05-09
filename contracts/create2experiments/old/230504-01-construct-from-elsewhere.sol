// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Storage {
    mapping(address => bytes) public personalStorage;
    mapping(bytes20 => bytes) public indexedStorage;

    function setPersonalStorage(bytes calldata data) public {
        personalStorage[msg.sender] = data;
    }

    function getPersonalStorage() public view returns (bytes memory) {
        return personalStorage[msg.sender];
    }

    function setIndexedStorage(bytes20 index, bytes calldata data) public {
        indexedStorage[index] = data;
    }
}

contract PersonalCreator {
    address constant storageContractAddress = 0xDA0bab807633f07f013f94DD0E6A4F96F8742B53; // TBD
    Storage constant storageContract = Storage(storageContractAddress);

    constructor() {
        bytes memory initCode = storageContract.personalStorage(msg.sender);
        assembly {
            return(add(initCode, 0x20), mload(initCode))
        }
    }
}