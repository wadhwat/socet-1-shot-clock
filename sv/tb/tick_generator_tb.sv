`timescale 1ns/1ps
module tb_tick_generator;
  localparam int CLK_FREQ_HZ = 100_000_000;
  localparam int TICK_FREQ_HZ = 1;
  localparam int CONDITIONED  = 1_000;

  reg clk = 0;
  reg rst_n = 0;
  wire tick;
  wire conditioned_tick;

  // 100 MHz clock => 10 ns period
  always #5 clk = ~clk;

  tick_generator #(
    .CLK_FREQ_HZ(CLK_FREQ_HZ),
    .TICK_FREQ_HZ(TICK_FREQ_HZ),
    .CONDITIONED(CONDITIONED)
  ) dut (
    .clk(clk),
    .rst_n(rst_n),
    .tick(tick),
    .conditioned_tick(conditioned_tick)
  );

  initial begin
    rst_n = 0;
    #100;           // hold reset for 100 ns
    rst_n = 1;
    #2_000_000;     // run for 2 ms to see several conditioned pulses
    $finish;
  end
endmodule