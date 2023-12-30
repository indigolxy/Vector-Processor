`include "./macros.v"
// `include "./src/macros.v"

module alu
(
  input wire clk,
  input wire rst,

  // with register
  input wire exe_valid,
  input wire [`VLEN-1:0] value1,
  input wire [`VLEN-1:0] value2,
  input wire [`SB_SIZE_WID] pos,
  input wire [`OPT_WID] opt,
  input wire [`FUNCT3_WID] funct3,
  input wire [`FUNCT6_WID] funct6,
  input wire [`REG_WID] rd,
  input wire [`XLEN-1:0] imm,

  // with CSRs
  input wire [`XLEN-1:0] vl,
  input wire [`XLEN-1:0] sew,
  output reg csr_we,
  output reg [`XLEN-1:0] vl_set,
  output reg [`XLEN-1:0] sew_set,

  // with wb buffer
  output reg wb_valid,
  output reg [`SB_SIZE_WID] wb_pos,
  output reg [`REG_WID] wb_rd,
  output reg [`VLEN-1:0] wb_value
);

// for vector:
reg [`XLEN-1:0] vector_op1 [0:`VLMAX-1]; // consider vx,vi
reg [`XLEN-1:0] vector_op2 [0:`VLMAX-1];
reg [`XLEN-1:0] vector_res [0:`VLMAX-1]; 
reg [`VLEN-1:0] vector_res_v;

reg [`XLEN-1:0] cut_mask; // {(XLEN-sew){1'b0},sew{1'b1}}
integer init_i;
initial begin
  for (init_i = 0; init_i < sew; init_i = init_i + 1) begin
    cut_mask[init_i] = 1;
  end
end

integer i;
always @* begin
  for (i = 0; i < vl; i = i + 1) begin
    // ! 这样切割对吗？
    vector_op2[i] = value2[i*sew+:`XLEN];
    if (vector_op2[i][sew-1] == 0) begin
      vector_op2[i] = vector_op2[i] & cut_mask;
    end else begin
      vector_op2[i] = vector_op2[i] | ~cut_mask;
    end

    case (funct3)
    3'b000: begin 
      vector_op1[i] = value1[i*sew+:`XLEN];
      if (vector_op1[i][sew-1] == 0) begin
        vector_op1[i] = vector_op1[i] & cut_mask;
      end else begin
        vector_op1[i] = vector_op1[i] | ~cut_mask;
      end
    end
    // ! 需要对 imm 和 value1 进行截位 + sign-extend 吗？
    3'b100: vector_op1[i] = value1;
    3'b011: vector_op1[i] = imm;
    default: vector_op1[i] = 0;
    endcase
    
    vector_res_v[i*sew+:`XLEN] = vector_res[i];
    vector_res_v = vector_res_v & (cut_mask << (i*sew));
  end
end

integer j;
always @* begin
  if (opt == `OPCODE_VA) begin
    for (j = 0; j < vl; j = j + 1) begin
      case (funct6)
      6'b000000: vector_res[j] = vector_op2[j] + vector_op1[j];
      6'b000010: vector_res[j] = vector_op2[j] - vector_op1[j];
      6'b000011: vector_res[j] = vector_op1[j] - vector_op2[j];

      6'b000100: vector_res[j] = (vector_op1[j] < vector_op2[j]) ? vector_op1[j] : vector_op2[j];
      6'b000101: vector_res[j] = ($signed(vector_op1[j]) < $signed(vector_op2[j])) ? vector_op1[j] : vector_op2[j];
      6'b000110: vector_res[j] = (vector_op1[j] < vector_op2[j]) ? vector_op2[j] : vector_op1[j];
      6'b000111: vector_res[j] = ($signed(vector_op1[j]) < $signed(vector_op2[j])) ? vector_op2[j] : vector_op1[j];

      6'b001001: vector_res[j] = vector_op1[j] & vector_op2[j];
      6'b001010: vector_res[j] = vector_op1[j] | vector_op2[j];
      6'b001100: vector_res[j] = vector_op1[j] ^ vector_op2[j];

      6'b100101: vector_res[j] = (vector_op1[j] < sew) ? vector_op2[j] << vector_op1[j] : 0;
      6'b101000: vector_res[j] = (vector_op1[j] < sew) ? vector_op2[j] >>> vector_op1[j] : 0;
      6'b101001: vector_res[j] = (vector_op1[j] < sew) ? vector_op2[j] >> vector_op1[j] : 0;

      default: vector_res[j] = 0;
      endcase
    end
  end else begin
    for (j = 0; j < vl; j = j + 1) begin
      vector_res[j] = 0;
    end
  end
end

// for scalar:
reg jump; // only for branch(scalar)
// only for arith-scalar
wire [`XLEN-1:0] scalar_op1 = value1[`XLEN-1:0];
wire [`XLEN-1:0] scalar_op2 = opt == `OPCODE_R ? value2[`XLEN-1:0] : imm;
reg [`XLEN-1:0] scalar_res;

  always @(*) begin
    if (opt == `OPCODE_I || opt == `OPCODE_R) begin
    case (funct3)
      3'b000:  scalar_res = scalar_op1 + scalar_op2;
      3'b100:  scalar_res = scalar_op1 ^ scalar_op2;
      3'b110:   scalar_res = scalar_op1 | scalar_op2;
      3'b111:  scalar_res = scalar_op1 & scalar_op2;
      3'b001:  scalar_res = scalar_op1 << scalar_op2;
      3'b101: scalar_res = scalar_op1 >> scalar_op2[5:0];
      3'b010:  scalar_res = ($signed(scalar_op1) < $signed(scalar_op2));
      3'b011: scalar_res = (scalar_op1 < scalar_op2);
    endcase
    end else begin
      scalar_res = 0;
    end
  end

  always @(*) begin
    if (opt == `OPCODE_B) begin
    case (funct3)
      3'b000:  jump = (value1 == value2);
      3'b001:  jump = (value1 != value2);
      3'b100:  jump = ($signed(value1) < $signed(value2));
      3'b101:  jump = ($signed(value1) >= $signed(value2));
      3'b110: jump = (value1 < value2);
      3'b111: jump = (value1 >= value2);
      default: jump = 0;
    endcase
    end else begin
      jump = 0;
    end
  end


  always @(posedge clk) begin
    if (rst) begin
      csr_we <= 0;
      vl_set <= 0;
      sew_set <= 0;
      wb_valid <= 0;
      wb_pos <= 0;
      wb_rd <= 0;
      wb_value <= 0;
    end else begin
      if (exe_valid) begin
        wb_valid <= 1;
        wb_pos <= pos;
        wb_rd <= rd;
        csr_we <= (opt == `OPCODE_VA && funct3 == 3'b111) ? 1 : 0;

        if (opt == `OPCODE_B) begin
          wb_value <= jump ? imm : 0;
        end else if (opt == `OPCODE_I || opt == `OPCODE_R) begin
          wb_value <= scalar_res;
        end else if (opt == `OPCODE_VA && funct3 != 3'b111) begin
          wb_value <= vector_res_v;
        end else if (opt == `OPCODE_VA && funct3 == 3'b111) begin
          // ! 算的对吗？
          vl_set <= (`VLEN/sew < value1) ? `VLEN/sew : value1;
          sew_set <= 8*2^(imm[4:2]);
          wb_value <= (`VLEN/sew < value1) ? `VLEN/sew : value1;
        end else begin
            wb_value <= 0; // ~ invalid instruction
        end
      end else begin
        csr_we <= 0;
        vl_set <= 0;
        sew_set <= 0;
        wb_valid <= 0;
        wb_pos <= 0;
        wb_rd <= 0;
        wb_value <= 0;
      end
    end
  end

endmodule
