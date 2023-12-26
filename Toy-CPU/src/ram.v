
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

localparam RAM_SIZE = 2**ADDR_WIDTH;

reg [8-1:0] ram [RAM_SIZE-1:0];
reg [ADDR_WIDTH-1:0] q_addr_a;
reg [ADDR_WIDTH-1:0] q_addr_b;

always @(posedge clk)
  begin
    q_addr_a <= addr_a;
    q_addr_b <= addr_b;
    if (we_b)
      ram[addr_b] <= din_b;
  end

integer i;
initial begin
  for (i=0;i<RAM_SIZE;i=i+1) begin
    ram[i] = 0;
  end
  $readmemh("test.data", ram); // add test.data to vivado project or specify a valid file path
end

assign dout_a = {ram[q_addr_a + 3], ram[q_addr_a + 2], ram[q_addr_a + 1], ram[q_addr_a]};
assign dout_b = {ram[q_addr_b + 3], ram[q_addr_b + 2], ram[q_addr_b + 1], ram[q_addr_b]};

endmodule