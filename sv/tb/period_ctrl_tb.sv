`timescale 1ns/1ps
module tb_period_ctrl;
  // 10 ns clock
  reg clk = 0;
  always #5 clk = ~clk;

  reg nrst = 0;
  reg increment = 0;
  wire [1:0] period_state;
  wire [3:0] period_leds;

  period_ctrl dut (
    .clk(clk),
    .nrst(nrst),
    .increment(increment),
    .period_state(period_state),
    .period_leds(period_leds)
  );

  initial begin
    nrst = 0;
    // Enable VCD waveform dump for GTKWave / viewers
    $dumpfile("period.vcd");
    $dumpvars(0, tb_period_ctrl);

    #100; nrst = 1;
    $display("%0t: reset released", $time);

    // Pulse increment 6 times to observe wrapping/limit
    repeat (6) begin
      @(posedge clk);
      increment = 1;
      @(posedge clk);
      increment = 0;
      repeat (2) @(posedge clk);
      $display("%0t: period_state=%b period_leds=%b", $time, period_state, period_leds);
    end

    #100; $display("Period control test complete"); $finish;
  end
endmodule
