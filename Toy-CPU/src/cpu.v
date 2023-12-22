`include "./src/idecode.v"
`include "./src/ifetch.v"
`include "./src/mem_ctrl.v"
`include "./src/ibuffer.v"
`include "./src/scoreboard.v"
`include "./src/register.v"

// RISCV32I CPU top module
// port modification allowed for debugging purposes

module cpu
#(
  parameter MEM_ADDR_WIDTH = 32, 
  parameter MEM_DATA_WIDTH = 32, 
  parameter INST_WIDTH = 32
)
(
  input wire clk_in,
  input wire rst_in,
	// input  wire					    rdy_in,			// ready signal, pause cpu when low

  output  wire [MEM_ADDR_WIDTH-1:0] mem_addr_a, // only 16 bits used
  input wire [MEM_DATA_WIDTH-1:0] mem_data_a,

  output  wire                  mem_wr_b,
  output  wire [MEM_DATA_WIDTH-1:0] mem_src_b,
  output  wire [MEM_ADDR_WIDTH-1:0] mem_addr_b,
  input wire [MEM_DATA_WIDTH-1:0] mem_data_b
	
	// output wire [31:0]			dbgreg_dout		// cpu register output (debugging demo)
);

localparam OPT_SIZE = 7;
localparam FUNCT_SIZE = 3;
localparam REG_WIDTH = 5;
localparam SB_SIZE_WIDTH = 4;

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)

// if and mc
wire [MEM_ADDR_WIDTH-1:0] if_to_mc_addr;
wire                      if_to_mc_valid;
wire [MEM_DATA_WIDTH-1:0] mc_to_if_data;
wire                      mc_to_if_done;

// if and id
wire                      id_to_if_vacant;
wire                      if_to_id_valid;
wire [INST_WIDTH-1:0]     if_to_id_inst;

// id and ib
wire                      ib_to_id_vacant;
wire                      id_to_ib_valid;
wire [OPT_SIZE-1:0]       id_to_ib_opt;
wire [FUNCT_SIZE-1:0]     id_to_ib_funct;
wire [REG_WIDTH-1:0]       id_to_ib_rs1;
wire [REG_WIDTH-1:0]       id_to_ib_rs2;
wire [REG_WIDTH-1:0]       id_to_ib_rd;
wire [MEM_DATA_WIDTH-1:0] id_to_ib_imm;

// ib and sb
wire                      ib_to_sb_valid;
wire [OPT_SIZE-1:0]       ib_to_sb_opt;
wire [FUNCT_SIZE-1:0]     ib_to_sb_funct;
wire [REG_WIDTH-1:0]      ib_to_sb_rs1;
wire [REG_WIDTH-1:0]      ib_to_sb_rs2;
wire [REG_WIDTH-1:0]      ib_to_sb_rd;
wire [MEM_DATA_WIDTH-1:0] ib_to_sb_imm;
wire                      sb_to_ib_vacant_ALU;
wire                      sb_to_ib_vacant_LS;

// sb and reg
wire [REG_WIDTH-1:0]      sb_to_reg_rs1;
wire [REG_WIDTH-1:0]      sb_to_reg_rs2;

// exe broadcast
wire                      exe_valid;
wire                      exe_dest; // 0 for alu, 1 for ls
wire [SB_SIZE_WIDTH-1:0]  exe_pos;
wire [OPT_SIZE-1:0]       exe_opt;
wire [FUNCT_SIZE-1:0]     exe_funct;
wire [REG_WIDTH-1:0]      exe_rd;
wire [MEM_DATA_WIDTH-1:0] exe_imm;
wire [MEM_DATA_WIDTH-1:0] exe_rs1;
wire [MEM_DATA_WIDTH-1:0] exe_rs2;

// wb broadcast
wire                      wb_valid;
wire [SB_SIZE_WIDTH-1:0]  wb_pos;
wire [REG_WIDTH-1:0]      wb_rd;
wire [MEM_DATA_WIDTH-1:0] wb_value;
wire [MEM_ADDR_WIDTH-1:0] wb_offset;

// mc and ls
wire                      ls_to_mc_we;
wire [MEM_DATA_WIDTH-1:0] ls_to_mc_src;
wire [MEM_ADDR_WIDTH-1:0] ls_to_mc_addr;
wire                      mc_to_ls_done;
wire [MEM_DATA_WIDTH-1:0] mc_to_ls_data;

i_fetch #(.ADDR_WIDTH(32),
         .INST_WIDTH(32)) u_i_fetch(
  .clk          	(clk_in),
  .rst          	(rst_in),
  .offset_valid 	(wb_valid),
  .offset       	(wb_offset),
  .id_vacant  	(id_to_if_vacant),
  .id_valid   	(if_to_id_valid),
  .id_inst      (if_to_id_inst),
  .mc_done     	(mc_to_if_done),
  .mc_inst     	(mc_to_if_data),
  .mc_valid    	(if_to_mc_valid),
  .mc_addr     	(if_to_mc_addr)
);

i_decode #(.INST_WIDTH(32),
           .DATA_WIDTH(32)) u_i_decode(
  .clk          	(clk_in),
  .rst          	(rst_in),
  .if_valid   	  (if_to_id_valid),
  .inst         	(if_to_id_inst),
  .if_vacant    	(id_to_if_vacant),

  .ib_vacant    	(ib_to_id_vacant),
  .ib_valid     	(id_to_ib_valid),
  .ib_opt       	(id_to_ib_opt),
  .ib_funct     	(id_to_ib_funct),
  .ib_rs1       	(id_to_ib_rs1),
  .ib_rs2       	(id_to_ib_rs2),
  .ib_rd        	(id_to_ib_rd),
  .ib_imm       	(id_to_ib_imm)
);

i_buffer #(.IB_SIZE_WIDTH(3),
           .DATA_WIDTH(32)) u_i_buffer(
  .clk          	(clk_in),
  .rst          	(rst_in),

  .id_vacant   	  (ib_to_id_vacant),
  .id_valid     	(id_to_ib_valid),
  .id_opt       	(id_to_ib_opt),
  .id_funct     	(id_to_ib_funct),
  .id_rs1       	(id_to_ib_rs1),
  .id_rs2       	(id_to_ib_rs2),
  .id_rd        	(id_to_ib_rd),
  .id_imm       	(id_to_ib_imm),

  .sb_vacant_ALU  (sb_to_ib_vacant_ALU),
  .sb_vacant_LS   (sb_to_ib_vacant_LS),
  .sb_valid     	(ib_to_sb_valid),
  .sb_opt       	(ib_to_sb_opt),
  .sb_funct     	(ib_to_sb_funct),
  .sb_rs1       	(ib_to_sb_rs1),
  .sb_rs2       	(ib_to_sb_rs2),
  .sb_rd        	(ib_to_sb_rd),
  .sb_imm       	(ib_to_sb_imm)
);

scoreboard #(.ALU_ENTRY_SIZE(8),
             .LS_ENTRY_SIZE(7),
             .SB_SIZE_WIDTH(4),
             .DATA_WIDTH(32)) u_scoreboard (
  .clk        (clk_in),
  .rst        (rst_in),

  .ib_vacant_ALU (sb_to_ib_vacant_ALU),
  .ib_vacant_LS  (sb_to_ib_vacant_LS),
  .ib_valid   (ib_to_sb_valid),
  .ib_opt     (ib_to_sb_opt),
  .ib_funct   (ib_to_sb_funct),
  .ib_rs1     (ib_to_sb_rs1),
  .ib_rs2     (ib_to_sb_rs2),
  .ib_rd      (ib_to_sb_rd),
  .ib_imm     (ib_to_sb_imm),

  .reg_rs1    (sb_to_reg_rs1),
  .reg_rs2    (sb_to_reg_rs2),

  .exe_valid  (exe_valid),
  .exe_dest   (exe_dest),
  .exe_pos    (exe_pos),
  .exe_opt    (exe_opt),
  .exe_funct  (exe_funct),
  .exe_rd     (exe_rd),
  .exe_imm    (exe_imm),

  .wb_valid   (wb_valid),
  .wb_pos     (wb_pos),
  .wb_rd      (wb_rd)
);

register #(.REG_WIDTH(5),
           .DATA_WIDTH(32)) u_register (
  .clk        (clk_in),
  .rst        (rst_in),

  .sb_valid   (exe_valid),
  .sb_dest    (exe_dest),
  .sb_rs1     (sb_to_reg_rs1),
  .sb_rs2     (sb_to_reg_rs2),

  .wb_valid   (wb_valid),
  .wb_rd      (wb_rd),
  .wb_value   (wb_value),

  .exe_rs1    (exe_rs1),
  .exe_rs2    (exe_rs2)
);

mem_ctrl #(.ADDR_WIDTH(32),
           .DATA_WIDTH(32)) u_mem_ctrl(
  .clk      	(clk_in),
  .rst      	(rst_in),
  .if_valid 	(if_to_mc_valid),
  .if_addr  	(if_to_mc_addr),
  .if_done  	(mc_to_if_done),
  .if_data  	(mc_to_if_data),
  .ls_we    	(ls_to_mc_we),
  .ls_src   	(ls_to_mc_src),
  .ls_addr  	(ls_to_mc_addr),
  .ls_done  	(mc_to_ls_done),
  .ls_data  	(mc_to_ls_data),
  .addr_a   	(mem_addr_a),
  .data_a   	(mem_data_a),
  .addr_b   	(mem_addr_b),
  .wr_b     	(mem_wr_b),
  .src_b    	(mem_src_b),
  .data_b   	(mem_data_b)
);


endmodule