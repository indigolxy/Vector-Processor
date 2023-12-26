`include "macros.v"
// `include "./src/macros.v"

module i_decode 
(
  input wire clk,
  input wire rst,

  // with i_fetch
  input wire if_valid,
  input wire [`INST_WID] inst,
  output wire if_vacant,

  // with i_buffer
  input wire ib_vacant,
  output wire ib_valid,
  output reg [`OPT_WID] ib_opt,
  output reg [`FUNCT3_WID] ib_funct,
  output reg [`REG_WID] ib_rs1,
  output reg [`REG_WID] ib_rs2,
  output reg [`REG_WID] ib_rd,
  output reg [`XLEN-1:0] ib_imm
);

assign if_vacant = ib_vacant;
assign ib_valid = if_valid;

always @(*) begin
  if (rst) begin
    ib_opt <= 0;
    ib_funct <= 0;
    ib_rs1 <= 0;
    ib_rs2 <= 0;
    ib_rd  <= 0;
    ib_imm <= 0;
  end else begin
    ib_opt <= inst[6:0];
    ib_funct <= inst[14:12];

    case (inst[6:0])
      `OPCODE_B: begin
        ib_rs1 <= {1'b0, inst[19:15]};
        ib_rs2 <= {1'b0,{inst[24:20]}};
        ib_rd  <= 6'b0;
        ib_imm <= {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
      end
      `OPCODE_L: begin
        ib_rs1 <= {1'b0, inst[19:15]};
        ib_rs2 <= 6'b0;
        ib_rd  <= {1'b0, inst[11:7]};
        ib_imm <= {{20{inst[31]}}, inst[31:20]};
      end
      `OPCODE_S: begin
        ib_rs1 <= {1'b0, inst[19:15]};
        ib_rs2 <= {1'b0, inst[24:20]};
        ib_rd  <= 6'b0;
        ib_imm <= {{20{inst[31]}}, inst[31:25], inst[11:7]};
      end
      `OPCODE_I: begin
        ib_rs1 <= {1'b0, inst[19:15]};
        ib_rs2 <= 6'b0;
        ib_rd  <= {1'b0, inst[11:7]};
        ib_imm <= {{20{inst[31]}}, inst[31:20]};
      end
      `OPCODE_R: begin
        ib_rs1 <= {1'b0, inst[19:15]};
        ib_rs2 <= {1'b0, inst[24:20]};
        ib_rd  <= {1'b0, inst[11:7]};
        ib_imm <= 32'h0;
      end
      `OPCODE_VA: begin
        case (inst[14:12])
        3'b111: begin
          ib_rs1 <= {1'b0, inst[19:15]};
          ib_rs2 <= 6'b0;
          ib_rd  <= {1'b0, inst[11:7]};
          ib_imm <= {21'b0, inst[30:20]};
        end
        3'b000: begin
          ib_rs1 <= {1'b1, inst[19:15]};
          ib_rs2 <= {1'b1, inst[24:20]};
          ib_rd  <= {1'b1, inst[11:7]};
          ib_imm <= 32'h0;
        end
        3'b100: begin
          ib_rs1 <= {1'b0, inst[19:15]};
          ib_rs2 <= {1'b1, inst[24:20]};
          ib_rd  <= {1'b1, inst[11:7]};
          ib_imm <= 32'h0;
        end
        3'b011: begin
          ib_rs1 <= 6'b0;
          ib_rs2 <= {1'b1, inst[24:20]};
          ib_rd  <= {1'b1, inst[11:7]};
          ib_imm <= {{27{inst[19]}}, inst[19:15]};
        end
        endcase
      end
      `OPCODE_VL: begin
        ib_rs1 <= {1'b0, inst[19:15]};
        ib_rs2 <= 6'b0;
        ib_rd  <= {1'b1, inst[11:7]};
        ib_imm <= 32'h0;
      end
      `OPCODE_VS: begin
        ib_rs1 <= {1'b0, inst[19:15]};
        ib_rs2  <= {1'b1, inst[11:7]};
        ib_rd  <= 6'b0;
        ib_imm <= 32'h0;
      end
      default: begin
        ib_rs1 <= 6'b0;
        ib_rs2 <= 6'b0;
        ib_rd  <= 6'b0;
        ib_imm <= 32'h0;
      end
    endcase
  end
end

endmodule