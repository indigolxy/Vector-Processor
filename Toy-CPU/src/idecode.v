
module i_decode 
#(
  parameter INST_WIDTH = 32,
  parameter DATA_WIDTH = 32
)
(
  input wire clk,
  input wire rst,

  // with i_fetch
  input wire inst_valid,
  input wire [INST_WIDTH-1:0] inst,
  output wire if_vacant,

  // with i_buffer
  input wire ib_vacant,
  output wire ib_valid,
  output reg [OPT_SIZE-1:0] ib_opt,
  output reg [FUNCT_SIZE-1:0] ib_funct,
  output reg [REG_SIZE-1:0] ib_rs1,
  output reg [REG_SIZE-1:0] ib_rs2,
  output reg [REG_SIZE-1:0] ib_rd,
  output reg [DATA_WIDTH-1:0] ib_imm
);

assign if_vacant = ib_vacant;
assign ib_valid = inst_valid;

localparam OPT_SIZE = 7;
localparam FUNCT_SIZE = 3;
localparam REG_SIZE = 5;

localparam OPCODE_B = 7'b1100011;
localparam OPCODE_L = 7'b0000011;
localparam OPCODE_S = 7'b0100011;
localparam OPCODE_I = 7'b0010011;
localparam OPCODE_R = 7'b0110011;

always @(*) begin
  if (rst) begin
    ib_opt <= 7'b0;
    ib_rs1 <= 5'b0;
    ib_rs2 <= 5'b0;
    ib_rd  <= 5'b0;
    ib_imm <= 32'h0;
  end else begin
    ib_opt <= inst[6:0];
    ib_rs1 <= inst[19:15];
    ib_funct <= inst[14:12];

    case (inst[6:0])
      OPCODE_B: begin
        ib_rs2 <= inst[24:20];
        ib_rd  <= 5'b0;
        ib_imm <= {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
      end
      OPCODE_L: begin
        ib_rs2 <= 5'b0;
        ib_rd  <= inst[11:7];
        ib_imm <= {{20{inst[31]}}, inst[31:20]};
      end
      OPCODE_S: begin
        ib_rs2 <= inst[24:20];
        ib_rd  <= 5'b0;
        ib_imm <= {{20{inst[31]}}, inst[31:25], inst[11:7]};
      end
      OPCODE_I: begin
        ib_rs2 <= 5'b0;
        ib_rd  <= inst[11:7];
        ib_imm <= {{20{inst[31]}}, inst[31:20]};
      end
      OPCODE_R: begin
        ib_rs2 <= inst[24:20];
        ib_rd  <= inst[11:7];
        ib_imm <= 32'h0;
      end
      default: begin
        ib_rs2 <= 5'b0;
        ib_rd  <= 5'b0;
        ib_imm <= 32'h0;
      end
    endcase
  end
end

endmodule