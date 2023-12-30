`include "./macros.v"
// `include "./src/macros.v"

module register
(
  input wire clk,
  input wire rst,

  // with scoreboard
  input wire sb_valid,
  input wire sb_dest, // 0 for alu, 1 for ls
  input wire [`REG_WID] sb_rs1,
  input wire [`REG_WID] sb_rs2,

  input wire [`SB_SIZE_WID] exe_pos,
  input wire [`OPT_WID] exe_opt,
  input wire [`FUNCT3_WID] exe_funct3,
  input wire [`FUNCT6_WID] exe_funct6,
  input wire [`REG_WID] exe_rd,
  input wire [`XLEN-1:0] exe_imm,

  // with wb
  input wire wb_valid,
  input wire [`REG_WID] wb_rd,
  input wire [`VLEN-1:0] wb_value,

  // with alu
  output reg alu_valid,
  output reg [`VLEN-1:0] alu_value1,
  output reg [`VLEN-1:0] alu_value2,
  output reg [`SB_SIZE_WID] alu_pos,
  output reg [`OPT_WID] alu_opt,
  output reg [`FUNCT3_WID] alu_funct3,
  output reg [`FUNCT6_WID] alu_funct6,
  output reg [`REG_WID] alu_rd,
  output reg [`XLEN-1:0] alu_imm,

  // with ls
  output reg ls_valid,
  output reg [`VLEN-1:0] ls_value1,
  output reg [`VLEN-1:0] ls_value2,
  output reg [`SB_SIZE_WID] ls_pos,
  output reg [`OPT_WID] ls_opt,
  output reg [`FUNCT3_WID] ls_funct3,
  output reg [`FUNCT6_WID] ls_funct6,
  output reg [`REG_WID] ls_rd,
  output reg [`XLEN-1:0] ls_imm
);

reg [`XLEN-1:0] scalar_reg [0:`REG_SIZE_S-1];
reg [`VLEN-1:0] vector_reg [0:`REG_SIZE_V-1];

reg [`VLEN-1:0] data1, data2;

always @* begin
  if (sb_rs1[5] == 0) begin
    data1 = scalar_reg[sb_rs1[4:0]];
  end else begin
    data1 = vector_reg[sb_rs1[4:0]];
  end
  if (sb_rs2[5] == 0) begin
    data2 = scalar_reg[sb_rs2[4:0]];
  end else begin
    data2 = vector_reg[sb_rs2[4:0]];
  end
end

integer i,j;
  always @(posedge clk) begin
    if (rst) begin
      alu_valid <= 0;
      alu_value1 <= 0;
      alu_value2 <= 0;
      alu_pos <= 0;
      alu_opt <= 0;
      alu_funct3 <= 0;
      alu_funct6 <= 0;
      alu_rd <= 0;
      alu_imm <= 0;

      ls_valid <= 0;
      ls_value1 <= 0;
      ls_value2 <= 0;
      ls_pos <= 0;
      ls_opt <= 0;
      ls_funct3 <= 0;
      ls_funct6 <= 0;
      ls_rd <= 0;
      ls_imm <= 0;

      data1 <= 0;
      data2 <= 0;

      for (i = 0; i < `REG_SIZE_S; i = i + 1) 
        scalar_reg[i] <= 0;
      for (j = 0; j < `REG_SIZE_V; j = j + 1) 
        vector_reg[j] <= 0;
    end else begin
      if (sb_valid) begin
        if (sb_dest) begin
          ls_valid <= 1;
          ls_value1 <= data1;
          ls_value2 <= data2;
          ls_pos <= exe_pos;
          ls_opt <= exe_opt;
          ls_funct3 <= exe_funct3;
          ls_funct6 <= exe_funct6;
          ls_rd <= exe_rd;
          ls_imm <= exe_imm;
        end else begin
          alu_valid <= 1;
          alu_value1 <= data1;
          alu_value2 <= data2;
          alu_pos <= exe_pos;
          alu_opt <= exe_opt;
          alu_funct3 <= exe_funct3;
          alu_funct6 <= exe_funct6;
          alu_rd <= exe_rd;
          alu_imm <= exe_imm;
        end
      end
      if (wb_valid) begin
        if (wb_rd[5] == 0) begin
          scalar_reg[wb_rd[4:0]] <= wb_value[`XLEN-1:0];
        end else begin
          vector_reg[wb_rd[4:0]] <= wb_value;
        end
      end
    end
  end

endmodule