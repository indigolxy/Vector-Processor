module scoreboard
#(
  parameter ALU_ENTRY_SIZE = 8,
  parameter LS_ENTRY_SIZE = 7,
  parameter SB_SIZE_WIDTH = 4,
  parameter DATA_WIDTH = 32
)
(
  input wire clk,
  input wire rst,
  
  // with i_buffer
  output reg ib_vacant_ALU,
  output reg ib_vacant_LS,
  input wire ib_valid,
  input wire [OPT_WIDTH-1:0] ib_opt,
  input wire [FUNCT_WIDTH-1:0] ib_funct,
  input wire [REG_WIDTH-1:0] ib_rs1,
  input wire [REG_WIDTH-1:0] ib_rs2,
  input wire [REG_WIDTH-1:0] ib_rd,
  input wire [DATA_WIDTH-1:0] ib_imm,

  // with register
  output reg [REG_WIDTH-1:0] reg_rs1,
  output reg [REG_WIDTH-1:0] reg_rs2,

  // with alu and ls(exe)
  output reg exe_valid,
  output reg exe_dest, // 0 for alu, 1 for ls
  output reg [SB_SIZE_WIDTH-1:0] exe_pos,
  output reg [OPT_WIDTH-1:0] exe_opt,
  output reg [FUNCT_WIDTH-1:0] exe_funct,
  output reg [REG_WIDTH-1:0] exe_rd,
  output reg [DATA_WIDTH-1:0] exe_imm,

  // // with alu
  // output reg alu_valid,
  // output wire [OPT_WIDTH-1:0] alu_opt,
  // output wire [FUNCT_WIDTH-1:0] alu_funct,
  // output wire [REG_WIDTH-1:0] alu_rd,
  // output wire [DATA_WIDTH-1:0] alu_imm,
  // output wire [SB_SIZE_WIDTH-1:0] alu_pos,

  // // with ls
  // output reg ls_valid,
  // output wire [OPT_WIDTH-1:0] ls_opt,
  // output wire [FUNCT_WIDTH-1:0] ls_funct,
  // output wire [REG_WIDTH-1:0] ls_rd,
  // output wire [DATA_WIDTH-1:0] ls_imm,
  // output wire [SB_SIZE_WIDTH-1:0] ls_pos,

  // with wb 
  input wire wb_valid,
  input wire [SB_SIZE_WIDTH-1:0] wb_pos,
  input wire [REG_WIDTH-1:0] wb_rd
);

  localparam OPCODE_B = 7'b1100011;
  localparam OPCODE_L = 7'b0000011;
  localparam OPCODE_S = 7'b0100011;
  localparam OPCODE_I = 7'b0010011;
  localparam OPCODE_R = 7'b0110011;

  localparam SB_SIZE = ALU_ENTRY_SIZE+LS_ENTRY_SIZE;
  localparam OPT_WIDTH = 7;
  localparam FUNCT_WIDTH = 3;
  localparam REG_WIDTH = 5;
  localparam REG_SIZE = 2**REG_WIDTH;
  localparam [SB_SIZE_WIDTH-1:0] INVALID_POS = {(SB_SIZE_WIDTH){1'b1}};
  localparam [SB_SIZE_WIDTH-1:0] LS_ST_POS = ALU_ENTRY_SIZE;
  localparam [SB_SIZE_WIDTH-1:0] LS_ED_POS = SB_SIZE-1;

  // reg_file
  reg [SB_SIZE_WIDTH-1:0] last_read_pos [0:REG_SIZE-1];
  reg [SB_SIZE_WIDTH-1:0] last_write_pos [0:REG_SIZE-1];

  reg alu_busy, ls_busy;

  reg valid [0:SB_SIZE-1];
  reg exe [0:SB_SIZE-1];
  reg [OPT_WIDTH-1:0] opt [0:SB_SIZE-1];
  reg [FUNCT_WIDTH-1:0] funct [0:SB_SIZE-1];
  reg [DATA_WIDTH-1:0] imm [0:SB_SIZE-1];

  reg [REG_WIDTH-1:0] rs1 [0:SB_SIZE-1];
  reg [SB_SIZE_WIDTH-1:0] dep1 [0:SB_SIZE-1];

  reg [REG_WIDTH-1:0] rs2 [0:SB_SIZE-1];
  reg [SB_SIZE_WIDTH-1:0] dep2 [0:SB_SIZE-1];

  reg [REG_WIDTH-1:0] rd [0:SB_SIZE-1];
  reg [SB_SIZE_WIDTH-1:0] dep_war [0:SB_SIZE-1];
  reg [SB_SIZE_WIDTH-1:0] dep_waw [0:SB_SIZE-1];

  reg [SB_SIZE_WIDTH-1:0] ls_rear;
  reg [SB_SIZE_WIDTH-1:0] ls_front;

  // ! 阻塞赋值，当个周期即时修改(还有exe_pos)
  integer ei; // may be xxx
  integer wi; // may be xxx
  reg [SB_SIZE_WIDTH-1:0] issue_pos; 
  reg [SB_SIZE_WIDTH-1:0] alu_ready_pos;
  reg ls_ready;
  reg [SB_SIZE_WIDTH-1:0] alu_vacant_pos;

  integer i, j;
  always @(posedge clk) begin
    if (rst) begin
      ib_vacant_ALU <= 1;
      ib_vacant_LS <= 1;
      exe_dest <= 0;
      exe_valid <= 0;
      for (i = 0; i < REG_SIZE; i = i + 1) begin
        last_read_pos[i] <= INVALID_POS;
        last_write_pos[i] <= INVALID_POS;
      end
      alu_busy <= 0;
      ls_busy <= 0;
      for (j = 0; j < SB_SIZE; j = j + 1) begin
        valid[j] <= 0;
        exe[j] <= 0;
        opt[j] <= 0;
        funct[j] <= 0;
        imm[j] <= 0;
        rs1[j] <= 0;
        dep1[j] <= INVALID_POS;
        rs2[j] <= 0;
        dep2[j] <= INVALID_POS;
        rd[j] <= 0;
        dep_war[j] <= INVALID_POS;
        dep_waw[j] <= INVALID_POS;
      end
      exe_pos <= INVALID_POS;
      alu_ready_pos <= ALU_ENTRY_SIZE;
      alu_vacant_pos <= 0;
      ls_rear <= LS_ST_POS;
      ls_front <= LS_ST_POS;
    end else begin
      // handle issue
      if (ib_valid) begin
        if (ib_opt == OPCODE_B || ib_opt == OPCODE_I || ib_opt == OPCODE_R) begin
          issue_pos = alu_vacant_pos;
        end else if (ib_opt == OPCODE_L || ib_opt == OPCODE_S) begin
          issue_pos = ls_rear;
          if (ls_rear == LS_ED_POS) begin
            ls_rear <= LS_ST_POS;
          end else begin
            ls_rear <= ls_rear + 1;
          end
        end else begin
          // ~ invalid instruction
        end

        valid[issue_pos] <= 1;
        opt[issue_pos] <= ib_opt;
        funct[issue_pos] <= ib_funct;
        imm[issue_pos] <= ib_imm;
        rs1[issue_pos] <= ib_rs1;
        rs2[issue_pos] <= ib_rs2;
        rd[issue_pos] <= ib_rd;
        // dependencies
        if (ib_rs1 == 0) begin
          dep1[issue_pos] <= INVALID_POS;
        end else begin
          dep1[issue_pos] <= last_write_pos[ib_rs1];
          last_read_pos[ib_rs1] <= issue_pos;
        end
        if (ib_rs2 == 0) begin
          dep2[issue_pos] <= INVALID_POS;
        end else begin
          dep2[issue_pos] <= last_write_pos[ib_rs2];
          last_read_pos[ib_rs2] <= issue_pos;
        end
        if (ib_rd == 0) begin
          dep_war[issue_pos] <= INVALID_POS;
          dep_waw[issue_pos] <= INVALID_POS;
        end else begin
          dep_war[issue_pos] <= last_read_pos[ib_rd];
          dep_waw[issue_pos] <= last_write_pos[ib_rd];
          last_write_pos[ib_rd] <= issue_pos;
        end

`ifdef DEBUG
        $fdisplay(logfile, "\n--------------!!SB issue!! at #%X--------------\n", issue_pos);
`endif
      end

      // handle exe
      if (alu_busy == 0 && alu_ready_pos != ALU_ENTRY_SIZE) begin
        exe_pos = alu_ready_pos;
        alu_busy <= 1;
        exe_dest <= 0;
      end else if (ls_busy == 0 && ls_ready) begin
        exe_pos = ls_front;
        ls_busy <= 1;
        exe_dest <= 1;
      end else begin
        exe_pos = INVALID_POS; // ! 数组访问越界会不会出错？ // 如果要改，后面if也要改
        exe_valid <= 0;
      end

      if (exe_pos != INVALID_POS) begin
        exe_valid <= 1;
        exe[exe_pos] <= 1;

        reg_rs1 <= rs1[exe_pos];
        reg_rs2 <= rs2[exe_pos];
        exe_opt <= opt[exe_pos];
        exe_funct <= funct[exe_pos];
        exe_rd <= rd[exe_pos];
        exe_imm <= imm[exe_pos];

        for (ei = 0; ei < SB_SIZE; ei = ei + 1)
          if (valid[ei] && dep_war[ei] == exe_pos)
            dep_war[ei] <= INVALID_POS;
        
        if (last_read_pos[rs1[exe_pos]] == exe_pos && (ib_valid == 0 || (ib_rs1 != rs1[exe_pos] && ib_rs2 != rs1[exe_pos])))
          last_read_pos[rs1[exe_pos]] <= INVALID_POS;

        if (last_read_pos[rs2[exe_pos]] == exe_pos && (ib_valid == 0 || (ib_rs1 != rs2[exe_pos] && ib_rs2 != rs2[exe_pos])))
          last_read_pos[rs2[exe_pos]] <= INVALID_POS;

`ifdef DEBUG
        $fdisplay(logfile, "\n--------------!!SB exe!! at #%X--------------\n", exe_pos);
`endif
      end

      // handle write back
      if (wb_valid) begin
        valid[wb_pos] <= 0;
        if (wb_pos < ALU_ENTRY_SIZE) begin
          alu_busy <= 0;
        end else begin
          ls_busy <= 0;
          if (ls_front == LS_ED_POS) begin
            ls_front <= LS_ST_POS;
          end else begin
            ls_front <= ls_front + 1;
          end
        end

        if (last_write_pos[wb_rd] == wb_pos && (ib_valid == 0 || ib_rd != wb_rd)) begin
          last_write_pos[wb_rd] <= INVALID_POS;
        end

        for (wi = 0; wi < SB_SIZE; wi = wi + 1) begin
          if (valid[wi] && dep1[wi] == wb_pos) 
            dep1[wi] <= INVALID_POS;
          if (valid[wi] && dep2[wi] == wb_pos) 
            dep2[wi] <= INVALID_POS;
          if (valid[wi] && dep_waw[wi] == wb_pos)
            dep_waw[wi] <= INVALID_POS;
        end

`ifdef DEBUG
        $fdisplay(logfile, "\n--------------!!SB wb!! at #%X--------------\n", wb_pos);
`endif
      end
    end
  end

  // * maintain vacant（当个周期即时修改，阻塞赋值）
  integer vi; // may be xxx
  reg v_flag; // may be xxx
  always @* begin
    // ib_vacant_LS，只在这里被赋值！
    if (ls_front == ls_rear + 1 || (ls_rear == LS_ED_POS && ls_front == LS_ST_POS)) begin
      ib_vacant_LS = 0; 
    end else begin
      ib_vacant_LS = 1;
    end

    // ib_vacant_ALU & alu_vacant_pos，只在这里被赋值
    v_flag = 0;
    for (vi = 0; vi < ALU_ENTRY_SIZE; vi = vi + 1) begin
      if (valid[vi] == 0 && v_flag == 0) begin
        v_flag = 1;
        alu_vacant_pos = vi;
      end
    end
    ib_vacant_ALU = v_flag;
    if (v_flag == 0) begin
      alu_vacant_pos = INVALID_POS;
    end
  end

  // * maintain ready（当个周期即时修改，阻塞赋值）
  integer ri; // may be xxx
  reg r_flag; // may be xxx
  always @* begin
    // ls_ready，只在这里被赋值！
    if (ls_front != ls_rear && exe[ls_front] == 0 && dep1[ls_front] == INVALID_POS && dep2[ls_front] == INVALID_POS && dep_war[ls_front] == INVALID_POS && dep_waw[ls_front] == INVALID_POS) begin
      ls_ready = 1;
    end else begin
      ls_ready = 0;
    end

    // alu_ready_pos, 只在这里被赋值！
    r_flag = 0;
    for (ri = 0; ri < ALU_ENTRY_SIZE; ri = ri + 1) begin
      if (r_flag == 0 && valid[ri] && exe[ri] == 0 && dep1[ri] == INVALID_POS && dep2[ri] == INVALID_POS && dep_war[ri] == INVALID_POS && dep_waw[ri] == INVALID_POS) begin
        alu_ready_pos = ri;
        r_flag = 1;
      end
    end
    if (r_flag == 0) begin
      alu_ready_pos = ALU_ENTRY_SIZE;
    end
  end

`ifdef DEBUG
integer di;
  always @(posedge clk) begin
    if (rst == 0) begin
      $fdisplay(logfile, "SB alu_busy = %X, ls_busy = %X", alu_busy, ls_busy);
      $fdisplay(logfile, "SB ls_front = %X, ls_rear = %X", ls_front, ls_rear);

      // $fdisplay(logfile, "SB vacant_LS = %X, vacant_ALU_pos = %X", ib_vacant_LS, alu_vacant_pos);

      $fdisplay(logfile, "----------------SB entry----------------");
      $fdisplay(logfile, " pos|valid|exe|rs1|dep1|rs2|dep2| rd |war|waw");
      for (di = 0; di < SB_SIZE; di = di + 1) begin
        if (valid[di]) begin
          $fdisplay(logfile, "#%3d|  %b  | %b |%3d| %2d |%3d| %2d | %2d |%3d|%3d", di, valid[di], exe[di], rs1[di], dep1[di], rs2[di], dep2[di], rd[di], dep_war[di], dep_waw[di]);
        end
      end
      $fdisplay(logfile, "-----------------------------------------");

      $fdisplay(logfile, "----------------REGFILE----------------");
      for (di = 0; di < REG_SIZE; di = di + 1) begin
        if (last_read_pos[di] != INVALID_POS || last_write_pos[di] != INVALID_POS) begin
          $fdisplay(logfile, "r%3d: last_read #%2d, last_write #%2d", di, last_read_pos[di], last_write_pos[di]);
        end
      end
      $fdisplay(logfile, "-----------------------------------------");
    end
  end
`endif  

`ifdef DEBUG
  integer logfile;
  initial begin
    logfile = $fopen("sb.log", "w");
    $fdisplay(logfile, "SB LS_ST_POS = %X, LS_ED_POS = %X, INVALID_POS = %X", LS_ST_POS, LS_ED_POS, INVALID_POS);
  end
`endif

endmodule
