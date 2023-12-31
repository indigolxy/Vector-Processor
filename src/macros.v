`ifndef MACROS
`define MACROS

`define XLEN 32
`define VLEN 512
`define vlenb 64
`define VLMAX 64 // VLEN/SEWmin

`define RAM_DATA_WID 7:0
`define RAM_ADDR_WID 16:0
`define RAM_SIZE 2**16

`define INST_WID 31:0

`define REG_WID 5:0 // 最高位 scalar(0)/vector(1)
`define OPT_WID 6:0
`define FUNCT3_WID 2:0
`define FUNCT6_WID 5:0

`define IB_WID 3:0
`define IB_SIZE 16

// for sb
`define SB_SIZE_WID 3:0 // for pos
`define ALU_ENTRY_SIZE 8
`define LS_ENTRY_SIZE 7
`define SB_SIZE 15
`define INVALID_POS 4'b1111 // width = SB_SIZE_WID
`define LS_ST_POS 8 // = ALU_ENTRY_SIZE
`define LS_ED_POS 14 // = SB_SIZE-1, last entry in SB

// for register
`define REG_SIZE 64 // num of registers
`define REG_SIZE_V 32 // num of vector registers
`define REG_SIZE_S 32 // num of scalar registers


`define OPCODE_B 7'b1100011
`define OPCODE_L 7'b0000011 // load
`define OPCODE_S 7'b0100011 // store
`define OPCODE_I 7'b0010011
`define OPCODE_R 7'b0110011
`define OPCODE_VA 7'b1010111
`define OPCODE_VL 7'b0000111
`define OPCODE_VS 7'b0100111

`endif // MACROS
