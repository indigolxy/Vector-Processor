`include "macros.v"
// `include "./src/macros.v"
// `include "./src/vpu.v"
// `include "./src/ram.v"

module riscv_top
// #(
// 	parameter SIM = 0						// whether in simulation
// )
(
	input wire 			EXCLK,
	input wire			btnC
	// output wire 		Tx,
	// input wire 			Rx,
	// output wire			led
);

reg rst;
// reg rst_delay;
always @(posedge clk or posedge btnC)
begin
	if (btnC)
		rst			<=	1'b1;
	else 
    rst <= 1'b0;
end

wire clk;
assign clk = EXCLK;

wire [`XLEN-1:0] addr_a;
wire [`RAM_DATA_WID] data_a;
wire we_b;
wire [`RAM_DATA_WID] src_b;
wire [`XLEN-1:0] addr_b;
wire [`RAM_DATA_WID] data_b;

vpu my_vpu (
	.clk_in(clk),
	.rst_in(rst),
	.mem_addr_a(addr_a),
	.mem_data_a(data_a),
	.mem_we_b(we_b),
	.mem_src_b(src_b),
	.mem_addr_b(addr_b),
	.mem_data_b(data_b)
);

ram my_ram (
	.clk(clk),
	.addr_a(addr_a[`RAM_ADDR_WID]),
	.dout_a(data_a),
	.we_b(we_b),
	.din_b(data_b),
	.addr_b(addr_b[`RAM_ADDR_WID]),
	.dout_b(data_b)
);

endmodule