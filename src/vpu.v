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
wire [`FUNCT3_WID] id_to_ib_funct3;
wire [`FUNCT6_WID] id_to_ib_funct6;
wire [`REG_WID]    id_to_ib_rs1;
wire [`REG_WID]    id_to_ib_rs2;
wire [`REG_WID]    id_to_ib_rd;
wire [`XLEN-1:0]   id_to_ib_imm;

// ib and sb
wire               ib_to_sb_valid;
wire [`OPT_WID]    ib_to_sb_opt;
wire [`FUNCT3_WID] ib_to_sb_funct3;
wire [`FUNCT6_WID] ib_to_sb_funct6;
wire [`REG_WID]    ib_to_sb_rs1;
wire [`REG_WID]    ib_to_sb_rs2;
wire [`REG_WID]    ib_to_sb_rd;
wire [`XLEN-1:0]   ib_to_sb_imm;
wire               sb_to_ib_vacant_ALU;
wire               sb_to_ib_vacant_LS;

// sb and reg
wire                sb_to_reg_valid;
wire                sb_to_reg_dest; // 0 for alu, 1 for ls
wire [`REG_WID]     sb_to_reg_rs1;
wire [`REG_WID]     sb_to_reg_rs2;
wire [`SB_SIZE_WID] sb_to_reg_pos;
wire [`OPT_WID]     sb_to_reg_opt;
wire [`FUNCT3_WID]  sb_to_reg_funct3;
wire [`FUNCT6_WID]  sb_to_reg_funct6;
wire [`REG_WID]     sb_to_reg_rd;
wire [`XLEN-1:0]    sb_to_reg_imm;

// reg and alu
wire                reg_to_alu_valid;
wire [`VLEN-1:0]    reg_to_alu_value1;
wire [`VLEN-1:0]    reg_to_alu_value2;
wire [`SB_SIZE_WID] reg_to_alu_pos;
wire [`OPT_WID]     reg_to_alu_opt;
wire [`FUNCT3_WID]  reg_to_alu_funct3;
wire [`FUNCT6_WID]  reg_to_alu_funct6;
wire [`REG_WID]     reg_to_alu_rd;
wire [`XLEN-1:0]    reg_to_alu_imm;

// reg and ls
wire                reg_to_ls_valid;
wire [`VLEN-1:0]    reg_to_ls_value1;
wire [`VLEN-1:0]    reg_to_ls_value2;
wire [`SB_SIZE_WID] reg_to_ls_pos;
wire [`OPT_WID]     reg_to_ls_opt;
wire [`FUNCT3_WID]  reg_to_ls_funct3;
wire [`FUNCT6_WID]  reg_to_ls_funct6;
wire [`REG_WID]     reg_to_ls_rd;
wire [`XLEN-1:0]    reg_to_ls_imm;

// alu and CSR
wire             alu_to_csr_we;
wire [`XLEN-1:0] alu_to_csr_vl_set;
wire [`XLEN-1:0] alu_to_csr_sew_set;
wire [`XLEN-1:0] csr_to_alu_vl;
wire [`XLEN-1:0] csr_to_alu_sew;

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
  .ib_funct3     	(id_to_ib_funct3),
  .ib_funct6     	(id_to_ib_funct6),
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
  .id_funct3     	(id_to_ib_funct3),
  .id_funct6     	(id_to_ib_funct6),
  .id_rs1       	(id_to_ib_rs1),
  .id_rs2       	(id_to_ib_rs2),
  .id_rd        	(id_to_ib_rd),
  .id_imm       	(id_to_ib_imm),

  .sb_vacant_ALU  (sb_to_ib_vacant_ALU),
  .sb_vacant_LS   (sb_to_ib_vacant_LS),
  .sb_valid     	(ib_to_sb_valid),
  .sb_opt       	(ib_to_sb_opt),
  .sb_funct3     	(ib_to_sb_funct3),
  .sb_funct6     	(ib_to_sb_funct6),
  .sb_rs1       	(ib_to_sb_rs1),
  .sb_rs2       	(ib_to_sb_rs2),
  .sb_rd        	(ib_to_sb_rd),
  .sb_imm       	(ib_to_sb_imm)
);

scoreboard u_scoreboard (
  .clk        (clk_in),
  .rst        (rst_in),

  .ib_vacant_ALU (sb_to_ib_vacant_ALU),
  .ib_vacant_LS  (sb_to_ib_vacant_LS),
  .ib_valid   (ib_to_sb_valid),
  .ib_opt     (ib_to_sb_opt),
  .ib_funct3   (ib_to_sb_funct3),
  .ib_funct6   (ib_to_sb_funct6),
  .ib_rs1     (ib_to_sb_rs1),
  .ib_rs2     (ib_to_sb_rs2),
  .ib_rd      (ib_to_sb_rd),
  .ib_imm     (ib_to_sb_imm),

  .reg_rs1    (sb_to_reg_rs1),
  .reg_rs2    (sb_to_reg_rs2),

  .exe_valid  (sb_to_reg_valid),
  .exe_dest   (sb_to_reg_dest),
  .exe_pos    (sb_to_reg_pos),
  .exe_opt    (sb_to_reg_opt),
  .exe_funct3  (sb_to_reg_funct3),
  .exe_funct6  (sb_to_reg_funct6),
  .exe_rd     (sb_to_reg_rd),
  .exe_imm    (sb_to_reg_imm),

  .wb_valid   (wb_valid),
  .wb_pos     (wb_pos),
  .wb_rd      (wb_rd)
);

register u_register (
  .clk        (clk_in),
  .rst        (rst_in),

  .sb_valid   (sb_to_reg_valid),
  .sb_dest    (sb_to_reg_dest),
  .sb_rs1     (sb_to_reg_rs1),
  .sb_rs2     (sb_to_reg_rs2),
  .exe_pos    (sb_to_reg_pos),
  .exe_opt     (sb_to_reg_opt),
  .exe_funct3  (sb_to_reg_funct3),
  .exe_funct6  (sb_to_reg_funct6),
  .exe_rd      (sb_to_reg_rd),
  .exe_imm     (sb_to_reg_imm),

  .alu_valid  (reg_to_alu_valid),
  .alu_value1 (reg_to_alu_value1),
  .alu_value2 (reg_to_alu_value2),
  .alu_pos    (reg_to_alu_pos),
  .alu_opt    (reg_to_alu_opt),
  .alu_funct3 (reg_to_alu_funct3),
  .alu_funct6 (reg_to_alu_funct6),
  .alu_rd     (reg_to_alu_rd),
  .alu_imm    (reg_to_alu_imm),

  .ls_valid   (reg_to_ls_valid),
  .ls_value1  (reg_to_ls_value1),
  .ls_value2  (reg_to_ls_value2),
  .ls_pos     (reg_to_ls_pos),
  .ls_opt     (reg_to_ls_opt),
  .ls_funct3  (reg_to_ls_funct3),
  .ls_funct6  (reg_to_ls_funct6),
  .ls_rd      (reg_to_ls_rd),
  .ls_imm     (reg_to_ls_imm),

  .wb_valid   (wb_valid),
  .wb_rd      (wb_rd),
  .wb_value   (wb_value)
);

alu u_alu (
  .clk        (clk_in),
  .rst        (rst_in),

  .exe_valid  (reg_to_alu_valid),
  .value1 (reg_to_alu_value1),
  .value2 (reg_to_alu_value2),
  .pos    (reg_to_alu_pos),
  .opt    (reg_to_alu_opt),
  .funct3 (reg_to_alu_funct3),
  .funct6 (reg_to_alu_funct6),
  .rd     (reg_to_alu_rd),
  .imm    (reg_to_alu_imm),

  .vl     (csr_to_alu_vl),
  .sew    (csr_to_alu_sew),

  .csr_we  (alu_to_csr_we),
  .vl_set (alu_to_csr_vl_set),
  .sew_set (alu_to_csr_sew_set),

  .wb_valid   (wb_valid),
  .wb_pos     (wb_pos),
  .wb_rd      (wb_rd),
  .wb_value   (wb_value)
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