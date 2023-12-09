module i_fetch
#(
  parameter ADDR_WIDTH = 32,
  parameter INST_WIDTH = 32
)
(
    input wire clk,
    input wire rst,

    input wire offset_valid,
    input wire [ADDR_WIDTH-1:0] offset,

    input wire inst_vacant,
    output reg inst_valid, 
    output wire [INST_WIDTH-1:0] inst,

    // interaction with memory
    input wire mem_done,
    input wire [INST_WIDTH-1:0] mem_inst,
    output reg mem_valid,
    output wire [ADDR_WIDTH-1:0] mem_addr
);
reg [ADDR_WIDTH-1:0] pc; // ! initial value = 0?
reg [2:1] status;
reg [INST_WIDTH-1:0] instruction;
localparam IDLE = 2'b00, WAIT_MEM = 2'b01, STALL = 2'b10, WAIT_DECODE = 2'b11;
assign inst = instruction;
assign mem_addr = pc;

always @(posedge clk) begin
  if (rst) begin
      pc    <= 32'h0;
      mem_valid <= 0;
      inst_valid <= 0;
      status   <= IDLE;
  end else begin
    case (status)
    IDLE: begin
      mem_valid  <= 1;
      inst_valid <= 0;
      status <= WAIT_MEM;
    end
    WAIT_MEM: begin
      if (mem_done) begin
        mem_valid <= 0;
        pc <= pc + 4;
        // bne
        if (instruction[6:0] == 7'b1100011 && instruction[14:12] == 3'b001) begin
          status <= STALL;
        end else begin
          status <= WAIT_DECODE;
        end
      end
    end
    STALL: begin
      if (offset_valid) begin
        pc <= pc + offset;
        status <= WAIT_DECODE;
      end
    end
    WAIT_DECODE: begin
      if (inst_vacant) begin
        inst_valid <= 1;
        instruction <= mem_inst;
        status <= IDLE;
      end
    end
  endcase
  end
end

endmodule