// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./TinyCreate2.sol";

contract MinimalCreate2Factory {
  event Created(address);
  event RawInput(bytes);
  event Returns(bytes);
  address public immutable minimalCreate2Factory;

  constructor () {
    assert(keccak256(TinyCreate2.proxyCreateCode) == keccak256(TinyCreate2.rawCode));
    bytes memory createCodeMem = TinyCreate2.proxyCreateCode;
    emit Created(address(this));
    address addr;
    assembly { addr := create(callvalue(), add(createCodeMem, 0x20), mload(createCodeMem)) }
    minimalCreate2Factory = addr;
    emit Created(minimalCreate2Factory);
  }

  function create2(bytes32 salt, bytes calldata createCode) public payable returns (address) {
    return this.create2raw{value: msg.value}(abi.encodePacked(salt, createCode));
  }

  function create2(bytes calldata createCode) external payable returns (address) {
    return this.create2{value: msg.value}(bytes32(0), createCode);
  }

  function create2raw(bytes calldata raw) public payable returns (address) {
    //emit RawInput(raw);
    (bool success, bytes memory retval) = minimalCreate2Factory.call{value: msg.value}(raw);
    require(success);
    //emit Returns(retval);
    address addr;
    assembly { addr := mload(add(retval, 20)) }
    require(addr != address(bytes20(0)));
    emit Created(addr);
    return addr;
  }

  function readCode(address addr) public view returns (bytes memory) {
    return addr.code;
  }
}