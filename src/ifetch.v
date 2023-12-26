`include "macros.v"
// `include "./src/macros.v"

module i_fetch
(
  input wire clk,
  input wire rst,

  // from bus
  input wire wb_valid,
  input wire [`SB_SIZE_WID] wb_pos,
  input wire [`REG_WID] wb_rd,
  input wire [`VLEN-1:0] wb_value,

  // with i_decode
  input wire id_vacant,
  output reg id_valid, 
  output reg [`INST_WID] id_inst,

  // interaction with memory
  input wire mc_done,
  input wire [`INST_WID] mc_inst,
  output reg mc_valid,
  output wire [`XLEN-1:0] mc_addr
);
reg [`XLEN-1:0] pc; // ! initial value = 0?
reg [2:1] status;
reg [`INST_WID] instruction;
localparam IDLE = 2'b00, WAIT_MEM = 2'b01, WAIT_DECODE = 2'b10, STALL = 2'b11;
assign mc_addr = pc;

always @(posedge clk) begin
  if (rst) begin
      pc <= 0;
      mc_valid <= 0;
      id_valid <= 0;
      id_inst <= 0;
      status <= IDLE;
      instruction <= 0;
  end else begin
    case (status)
    IDLE: begin
      mc_valid <= 1;
      id_valid <= 0;
      status <= WAIT_MEM;
    end
    WAIT_MEM: begin
      mc_valid <= 0;
      id_valid <= 0;
      if (mc_done) begin
        pc <= pc + 4;
        instruction <= mc_inst;
        status <= WAIT_DECODE;
      end
    end
    WAIT_DECODE: begin
      if (id_vacant) begin
        id_valid <= 1;
        id_inst <= instruction;
        // bne
        if (instruction[6:0] == 7'b1100011 && instruction[14:12] == 3'b001) begin
          status <= STALL;
        end else begin
          status <= IDLE;
        end
      end
    end
    STALL: begin
      id_valid <= 0;
      if (wb_valid && wb_rd == 0 && wb_pos < `ALU_ENTRY_SIZE) begin
        pc <= pc + wb_value[`XLEN-1:0];
        status <= IDLE;
      end
    end
  endcase
  end
end

endmodule