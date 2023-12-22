
module alu
#(
  parameter SB_SIZE_WIDTH = 4,
  parameter DATA_WIDTH = 32
)
(
  input wire clk,
  input wire rst,

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
  output reg  [DATA_WIDTH-1:0]    wb_value
);

  localparam OPT_WIDTH = 7;
  localparam FUNCT_WIDTH = 3;
  localparam REG_WIDTH = 5;

  // assign wb_pos = pos;
  // assign wb_rd = rd;

  reg status;
  localparam IDLE = 1'b0, EXE = 1'b1;

  reg [OPT_WIDTH-1:0] opt_save;
  reg [FUNCT_WIDTH-1:0] funct_save;
  reg [DATA_WIDTH-1:0] imm_save;

  localparam OPCODE_B = 7'b1100011;
  localparam OPCODE_L = 7'b0000011;
  localparam OPCODE_S = 7'b0100011;
  localparam OPCODE_I = 7'b0010011;
  localparam OPCODE_R = 7'b0110011;

  always @(posedge clk) begin
    if (rst) begin
      wb_valid <= 0;
      wb_pos <= 0;
      wb_rd <= 0;
      wb_value <= 0;
      status <= IDLE;
      imm_save <= 0;
      opt_save <= 0;
      funct_save <= 0;
    end else begin
      case (status)
        IDLE: begin
          wb_valid <= 0;
          if (valid && dest == 0) begin
            status <= EXE;
            wb_pos <= pos;
            wb_rd <= rd;
            imm_save <= imm;
            opt_save <= opt;
            funct_save <= funct;
          end
        end
        EXE: begin
          wb_valid <= 1;
          status <= IDLE;
          if (opt_save == OPCODE_B) begin
            wb_value <= jump ? imm_save : 0;
          end else begin
            wb_value <= arith_res;
          end
        end
      endcase
    end
  end

  reg jump;
  always @(*) begin
    case (funct_save)
      3'b000:  jump = (rs1 == rs2);
      3'b001:  jump = (rs1 != rs2);
      3'b100:  jump = ($signed(rs1) < $signed(rs2));
      3'b101:  jump = ($signed(rs1) >= $signed(rs2));
      3'b110: jump = (rs1 < rs2);
      3'b111: jump = (rs1 >= rs2);
      default: jump = 0;
    endcase
  end

  wire [DATA_WIDTH-1:0] arith_op1 = rs1;
  wire [DATA_WIDTH-1:0] arith_op2 = opt_save == OPCODE_R ? rs2 : imm_save;
  reg [DATA_WIDTH-1:0] arith_res;
  always @(*) begin
    case (funct_save)
      3'b000:  arith_res = arith_op1 + arith_op2;
      3'b100:  arith_res = arith_op1 ^ arith_op2;
      3'b110:   arith_res = arith_op1 | arith_op2;
      3'b111:  arith_res = arith_op1 & arith_op2;
      3'b001:  arith_res = arith_op1 << arith_op2;
      3'b101: arith_res = arith_op1 >> arith_op2[5:0];
      3'b010:  arith_res = ($signed(arith_op1) < $signed(arith_op2));
      3'b011: arith_res = (arith_op1 < arith_op2);
    endcase
  end
  
endmodule

  // reg [5:0] operation;
  // localparam BEQ = 5'b00001, BNE = 5'b00010, BLT = 5'b00011, BGE = 5'b00100, BLTU = 5'b00101, BGEU = 5'b00110;
  // localparam ADDI = 5'b00110, SLTI = 5'b00111, SLTIU = 5'b01000, XORI = 5'b01001, ORI = 5'b01010, ANDI = 5'b01011, SLLI = 5'b01100, SRLI = 5'b01101, SRAI = 5'b01110;
  // localparam ADD = 5'b01111, SUB = 5'b10000, SLL = 5'b10001, SLT = 5'b10010, SLTU = 5'b10011, XOR = 5'b10100, SRL = 5'b10101, SRA = 5'b10110, OR = 5'b10111, AND = 5'b11000;

     /*
            // case (opt)
            // OPCODE_B: begin
            //   case (funct)
            //   3'b000: operation <= BEQ;
            //   3'b001: operation <= BNE;
            //   3'b100: operation <= BLT;
            //   3'b101: operation <= BGE;
            //   3'b110: operation <= BLTU;
            //   3'b111: operation <= BGEU;
            //   endcase
            // end
            // OPCODE_I: begin
            //   case (funct)
            //   3'b000: operation <= ADDI;
            //   3'b010: operation <= SLTI;
            //   3'b011: operation <= SLTIU;
            //   3'b100: operation <= XORI;
            //   3'b110: operation <= ORI;
            //   3'b111: operation <= ANDI;
            //   3'b001: operation <= SLLI;
            //   3'b101: operation <= SRLI;
            //   endcase
            // end
            // OPCODE_R: begin
            //   case (funct)
            //   3'b000: operation <= ADD;
            //   3'b001: operation <= SLL;
            //   3'b010: operation <= SLT;
            //   3'b011: operation <= SLTU;
            //   3'b100: operation <= XOR;
            //   3'b101: operation <= SRL;
            //   3'b110: operation <= OR;
            //   3'b111: operation <= AND;
            //   endcase
            // end
            */
