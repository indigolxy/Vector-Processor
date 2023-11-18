
module i_fetch(
    input wire clk,
    // input wire rst,

    input reg offset_valid,
    input wire [31:0] offset,

    output reg inst_valid, 
    output wire [31:0] inst,

    // interaction with memory
    input wire mem_done,
    output reg mem_valid,
    output wire [31:0] mem_addr,
    input wire [31:0] mem_inst
);
reg [31:0] pc; // ! initial value = 0?
reg status;
reg wait_for_br;
reg [31:0] instruction;
localparam IDLE = 0, WAIT_MEM = 1;
assign inst = instruction;
assign mem_addr = pc;

always @(posedge clk) begin
    pc <= pc + offset;
    if (status == IDLE) begin
      mem_valid  <= 1;
      status <= WAIT_MEM;
    end else begin
      if (mem_done) begin
        inst_valid <= 1;
        instruction <= mem_inst;
        status <= IDLE;
        mem_valid <= 0;
        pc <= pc + 4;
        // bne
        if (instruction[6:0] == 7'b1100011 && instruction[14:12] == 3'b001) begin
          wait_for_br <= 1;
        end
      end
    end
end

endmodule