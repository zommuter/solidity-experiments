// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library asm {
  bytes1 constant SUB = hex'03';
  bytes1 constant CALLVALUE = hex'34';
  bytes1 constant CALLDATALOAD = hex'35';
  bytes1 constant CALLDATASIZE = hex'36';
  bytes1 constant CALLDATACOPY = hex'37';
  bytes1 constant RETURNDATASIZE = hex'3d';
  bytes1 constant MSTORE = hex'52';
  bytes1 constant PUSH0 = hex'5f'; // 0x5f from EIP-3855, not sure if all relevant chains support that yet
  bytes1 constant PUSH1 = hex'60';
  bytes1 constant DUP1 = hex'80';
  bytes1 constant RETURN = hex'f3';
  bytes1 constant CREATE2 = hex'f5';

  uint8 constant ADDRLEN = 20;
}