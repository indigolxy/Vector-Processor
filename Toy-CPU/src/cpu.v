`include "./src/ifetch.v"

// RISCV32I CPU top module
// port modification allowed for debugging purposes

module cpu
#(
  parameter MEM_ADDR_WIDTH = 32, 
  parameter MEM_DATA_WIDTH = 32, 
  parameter INST_WIDTH = 32
)
(
  input wire clk_in,
  input wire rst_in,
	// input  wire					    rdy_in,			// ready signal, pause cpu when low

  output  wire [MEM_ADDR_WIDTH-1:0] mem_addr_a, // only 16 bits used
  input wire [MEM_DATA_WIDTH-1:0] mem_data_a,

  output  wire                  mem_wr_b,
  output  wire [MEM_DATA_WIDTH-1:0] mem_src_b,
  output  wire [MEM_ADDR_WIDTH-1:0] mem_addr_b,
  input wire [MEM_DATA_WIDTH-1:0] mem_data_b
	
	// output wire [31:0]			dbgreg_dout		// cpu register output (debugging demo)
);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)

wire [MEM_ADDR_WIDTH-1:0] if_to_ram_addr;
wire                      if_to_ram_valid;
wire [MEM_DATA_WIDTH-1:0] ram_to_if_data;
wire                      ram_to_if_done;

wire                      id_to_if_vacant;
wire                      if_to_id_valid;
wire [INST_WIDTH-1:0]     if_to_id_inst;

wire                      wb_to_if_valid;
wire [MEM_ADDR_WIDTH-1:0] wb_to_if_offset;

i_fetch #(.ADDR_WIDTH(32),
         .INST_WIDTH(32)) u_IFetch(
  .clk          	(clk_in),
  .offset_valid 	(wb_to_if_valid),
  .offset       	(wb_to_if_offset),
  .inst_vacant  	(id_to_if_vacant),
  .inst_valid   	(if_to_id_valid),
  .inst         	(if_to_id_inst),
  .mem_done     	(ram_to_if_done),
  .mem_inst     	(ram_to_if_data),
  .mem_valid    	(if_to_ram_valid),
  .mem_addr     	(if_to_ram_addr)
);


always @(posedge clk_in)
  begin
    if (rst_in)
      begin
      
      end
    else
      begin
      
      end
  end

endmodule