// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./asm.sol";

library TinyCreate2 {
  // TODO document the blocks
  bytes constant loadSalt = abi.encodePacked(asm.PUSH0, asm.CALLDATALOAD); // hex'5f35'

  bytes constant copyCreationCode = abi.encodePacked(
    asm.PUSH1, uint8(32),
    asm.CALLDATASIZE, asm.SUB,
    asm.DUP1, asm.PUSH1, uint8(32), asm.PUSH0,
    asm.CALLDATACOPY
  );  //*/ hex'6020_3603_80_60205f_37';
  
  bytes constant create2call = abi.encodePacked(
    asm.PUSH0, asm.CALLVALUE, asm.CREATE2
  ); //*/ hex'5f34f5';

  bytes constant returnAddr = abi.encodePacked(
    asm.PUSH0, asm.MSTORE,
    asm.PUSH1, asm.ADDRLEN,
    asm.PUSH1, 32 - asm.ADDRLEN,
    asm.RETURN
  ); //*/ hex'5f52_6014_600c_f3';

  bytes constant proxyCode = abi.encodePacked(
    // hexcode        //    gas | stack       | comments
    loadSalt,         //      5 | salt        | 
    copyCreationCode, //     19 + 3*data_size_words + mem_expansion_cost
    create2call,      //  32004 + 6*data_size_words + mem_expansion_cost + code_deposit_cost
    returnAddr        //     11 + mem_expansion_cost
    //                //  32039 + 9*data_size_words + mem_expansion_costs + code_deposit_cost
  );
  uint8 constant proxyCodeLength = 21;  // unfortunately can't use proxyCode.length for a constant, so this needs to be adapted...
  //uint immutable proxyCodeLength = proxyCode.length;  // immutable works, but that's not ideal in terms of gas and memory

  bytes constant pushProxyCode = abi.encodePacked(
    uint8(asm.PUSH1) - 1 + proxyCodeLength, //hex'74' corresponds to PUSH21,
    proxyCode,
    asm.PUSH0, asm.MSTORE // hex'5f52'
  );

  bytes constant returnProxyCode = abi.encodePacked(
    asm.PUSH1, proxyCodeLength,
    asm.PUSH1, 32 - proxyCodeLength,
    asm.RETURN
  );

  bytes constant proxyCreateCode = abi.encodePacked(pushProxyCode, returnProxyCode);

  //bytes constant rawCode = hex'74_3d35_602036038060203d37_3d34f5_3d526014600c_f3_3d52_6015600bf3';
  bytes constant rawCode = hex'74_5f35_602036038060205f37_5f34f5_5f526014600c_f3_5f52_6015600bf3';
}

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
    this gets encoded as [uint256 salt, uint256(0x40), uint256 len(creationCode), enc(creationCode[0]), enc(creationCode[1], ...]
    which actually wastes 2x 32 bytes for the position and length encoding and makes the code unnecessarily complicated.
    In contrast [`abi.encodePacked()`](https://docs.soliditylang.org/en/develop/abi-spec.html#non-standard-packed-mode)
    should be more tight, [uint256 salt, bytes creationCode]

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
    0x03        | SUB               | lc:=cds-32 salt   | len(enc(creationCode) = CALLDATASIZE - 32 =: lc
    0x80        | DUP1              | lc lc salt        | we need the length later again
    0x6020      | PUSH1 0x20        | 0x20 lc lc salt   | can this be optimized using the previous 0x20? PUSH1, DUPx and SWAPx need 3 gas each though
    0x3d        | RETURNDATASIZE    | 0 0x20 lc lc salt |
    0x37        | CALLDATACOPY      | lc salt           | memory[0:...] = msg.data[0x20:...] = enc(creationCode)
    ------------+-------------------+-------------------+------------------------------------------------------------------
                | CREATE2(value, offset, length, salt)  |
    ------------+-------------------+-------------------+------------------------------------------------------------------
    0x3d        | RETURNDATASIZE    | 0 lc salt         |
    0x34        | CALLVALUE         | val 0 lc salt     |
    0xf5        | CREATE2           | addr              |
    ------------+-------------------+-------------------+------------------------------------------------------------------
                | return addr       |                   | mandatory?
    ------------+-------------------+-------------------+------------------------------------------------------------------
    0x3d        | RETURNDATASIZE    | 0? addr?          | let's see...
    0x52        | MSTORE            |                   |
    0x6014      | PUSH 0x14         | 20                | len(address)
    0x600c      | PUSH 0x0c         | 12 20             | offset = 32-20 = 12
    0xf3        | RETURN            |                   |

    so in summary 0x3d35602036038060203d373d34f5, 14 bytes
    plus 0x3d526014600cf3 = 7 bytes

    the creationCode for this proxy is therefore:
    OPCODE      | INSTRUCTION       | STACK             | COMMENT
    ------------+-------------------+-------------------+------------------------------------------------------------------
                | PUSH proxycode    |                   |
    ------------+-------------------+-------------------+------------------------------------------------------------------
    0x74 [...]  | PUSH21 ...        | PROXYCODE         |
    0x3d        | RETURNDATASIZE    | 0 PROXYCODE       | again less gas/bytes than PUSH1 0x00
    0x52        | MSTORE            |                   | writes stack to memory[0x00:0x20], PADDED to bytes32
    ------------+-------------------+-------------------+------------------------------------------------------------------
                | return proxycode  |                   |
    ------------+-------------------+-------------------+------------------------------------------------------------------
    0x6015      | PUSH1 15          | 21                | length of PROXYCODE
    0x600b      | PUSH1 0b          | 18 14             | 32-21 = 11 =0x0b as offset
    0xf3        | RETURN            |                   | returns PROXYCODE from memory[0x12:0x20]

    so in summary the createCode is
    0x743d35602036038060203d373d34f53d526014600cf33d526015600bf3
  */
