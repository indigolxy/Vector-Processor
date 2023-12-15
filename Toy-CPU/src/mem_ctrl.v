
module mem_ctrl 
#(
  parameter ADDR_WIDTH = 32,
  parameter DATA_WIDTH = 32
)
(
  input wire clk,
  input wire rst,

  // with i_fetch
  input wire if_valid,
  input wire [ADDR_WIDTH-1:0] if_addr,
  output reg if_done,
  output wire [DATA_WIDTH-1:0] if_data,
  
  // with ls
  input wire ls_we,
  input wire [DATA_WIDTH-1:0] ls_src,
  input wire [ADDR_WIDTH-1:0] ls_addr,
  output reg ls_done,
  output wire [DATA_WIDTH-1:0] ls_data,

  // with ram (output of cpu)
  output reg [ADDR_WIDTH-1:0] addr_a, // address bus (only 17:0 is used)
  input wire [DATA_WIDTH-1:0] data_a,
  output reg [ADDR_WIDTH-1:0] addr_b, // address bus (only 17:0 is used)
  output reg wr_b,
  output wire [DATA_WIDTH-1:0] src_b,
  input wire [DATA_WIDTH-1:0] data_b
);

  assign if_data = data_a;

  reg status;
  localparam IDLE = 1'b0, BUSY = 1'b1;

  always @(posedge clk) begin
    if (rst) begin
      if_done  <= 0;
      ls_done <= 0;
      wr_b   <= 0;
      addr_a    <= 0;
      addr_b    <= 0;
      status <= 0;
    end else begin
      // todo: 多周期取数据：用state machine
      case (status)
      IDLE: begin
        if_done <= 1'b0;
        if (if_valid) begin
          addr_a <= if_addr;
          status <= BUSY;
        end
      end
      BUSY: begin
        if_done <= 1'b1;
        addr_a <= 0;
        status <= IDLE;
      end
      endcase
    end
    // if (write_en_b) begin
    //   mem[addr_b] <= data_b;
    // end
  end

endmodule
