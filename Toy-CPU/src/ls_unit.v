
module ls_unit 
#(
  parameter SB_SIZE_WIDTH = 4,
  parameter DATA_WIDTH = 32
)
(
  input wire clk,
  input wire rst,

  // from exe broadcast
  input wire valid,
  input wire dest, // 0 for alu, 1 for ls
  input wire [SB_SIZE_WIDTH-1:0] pos,
  input wire [OPT_WIDTH-1:0]     opt,
  input wire [FUNCT_WIDTH-1:0]   funct,
  input wire [REG_WIDTH-1:0]     rd,
  input wire [DATA_WIDTH-1:0]    imm,

  input wire [DATA_WIDTH-1:0]    rs1,
  input wire [DATA_WIDTH-1:0]    rs2,

  // with wb_buffer
  output reg wb_valid,
  output reg [SB_SIZE_WIDTH-1:0] wb_pos,
  output reg [REG_WIDTH-1:0]     wb_rd,
  output reg  [DATA_WIDTH-1:0]    wb_value,

  // with mc
  input wire mc_done,
  input wire mc_data,
  output reg mc_valid,
  output reg mc_we,
  output reg [DATA_WIDTH-1:0] mc_src,
  output reg [DATA_WIDTH-1:0] mc_addr
);

  localparam OPT_WIDTH = 7;
  localparam FUNCT_WIDTH = 3;
  localparam REG_WIDTH = 5;

  localparam OPCODE_L = 7'b0000011;
  localparam OPCODE_S = 7'b0100011;

  reg [1:0] status;
  localparam IDLE = 2'b00, EXE = 2'b01, WAIT = 2'b10;

  reg [OPT_WIDTH-1:0] opt_save;
  reg [FUNCT_WIDTH-1:0] funct_save;
  reg [DATA_WIDTH-1:0] imm_save;

  always @(posedge clk) begin
    if (rst) begin
      wb_valid <= 0;
      wb_pos <= 0;
      wb_rd <= 0;
      wb_value <= 0;
      mc_valid <= 0;
      mc_we <= 0;
      mc_src <= 0;
      mc_addr <= 0;
      status <= 0;
      imm_save <= 0;
      opt_save <= 0;
      funct_save <= 0;
    end else begin
      case (status)
      IDLE: begin
        wb_valid <= 0;
        if (valid && dest) begin
          wb_pos <= pos;
          wb_rd <= rd;
          imm_save <= imm;
          opt_save <= opt;
          funct_save <= funct;
          status <= EXE;
        end
      end
      EXE: begin
        mc_valid <= 1;
        mc_we <= (opt_save == OPCODE_S);
        mc_addr <= rs1 + imm_save;
        if (opt_save == OPCODE_S) begin
          mc_src <= rs2;
        end else begin
          mc_src <= 0;
        end
        status <= WAIT;
      end
      WAIT: begin
        mc_valid <= 0;
        if (mc_done) begin
          wb_valid <= 1;
          wb_value <= mc_data;
          status <= IDLE;
        end
      end
      endcase
    end
  end

endmodule