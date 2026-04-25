`timescale 1ns / 1ps

module clock_driver_tb();

    // 1. Interface Signals
    logic [15:0] tb_raw_deciseconds;
    logic [6:0]  tb_seg3, tb_seg2, tb_seg1, tb_seg0;
    logic        tb_colon;
    logic [3:0]  tb_dp;

    // 2. Instantiate the Device Under Test (DUT)
    shot_clock_driver dut (
        .raw_deciseconds(tb_raw_deciseconds),
        .seg3(tb_seg3),
        .seg2(tb_seg2),
        .seg1(tb_seg1),
        .seg0(tb_seg0),
        .colon(tb_colon),
        .dp(tb_dp)
    );

    // 3. Stimulus Block
    initial begin
        // Display header for console output
        $display("Time (ds) | Mode  | D3 D2 : D1 D0 | Colon | DP   ");
        $display("-----------------------------------------------------");

        // Case 1: 0 deciseconds (Starting point)
        tb_raw_deciseconds = 0;
        #10; display_results("00.0");

        // Case 2: 140 deciseconds (Your 14.0s example)
        tb_raw_deciseconds = 140;
        #10; display_results("14.0");

        // Case 3: 599 deciseconds (Just before 1 minute transition)
        tb_raw_deciseconds = 599;
        #10; display_results("59.9");

        // Case 4: 600 deciseconds (Exactly 1 minute - Transition!)
        tb_raw_deciseconds = 600;
        #10; display_results("01:00");

        // Case 5: 750 deciseconds (1 minute, 15 seconds)
        tb_raw_deciseconds = 750;
        #10; display_results("01:15");

        // Case 6: 1400 deciseconds (14.00s -> 2 minutes 20.0s)
        tb_raw_deciseconds = 1400;
        #10; display_results("02:20.0");

        $finish;
    end

    // Helper task to print values nicely in the simulator console
    task display_results(string expected);
        $display("%9d | %5s |  %h  %h :  %h  %h |   %b   | %b", 
                 tb_raw_deciseconds, expected, 
                 tb_seg3, tb_seg2, tb_seg1, tb_seg0, 
                 tb_colon, tb_dp);
        // Print full 7-bit patterns for each digit (bit order: g f e d c b a)
        $display("Segments (gfedcba): D3=%b  D2=%b  D1=%b  D0=%b",
                 {tb_seg3[6],tb_seg3[5],tb_seg3[4],tb_seg3[3],tb_seg3[2],tb_seg3[1],tb_seg3[0]},
                 {tb_seg2[6],tb_seg2[5],tb_seg2[4],tb_seg2[3],tb_seg2[2],tb_seg2[1],tb_seg2[0]},
                 {tb_seg1[6],tb_seg1[5],tb_seg1[4],tb_seg1[3],tb_seg1[2],tb_seg1[1],tb_seg1[0]},
                 {tb_seg0[6],tb_seg0[5],tb_seg0[4],tb_seg0[3],tb_seg0[2],tb_seg0[1],tb_seg0[0]});
    endtask

endmodule