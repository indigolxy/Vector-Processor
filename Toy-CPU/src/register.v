module register 
#(
  parameter REG_WIDTH = 5,
  parameter DATA_WIDTH = 32
)
(
  input wire clk,
  input wire rst,

  // with scoreboard
  input wire sb_valid,
  input wire sb_dest, // 0 for alu, 1 for ls
  input wire [REG_WIDTH-1:0] sb_rs1,
  input wire [REG_WIDTH-1:0] sb_rs2,

  // with wb
  input wire wb_valid,
  input wire [REG_WIDTH-1:0] wb_rd,
  input wire [DATA_WIDTH-1:0] wb_value,

  // with alu and ls(exe)
  output reg [DATA_WIDTH-1:0] exe_rs1,
  output reg [DATA_WIDTH-1:0] exe_rs2
);

  localparam REG_SIZE = 2**REG_WIDTH;

  reg [DATA_WIDTH-1:0] registers [REG_SIZE-1:0];

  integer i;
  always @(posedge clk) begin
    if (rst) begin
      exe_rs1 <= 0;
      exe_rs2 <= 0;
      for (i = 0; i < REG_SIZE; i = i + 1) begin
        registers[i] <= 0;
      end
    end else begin
      exe_rs1 <= registers[sb_rs1];
      exe_rs2 <= registers[sb_rs2];
      if (wb_valid) begin
        registers[wb_rd] <= wb_value;
      end
    end
  end

endmodule
