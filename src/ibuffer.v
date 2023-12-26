`include "./macros.v"
// `include "./src/macros.v"

module i_buffer
(
  input wire clk,
  input wire rst,

  // with i_decode
  output reg id_vacant,
  input wire id_valid,
  input wire [`OPT_WID] id_opt,
  input wire [`FUNCT3_WID] id_funct,
  input wire [`REG_WID] id_rs1,
  input wire [`REG_WID] id_rs2,
  input wire [`REG_WID] id_rd,
  input wire [`XLEN-1:0] id_imm,

  // with scoreboard
  input wire sb_vacant_ALU,
  input wire sb_vacant_LS,
  output reg sb_valid,
  output wire [`OPT_WID] sb_opt,
  output wire [`FUNCT3_WID] sb_funct,
  output wire [`REG_WID] sb_rs1,
  output wire [`REG_WID] sb_rs2,
  output wire [`REG_WID] sb_rd,
  output wire [`XLEN-1:0] sb_imm
);

localparam OPCODE_B = 7'b1100011;
localparam OPCODE_L = 7'b0000011;
localparam OPCODE_S = 7'b0100011;
localparam OPCODE_I = 7'b0010011;
localparam OPCODE_R = 7'b0110011;

reg [`OPT_WID] opt [`IB_SIZE-1:0];
reg [`FUNCT3_WID] funct [`IB_SIZE-1:0];
reg [`REG_WID] rs1 [`IB_SIZE-1:0];
reg [`REG_WID] rs2 [`IB_SIZE-1:0];
reg [`REG_WID] rd [`IB_SIZE-1:0];
reg [`XLEN-1:0] imm [`IB_SIZE-1:0];

reg [`IB_WID] front, rear;

assign sb_opt = opt[front];
assign sb_funct = funct[front];
assign sb_rs1 = rs1[front];
assign sb_rs2 = rs2[front];
assign sb_rd = rd[front];
assign sb_imm = imm[front];

reg [1:0] send_status, receive_status;

localparam WAIT_RECEIVE = 2'b00, RECEIVED = 2'b01, FULL = 2'b10;
localparam WAIT_SEND = 2'b00, SENT = 2'b01, POP = 2'b10, EMPTY = 2'b11;

integer i;
always @(posedge clk) begin
  if (rst) begin
    front <= 0;
    rear <= 0;
    receive_status <= WAIT_RECEIVE;
    id_vacant <= 1;
    send_status <= EMPTY;
    sb_valid <= 0;
    for (i = 0; i < `IB_SIZE; i = i + 1) begin
        opt[i] <= 0;
        funct[i] <= 0;
        rs1[i] <= 0;
        rs2[i] <= 0;
        rd[i] <= 0;
        imm[i] <= 0;
    end
  end else begin
    // for receive: 
    // might modify: id_vacant, receive_status, rear, the regs
    case (receive_status)
    WAIT_RECEIVE: begin
      if (id_valid) begin
        // receive the inst from id
        opt[rear] <= id_opt;
        funct[rear] <= id_funct;
        rs1[rear] <= id_rs1;
        rs2[rear] <= id_rs2;
        rd[rear] <= id_rd;
        imm[rear] <= id_imm;
        // push
        if (rear == `IB_SIZE - 1) begin
          rear <= 0;
        end else begin
          rear <= rear + 1;
        end
        // set status
        id_vacant <= 0;
        receive_status <= RECEIVED;
      end
    end
    RECEIVED: begin
      if ((rear == `IB_SIZE - 1 && front == 0) || (rear == front - 1)) begin
        receive_status <= FULL;
      end else begin
        id_vacant <= 1;
        receive_status <= WAIT_RECEIVE;
      end
    end
    FULL: begin
      if ((rear == `IB_SIZE - 1 && front == 0) || (rear == front - 1)) begin
      end else begin
        id_vacant <= 1;
        receive_status <= WAIT_RECEIVE;
      end
    end
    endcase

    // for send:
    // might modify: sb_valid, send_status, front
    case (send_status)
    EMPTY : begin
      if (front != rear) begin
        send_status <= WAIT_SEND;
      end
    end
    WAIT_SEND: begin
      if (sb_vacant_ALU && (opt[front] == OPCODE_B || opt[front] == OPCODE_I || opt[front] == OPCODE_R)) begin
        sb_valid <= 1;
        send_status <= SENT;
      end else if (sb_vacant_LS && (opt[front] == OPCODE_L || opt[front] == OPCODE_S)) begin
        sb_valid <= 1;
        send_status <= SENT;
      end
    end
    SENT: begin
      sb_valid <= 0;
      if (front == `IB_SIZE - 1) begin
        front <= 0;
      end else begin
        front <= front + 1;
      end
      send_status <= POP;
    end
    POP: begin
      if (front == rear) begin
        send_status <= EMPTY;
      end else begin
        send_status <= WAIT_SEND;
      end
    end
    endcase
  end
end

endmodule