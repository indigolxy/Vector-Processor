`include "macros.v"
// `include "./src/macros.v"

module ram
(
  input  wire                  clk,

  input  wire [`RAM_ADDR_WID] addr_a,
  output reg [`RAM_DATA_WID] dout_a,

  input  wire                  we_b,
  input  wire [`RAM_DATA_WID] din_b,
  input  wire [`RAM_ADDR_WID] addr_b,
  output reg [`RAM_DATA_WID] dout_b
);

  reg [`RAM_DATA_WID] ram [`RAM_SIZE-1:0];

  always @(posedge clk) begin
    dout_a <= ram[addr_a];
    if (we_b) begin
      ram[addr_b] <= din_b;
    end else begin
      dout_b <= ram[addr_b];
    end
  end

  integer i;
  initial begin
    for (i = 0; i < `RAM_SIZE; i = i + 1) begin
      ram[i] = 0;
    end
  $readmemh("test.data", ram); // add test.data to vivado project or specify a valid file path
end

endmodule