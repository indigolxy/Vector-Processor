
module ram
#(
  parameter ADDR_WIDTH = 16,
  parameter DATA_WIDTH = 32
)
(
  input  wire                  clk,

  input  wire [ADDR_WIDTH-1:0] addr_a,
  output wire [DATA_WIDTH-1:0] dout_a,

  input  wire                  we_b,
  input  wire [DATA_WIDTH-1:0] din_b,
  input  wire [ADDR_WIDTH-1:0] addr_b,
  output wire [DATA_WIDTH-1:0] dout_b
);

reg [DATA_WIDTH-1:0] ram [2**ADDR_WIDTH-1:0];
reg [ADDR_WIDTH-1:0] q_addr_a;
reg [ADDR_WIDTH-1:0] q_addr_b;

always @(posedge clk)
  begin
    q_addr_a <= addr_a;
    // if (we)
    //     ram[addr_b] <= din_b;
    // q_addr_b <= addr_b;
  end

integer i;
initial begin
  for (i=0;i<2**ADDR_WIDTH;i=i+1) begin
    ram[i] = 0;
  end
  $readmemh("test.data", ram); // add test.data to vivado project or specify a valid file path
end

assign dout_a = ram[q_addr_a];
assign dout_b = ram[q_addr_b];

endmodule