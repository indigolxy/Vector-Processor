// riscv top module file
// modification allowed for debugging purposes
`include "./src/cpu.v"
`include "./src/ram.v"

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

// localparam SYS_CLK_FREQ = 100000000;
// localparam UART_BAUD_RATE = 115200;
localparam RAM_ADDR_WIDTH = 17; 			// 128KiB ram, should not be modified
localparam DATA_WIDTH = 32;					// data width of cpu
localparam ADDR_WIDTH = 32;					// address width of cpu

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

wire [ADDR_WIDTH-1:0] addr_a;
wire [DATA_WIDTH-1:0] data_a;
wire we_b;
wire [DATA_WIDTH-1:0] src_b;
output wire [ADDR_WIDTH-1:0] addr_b;
input wire [DATA_WIDTH-1:0] data_b;

cpu #(
	.MEM_ADDR_WIDTH(ADDR_WIDTH),
	.MEM_DATA_WIDTH(DATA_WIDTH),
	.INST_WIDTH(DATA_WIDTH)
) my_cpu (
	.clk_in(clk),
	.rst_in(rst),
	// .rdy_in(1'b1),
	.mem_addr_a(addr_a),
	.mem_data_a(data_a),
	.mem_wr_b(we_b),
	.mem_src_b(src_b),
	.mem_addr_b(addr_b),
	.mem_data_b(data_b)
);

ram #(
	.ADDR_WIDTH(RAM_ADDR_WIDTH),
	.DATA_WIDTH(DATA_WIDTH)
) my_ram (
	.clk(clk),
	.addr_a(addr_a[RAM_ADDR_WIDTH-1:0]),
	.dout_a(data_a),
	.we_b(we_b),
	.din_b(data_b),
	.addr_b(addr_b[RAM_ADDR_WIDTH-1:0]),
	.dout_b(data_b)
);

endmodule