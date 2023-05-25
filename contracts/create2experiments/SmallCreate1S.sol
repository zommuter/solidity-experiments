// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

// https://spdx.org/licenses/BUSL-1.1.html

import "@0xsequence/create3/contracts/Create3.sol";
//import "https://github.com/0xsequence/create3/blob/master/contracts/Create3.sol";

/**
  @title CREATE1S - CREATE with salt instead of nonce / CREATE2 with sender instead of code dependency
  @notice The salt is re-hashed together with the sender address `msg.sender` (using `privateDeploy`), which serves
          the purpose of avoiding front-running a contract deployment to a given address. The contract accepts ETH
          payments as donations ;)
          Based on Agustin Aguilar's CREATE3 implementation https://github.com/0xsequence/create3
  @author Zommuter <zommuter+eth@gmail.com> / https://twitter.com/zommuter_eth
*/
contract Create1sFactory {
    // hard-coded to avoid front-runners exploiting owner = msg.sender constructor, since this contract is to be deterministically deployed via
    // https://github.com/Arachnid/deterministic-deployment-proxy / https://blockscan.com/address/0x4e59b44847b379578588920ca78fbf26c0b4956c
    address payable constant zommuter = payable(0x4d25F3E88C10cDC001447beaEcA6e9Ee0009c060);

    event CREATE1S(address indexed contractAddress, address deployer, bytes32 indexed salt, bytes indexed _creationCode);

    /**
    @notice Creates a new contract with given `_creationCode` and `_salt`, using the sender's address in the salt to avoid front-running
            Usage is free, but a payment can be included as donation.
    @param _salt Salt of the contract creation, resulting address will be derived from this value
           only -- note the salt is salted with `msg.sender` in order to allow for front-running resistant deployment
    @param _creationCode Creation code (constructor) of the contract to be deployed, this value doesn't affect the resulting address
    @return addr of the deployed contract, reverts on error
    */
    function create1s(bytes32 _salt, bytes calldata _creationCode) external payable returns (address) {
        zommuter.transfer(address(this).balance);
        _salt = keccak256(bytes.concat(_salt, bytes20(msg.sender)));
        address addr = Create3.create3(_salt, _creationCode);
        emit CREATE1S(addr, msg.sender, _salt, _creationCode);
        return addr;
    }

    /**
    @notice Generates the address from `_salt`, using the sender's address in the salt to avoid front-running
    @param _salt Salt of the contract creation, resulting address will be derived from this value
           only -- note the salt is salted with `msg.sender` in order to allow for front-running resistant deployment
    @return addr of the deployed contract, reverts on error
    */
    function privateAddressOf(bytes32 _salt) external view returns (address) {
        return addressOf(_salt, msg.sender);
    }

    /**
    @notice Generates the address from `_salt`, using the sender's address in the salt to avoid front-running
    @param _salt Salt of the contract creation, resulting address will be derived from this value
           only -- note the salt is salted with `_sender` in order to allow for front-running resistant deployment
    @return addr of the deployed contract, reverts on error
    */
    function addressOf(bytes32 _salt, address _sender) public view returns (address) {
        _salt = keccak256(bytes.concat(_salt, bytes20(_sender)));
        return Create3.addressOf(_salt);
    }
}