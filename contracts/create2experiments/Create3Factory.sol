// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@0xsequence/create3/contracts/Create3.sol";

/**
  @title A contract factory based on Agustin Aguilar's CREATE3 implementation https://github.com/0xsequence/create3
  @notice The salt is re-hashed together with either the sender address `msg.sender` (using `privateDeploy`).
          This serves the purpose of avoiding front-running a contract deployment to a given address.
  @author Zommuter <zommuter+eth@gmail.com>
*/
contract Create3Factory {
    /**
    @notice Creates a new contract with given `_creationCode` and `_salt`, using the sender's address in the salt to avoid front-running
    @param _salt Salt of the contract creation, resulting address will be derived from this value
           only -- note the salt is salted with `msg.sender` in order to allow for front-running resistant deployment
    @param _creationCode Creation code (constructor) of the contract to be deployed, this value doesn't affect the resulting address
    @return addr of the deployed contract, reverts on error
    */
    function privateDeploy(bytes32 _salt, bytes calldata _creationCode) external payable returns (address) {
        _salt = keccak256(bytes.concat(_salt, bytes20(msg.sender)));
        return Create3.create3(_salt, _creationCode);
    }

    /**
    @notice Generates the address from `_salt`, using the sender's address in the salt to avoid front-running
    @param _salt Salt of the contract creation, resulting address will be derived from this value
           only -- note the salt is salted with `msg.sender` in order to allow for front-running resistant deployment
    @return addr of the deployed contract, reverts on error
    */
    function privateAddressOf(bytes32 _salt) external view returns (address) {
        return this.addressOf(_salt, msg.sender);
    }

    /**
    @notice Generates the address from `_salt`, using the sender's address in the salt to avoid front-running
    @param _salt Salt of the contract creation, resulting address will be derived from this value
           only -- note the salt is salted with `_sender` in order to allow for front-running resistant deployment
    @return addr of the deployed contract, reverts on error
    */
    function addressOf(bytes32 _salt, address _sender) external view returns (address) {
        _salt = keccak256(bytes.concat(_salt, bytes20(_sender)));
        return Create3.addressOf(_salt);
    }
}

/*
contract DeployCreate3Factory {
    event Deployed(address addr);
    constructor(bytes32 _salt) payable {
        address addr;
        bytes memory storedCode = type(Create3Factory).creationCode;
        assembly {
            addr := create2(callvalue(), add(storedCode, 0x20), mload(storedCode), _salt)
        }
        require(addr.code.length != 0);
        emit Deployed(addr);
        selfdestruct(payable(msg.sender));
    }

    // adapted from https://docs.soliditylang.org/en/develop/control-structures.html#salted-contract-creations-create2
    function predictAdress(bytes32 salt) external pure returns (address) {
        address predictedAddress = address(uint160(uint(keccak256(abi.encodePacked(
            bytes1(0xff),
            address(this),
            salt,
            keccak256(abi.encodePacked(
                type(Create3Factory).creationCode,
                abi.encode(this)
            ))
        )))));
        return predictedAddress;
    }


    function addressOf(bytes32 _salt) external pure returns (address) {

    }
}
*/