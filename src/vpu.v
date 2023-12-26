`include "./macros.v"
// `include "./src/macros.v"
// `include "./src/mem_ctrl.v"
// `include "./src/ifetch.v"
// `include "./src/idecode.v"
// `include "./src/ibuffer.v"

module vpu
(
  input wire clk_in,
  input wire rst_in,

  input wire [`RAM_DATA_WID] mem_data_a,
  output wire [`XLEN-1:0] mem_addr_a, // only 16 bits used

  input wire [`RAM_DATA_WID] mem_data_b,
  output wire mem_we_b,
  output wire [`RAM_DATA_WID] mem_src_b,
  output wire [`XLEN-1:0] mem_addr_b
);

// if and mc
wire             if_to_mc_valid;
wire [`XLEN-1:0] if_to_mc_addr;
wire [`XLEN-1:0] if_to_mc_len;
wire             mc_to_if_done;
wire [`XLEN-1:0] mc_to_if_data;

assign if_to_mc_len = `XLEN'b100;

// if and id
wire             id_to_if_vacant;
wire             if_to_id_valid;
wire [`INST_WID] if_to_id_inst;

// id and ib
wire               ib_to_id_vacant;
wire               id_to_ib_valid;
wire [`OPT_WID]    id_to_ib_opt;
wire [`FUNCT3_WID] id_to_ib_funct;
wire [`REG_WID]    id_to_ib_rs1;
wire [`REG_WID]    id_to_ib_rs2;
wire [`REG_WID]    id_to_ib_rd;
wire [`XLEN-1:0]   id_to_ib_imm;

// ib and sb
wire               ib_to_sb_valid;
wire [`OPT_WID]    ib_to_sb_opt;
wire [`FUNCT3_WID] ib_to_sb_funct;
wire [`REG_WID]    ib_to_sb_rs1;
wire [`REG_WID]    ib_to_sb_rs2;
wire [`REG_WID]    ib_to_sb_rd;
wire [`XLEN-1:0]   ib_to_sb_imm;
wire               sb_to_ib_vacant_ALU;
wire               sb_to_ib_vacant_LS;

assign sb_to_ib_vacant_ALU = 1'b0;
assign sb_to_ib_vacant_LS = 1'b0;

// mc and ls
wire             ls_to_mc_valid;
wire             ls_to_mc_we;
wire [`VLEN-1:0] ls_to_mc_src;
wire [`XLEN-1:0] ls_to_mc_addr;
wire [`XLEN-1:0] ls_to_mc_len;
wire             mc_to_ls_done;
wire [`VLEN-1:0] mc_to_ls_data;

// wb broadcast
wire                wb_valid;
wire [`SB_SIZE_WID] wb_pos;
wire [`REG_WID]     wb_rd;
wire [`VLEN-1:0]    wb_value;

i_fetch u_i_fetch(
  .clk          	(clk_in),
  .rst          	(rst_in),

  .wb_valid 	  (wb_valid),
  .wb_pos       (wb_pos),
  .wb_rd        (wb_rd),
  .wb_value     (wb_value),

  .id_vacant  	(id_to_if_vacant),
  .id_valid   	(if_to_id_valid),
  .id_inst      (if_to_id_inst),

  .mc_done     	(mc_to_if_done),
  .mc_inst     	(mc_to_if_data),
  .mc_valid    	(if_to_mc_valid),
  .mc_addr     	(if_to_mc_addr)
);


i_decode u_i_decode(
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

i_buffer u_i_buffer(
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

mem_ctrl u_mem_ctrl(
  .clk      	(clk_in),
  .rst      	(rst_in),

  .if_valid 	(if_to_mc_valid),
  .if_addr  	(if_to_mc_addr),
  .if_len     (if_to_mc_len),
  .if_done  	(mc_to_if_done),
  .if_data  	(mc_to_if_data),

  .ls_valid   (ls_to_mc_valid),
  .ls_we    	(ls_to_mc_we),
  .ls_src   	(ls_to_mc_src),
  .ls_addr  	(ls_to_mc_addr),
  .ls_len     (ls_to_mc_len),
  .ls_done  	(mc_to_ls_done),
  .ls_data  	(mc_to_ls_data),

  .addr_a   	(mem_addr_a),
  .data_a   	(mem_data_a),
  .addr_b   	(mem_addr_b),
  .we_b     	(mem_wr_b),
  .src_b    	(mem_src_b),
  .data_b   	(mem_data_b)
);


endmodule