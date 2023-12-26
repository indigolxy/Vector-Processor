
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
  output reg [DATA_WIDTH-1:0] if_data,
  
  // with ls
  input wire ls_valid,
  input wire ls_we,
  input wire [DATA_WIDTH-1:0] ls_src,
  input wire [ADDR_WIDTH-1:0] ls_addr,
  output reg ls_done,
  output reg [DATA_WIDTH-1:0] ls_data,

  // with ram (output of cpu)
  output reg [ADDR_WIDTH-1:0] addr_a, // address bus (only 17:0 is used)
  input wire [DATA_WIDTH-1:0] data_a,

  output reg [ADDR_WIDTH-1:0] addr_b, // address bus (only 17:0 is used)
  output reg we_b,
  output reg [DATA_WIDTH-1:0] src_b,
  input wire [DATA_WIDTH-1:0] data_b
);

  reg status_a, status_b;
  localparam IDLE = 1'b0, BUSY = 1'b1;

  always @(posedge clk) begin
    if (rst) begin
      if_done  <= 0;
      ls_done <= 0;
      addr_a    <= 0;
      addr_b    <= 0;
      we_b <= 0;
      status_a <= 0;
      status_b <= 0;
    end else begin
      case (status_a)
      IDLE: begin
        if_done <= 1'b0;
        if (if_valid) begin
          addr_a <= if_addr;
          status_a <= BUSY;
        end
      end
      BUSY: begin
        if_done <= 1'b1;
        if_data <= data_a;
        addr_a <= 0;
        status_a <= IDLE;
      end
      endcase

      case (status_b)
      IDLE: begin
        ls_done <= 0;
        if (ls_valid) begin
          addr_b <= ls_addr;
          we_b <= ls_we;
          if (ls_we) src_b <= ls_src;
          status_b <= BUSY;
        end
      end
      BUSY: begin
        ls_done <= 1'b1;
        if (we_b == 0) ls_data <= data_b;
        addr_b <= 0;
        src_b <= 0;
        we_b <= 0;
        status_b <= IDLE;
      end
      endcase
    end
  end

endmodule
