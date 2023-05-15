// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract MinimalCreate2Factory {
  /**
    @notice The bytecode for a contract that proxies the creation of another contract
    @dev ...

    this proxy gets called with (bytes creationCode) as single argument, which as per
    https://docs.soliditylang.org/en/latest/abi-spec.html#formal-specification-of-the-encoding
    gets encoded as [uint256 len(creationCode), enc(creationCode[0]), enc(creationCode[1], ...]
  0x67363d3d37363d34f03d5260086018f3:
      0x00  0x67  0x67XXXXXXXXXXXXXXXX  PUSH8 bytecode  0x363d3d37363d34f0
      0x01  0x3d  0x3d                  RETURNDATASIZE  0 0x363d3d37363d34f0
      0x02  0x52  0x52                  MSTORE
      0x03  0x60  0x6008                PUSH1 08        8
      0x04  0x60  0x6018                PUSH1 18        24 8   // 24 = 32-8 since MSTORE pads the stack value to 32 bytes...
      0x05  0xf3  0xf3                  RETURN
  0x363d3d37363d34f0:
      0x00  0x36  0x36                  CALLDATASIZE    cds
      0x01  0x3d  0x3d                  RETURNDATASIZE  0 cds
      0x02  0x3d  0x3d                  RETURNDATASIZE  0 0 cds
      0x03  0x37  0x37                  CALLDATACOPY
      0x04  0x36  0x36                  CALLDATASIZE    cds
      0x05  0x3d  0x3d                  RETURNDATASIZE  0 cds
      0x06  0x34  0x34                  CALLVALUE       val 0 cds
      0x07  0xf0  0xf0                  CREATE          addr


    now we want a CREATE2 proxy, so it gets called with (bytes creationCode, bytes32 salt) or
    (bytes32 salt, bytes creationCode), whichever is more convenient. This CALLDATASIZE is now
    32 bytes more. Since `salt` needs to be pushed to the stack we can directly use CALLDATALOAD
    with adequate parameter. Zero is an easier offset than using the length of creationCode first,
    so let's try (bytes32 salt, bytes creationCode):

    OPCODE      | INSTRUCTION       | STACK             | COMMENT
    ------------+-------------------+-------------------+------------------------------------------------------------------
                | LOAD salt         |                   |
    ------------+-------------------+-------------------+------------------------------------------------------------------
    0x3d        | RETURNDATASIZE    | 0                 | requires less gas and bytes than e.g. PUSH 0 or DUPx
    0x35        | CALLDATALOAD      | salt              |
    ------------+-------------------+-------------------+------------------------------------------------------------------
                | COPY creationCode | salt              |
    ------------+-------------------+-------------------+------------------------------------------------------------------
    0x6020      | PUSH1 0x20        | 0x20 salt         |
    0x36        | CALLDATASIZE      | cds 0x20 salt     |
    0x03        | SUB               | cds-32 salt       | len(enc(creationCode) = CALLDATASIZE - 32 =: lc
    0x80        | DUP1              | lc lc salt        | we need the length later again
    0x6020      | PUSH1 0x20        | 0x20 lc lc salt   | can this be optimized using the previous 0x20? PUSH1, DUPx and SWAPx need 3 gas each though
    0x3d        | RETURNDATASIZE    | 0 0x20 lc lc salt |
    0x37        | CALLDATACOPY      | lc salt           | memory[0:...] = msg.data[0x20:...] = enc(creationCode)
    ------------+-------------------+-------------------+------------------------------------------------------------------
                | CREATE2(value, offset, length, salt)  |
    ------------+-------------------+-------------------+------------------------------------------------------------------
    0x3d        | RETURNDATASIZE    | 0 lc salt         |
    0x34        | CALLVALUE         | val 0 lc salt     |
    0xf5        | CREATE2           | addr

    so in summary 0x3d35602036038060203d373d34f5, 14 bytes

    the creationCode for this proxy is therefore:
    OPCODE      | INSTRUCTION       | STACK             | COMMENT
    ------------+-------------------+-------------------+------------------------------------------------------------------
                | PUSH proxycode    |                   |
    0x6d [...]  | PUSH14 ...        | PROXYCODE         |
    0x3d        | RETURNDATASIZE    | 0 PROXYCODE       | again less gas/bytes than PUSH1 0x00
    0x52        | MSTORE            |                   | writes stack to memory[0x00:0x20], PADDED to bytes32
    0x600e      | PUSH1 0e          | 14                | length of PROXYCODE
    0x6012      | PUSH1 12          | 18 14             | 32-14=18=0x12 as offset
    0xf3        | RETURN            |                   | returns PROXYCODE from memory[0x12:0x20]

    so in summary the createCode is
    0x6d3d35602036038060203d373d34f53d52600e6012f3
  */    
}