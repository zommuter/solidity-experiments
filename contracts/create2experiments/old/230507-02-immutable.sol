// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract ImmutableTester {
    address immutable public addr;

    constructor() payable {
        addr = address(this);
    }
}

// resulting bytecode
// 60a06040523060805260805160a561002060003960006031015260a56000f3fe6080604052348015600f57600080fd5b506004361060285760003560e01c8063767800de14602d575b600080fd5b60537f000000000000000000000000000000000000000000000000000000000000000081565b6040516001600160a01b03909116815260200160405180910390f3fea26469706673582212202751394d5d97d54c15c967ddbb380ae91a087ea664bd466b32d8df0abdce6e8364736f6c63430008120033

contract resultingDecompile {  // using https://ethervm.io/decompile
    constructor() {
        memory[0x40:0x60] = 0xa0;
        memory[0x80:0xa0] = address(this);
        var temp0 = memory[0x80:0xa0];
        memory[0x00:0xa5] = code[0x20:0xc5];
        memory[0x31:0x51] = temp0;
        return mem[0x00:0xa5];
    }
}

/* resulting disassembly

label_0000:
	// Inputs[3]
	// {
	//     @0005  address(this)
	//     @000B  memory[0x80:0xa0]
	//     @001E  memory[0x00:0xa5]
	// }

	0000    60  PUSH1 0xa0
	0002    60  PUSH1 0x40
	0004    52  MSTORE
	//     @0004  memory[0x40:0x60] = 0xa0  // is that used anywhere?

	0005    30  ADDRESS
	0006    60  PUSH1 0x80
	0008    52  MSTORE
	//     @0008  memory[0x80:0xa0] = address(this)

	0009    60  PUSH1 0x80
	000B    51  MLOAD
    var temp0 = memory[0x80:0xa0] = address(this);  // so why not just ADDRESS?

	000C    60  PUSH1 0xa5
	000E    61  PUSH2 0x0020
	0011    60  PUSH1 0x00
	0013    39  CODECOPY
	//     @0013  memory[0x00:0xa5] = code[0x20:0x20+0xa5=0xc5]

	0014    60  PUSH1 0x00
	0016    60  PUSH1 0x31
	0018    01  ADD
	0019    52  MSTORE
	//     @0019  memory[0x31:0x51] = temp0 = memory[0x80:0xa0] = address(this)  // so really, why not ADDRESS, PUSH 0xff...ff (20 bytes), AND, PUSH1 0x31, MSTORE
    // anyway, this overwrites the placeholder 0x00..00 at 0x20+0x31=0x51

	001A    60  PUSH1 0xa5
	001C    60  PUSH1 0x00
	001E    F3  *RETURN
    return memory[0x00:0xa5];

	// Stack delta = +0
	// Outputs[5]
	// {
	//     @0004  memory[0x40:0x60] = 0xa0
	//     @0008  memory[0x80:0xa0] = address(this)
	//     @0013  memory[0x00:0xa5] = code[0x20:0xc5]
	//     @0019  memory[0x31:0x51] = memory[0x80:0xa0]
	//     @001E  return memory[0x00:0xa5];
	// }
	// Block terminates

	001F    FE    *ASSERT
    // filler?

	0020    60    PUSH1 0x80
	0022    60    PUSH1 0x40
	0024    52    MSTORE
	0025    34    CALLVALUE
	0026    80    DUP1
	0027    15    ISZERO
	0028    60    PUSH1 0x0f
	002A    57    *JUMPI
	002B    60    PUSH1 0x00
	002D    80    DUP1
	002E    FD    *REVERT
	002F    5B    JUMPDEST
	0030    50    POP
	0031    60    PUSH1 0x04
	0033    36    CALLDATASIZE
	0034    10    LT
	0035    60    PUSH1 0x28
	0037    57    *JUMPI
	0038    60    PUSH1 0x00
	003A    35    CALLDATALOAD
	003B    60    PUSH1 0xe0
	003D    1C    SHR
	003E    80    DUP1
	003F    63    PUSH4 0x767800de
	0044    14    EQ
	0045    60    PUSH1 0x2d
	0047    57    *JUMPI
	0048    5B    JUMPDEST
	0049    60    PUSH1 0x00
	004B    80    DUP1
	004C    FD    *REVERT
	004D    5B    JUMPDEST
	004E    60    PUSH1 0x53

	0050    7F    PUSH32 0x0000000000000000000000000000000000000000000000000000000000000000
    // the immutable address modified by the constructor

	0071    81    DUP2
	0072    56    *JUMP
	0073    5B    JUMPDEST
	0074    60    PUSH1 0x40
	0076    51    MLOAD
	0077    60    PUSH1 0x01
	0079    60    PUSH1 0x01
	007B    60    PUSH1 0xa0
	007D    1B    SHL
	007E    03    SUB
	007F    90    SWAP1
	0080    91    SWAP2
	0081    16    AND
	0082    81    DUP2
	0083    52    MSTORE
	0084    60    PUSH1 0x20
	0086    01    ADD
	0087    60    PUSH1 0x40
	0089    51    MLOAD
	008A    80    DUP1
	008B    91    SWAP2
	008C    03    SUB
	008D    90    SWAP1
	008E    F3    *RETURN
	008F    FE    *ASSERT
	0090    A2    LOG2
	0091    64    PUSH5 0x6970667358
	0097    22    22
	0098    12    SLT
	0099    20    SHA3
	009A    27    27
	009B    51    MLOAD
	009C    39    CODECOPY
	009D    4D    4D
	009E    5D    5D
	009F    97    SWAP8
	00A0    D5    D5
	00A1    4C    4C
	00A2    15    ISZERO
	00A3    C9    C9
	00A4    67    PUSH8 0xddbb380ae91a087e
	00AD    A6    A6
	00AE    64    PUSH5 0xbd466b32d8
	00B4    DF    DF
	00B5    0A    EXP
	00B6    BD    BD
	00B7    CE    CE
	00B8    6E    PUSH15 0x8364736f6c63430008120033

*/