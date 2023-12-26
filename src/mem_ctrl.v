`include "macros.v"
// `include "./src/macros.v"

module mem_ctrl 
(
  input wire clk,
  input wire rst,

  // with i_fetch
  input wire if_valid,
  input wire [`XLEN-1:0] if_addr,
  input wire [`XLEN-1:0] if_len,
  output reg if_done,
  output wire [`INST_WID] if_data,
  
  // with ls
  input wire ls_valid,
  input wire ls_we,
  input wire [`VLEN-1:0] ls_src,
  input wire [`XLEN-1:0] ls_addr,
  input wire [`XLEN-1:0] ls_len,
  output reg ls_done,
  output wire [`VLEN-1:0] ls_data,

  // with ram (output of vpu)
  input wire [`RAM_DATA_WID] data_a,
  output reg [`XLEN-1:0] addr_a, 

  input wire [`RAM_DATA_WID] data_b,
  output reg we_b,
  output reg [`RAM_DATA_WID] src_b,
  output reg [`XLEN-1:0] addr_b
);

  reg status_a, status_b;
  localparam IDLE = 1'b0, BUSY = 1'b1;

  reg [`XLEN-1:0] stage_a, stage_b;
  reg [`XLEN-1:0] len_a, len_b;

  reg [`RAM_DATA_WID] if_data_arr[4-1:0];
  genvar _i;
  generate
    for (_i = 0; _i < 4; _i = _i + 1) begin
      assign if_data[_i*8+7:_i*8] = if_data_arr[_i];
    end
  endgenerate

  reg [`RAM_DATA_WID] ls_data_arr[`vlenb:0];
  genvar _j;
  generate
    for (_j = 0; _j < `vlenb; _j = _j + 1) begin
      assign ls_data[_j*8+7:_j*8] = ls_data_arr[_j];
    end
  endgenerate

  always @(posedge clk) begin
    if (rst) begin
      if_done  <= 0;
      ls_done <= 0;
      addr_a    <= 0;
      we_b <= 0;
      addr_b    <= 0;
      src_b <= 0;
      status_a <= 0;
      status_b <= 0;
      stage_a <= 0;
      stage_b <= 0;
      len_a <= 0;
      len_b <= 0;
    end else begin
      case (status_a)
      IDLE: begin
        if_done <= 1'b0;
        if (if_valid) begin
          addr_a <= if_addr;
          len_a <= if_len;
          status_a <= BUSY;
        end
      end
      BUSY: begin
        if (stage_a != 0) if_data_arr[stage_a-1] <= data_a;
        if (stage_a == len_a) begin
          if_done <= 1'b1;
          addr_a <= 0;
          stage_a <= 0;
          status_a <= IDLE;
        end else begin
          stage_a <= stage_a + 1;
          addr_a <= addr_a + 1;
        end
      end
      endcase

      case (status_b)
      IDLE: begin
        ls_done <= 1'b0;
        if (ls_valid) begin
          we_b <= ls_we;
          src_b <= ls_src;
          addr_b <= ls_addr;
          len_b <= ls_len;
          status_b <= BUSY;
        end
      end
      BUSY: begin
        // * 读写都由 we_b(=ls_we)控制了，只需要管地址即可
        if (stage_b != 0) ls_data_arr[stage_b-1] <= data_b; // 如果是写，用不到，也没事
        if (stage_b == len_b) begin
          ls_done <= 1'b1;
          addr_b <= 0;
          src_b <= 0;
          we_b <= 0;
          stage_b <= 0;
          status_b <= IDLE;
        end else begin
          stage_b <= stage_b + 1;
          addr_b <= addr_b + 1;
        end
      end
      endcase
    end
  end

endmodule
