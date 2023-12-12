
module i_buffer
#(
  parameter IB_SIZE_WIDTH = 4,
  parameter DATA_WIDTH = 32
)
(
  input wire clk,
  input wire rst,

  // with i_decode
  output reg id_vacant,
  input wire id_valid,
  input wire [OPT_SIZE-1:0] id_opt,
  input wire [FUNCT_SIZE-1:0] id_funct,
  input wire [REG_SIZE-1:0] id_rs1,
  input wire [REG_SIZE-1:0] id_rs2,
  input wire [REG_SIZE-1:0] id_rd,
  input wire [DATA_WIDTH-1:0] id_imm,

  // with scoreboard
  // output wire ie_vacant,
  // output wire ie_valid,
  // output reg [OPT_SIZE-1:0] ie_opt,
  // output reg [FUNCT_SIZE-1:0] ie_funct,
  // output reg [REG_SIZE-1:0] ie_rs1,
  // output reg [REG_SIZE-1:0] ie_rs2,
  // output reg [REG_SIZE-1:0] ie_rd,
  // output reg [DATA_WIDTH-1:0] ie_imm
);

localparam IB_SIZE = 2**IB_SIZE_WIDTH;
localparam OPT_SIZE = 7;
localparam FUNCT_SIZE = 3;
localparam REG_SIZE = 5;

reg [OPT_SIZE-1:0] opt [IB_SIZE-1:0];
reg [FUNCT_SIZE-1:0] funct [IB_SIZE-1:0];
reg [REG_SIZE-1:0] rs1 [IB_SIZE-1:0];
reg [REG_SIZE-1:0] rs2 [IB_SIZE-1:0];
reg [REG_SIZE-1:0] rd [IB_SIZE-1:0];
reg [DATA_WIDTH-1:0] imm [IB_SIZE-1:0];

reg [IB_SIZE_WIDTH-1:0] head, tail;

always @(posedge clk) begin
  if (rst) begin
    head <= 0;
    tail <= 0;
    id_vacant <= 1;
    for (integer i = 0; i < IB_SIZE; i = i + 1) begin
        opt[i] <= 0;
        funct[i] <= 0;
        rs1[i] <= 0;
        rs2[i] <= 0;
        rd[i] <= 0;
        imm[i] <= 0;
    end
  end else begin
    // if (id_valid && id_vacant) begin
    //   opt[tail] <= id_opt;
    //   funct[tail] <= id_funct;
    //   rs1[tail] <= id_rs1;
    //   rs2[tail] <= id_rs2;
    //   rd[tail] <= id_rd;
    //   imm[tail] <= id_imm;
    //   tail <= tail + 1;
    //   id_vacant <= 0;
    // end
    // if (ie_valid && ie_vacant) begin
    //   ie_opt <= opt[head];
    //   ie_funct <= funct[head];
    //   ie_rs1 <= rs1[head];
    //   ie_rs2 <= rs2[head];
    //   ie_rd <= rd[head];
    //   ie_imm <= imm[head];
    //   head <= head + 1;
    //   ie_vacant <= 0;
    // end
  end
end

endmodule