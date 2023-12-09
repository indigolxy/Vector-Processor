// testbench top module file
// for simulation only

`timescale 1ns/1ps
module testbench;

reg clk;
reg rst;

riscv_top top(
    .EXCLK(clk),
    .btnC(rst)
);

initial begin
  clk=0;
  rst=1;
  repeat(25) #1 clk=!clk;
  rst=0; 
  forever #1 clk=!clk;

  $finish;
end

initial begin
     $dumpfile("test.vcd");
     $dumpvars(0, testbench);
     #300000000 $finish;
end

endmodule
