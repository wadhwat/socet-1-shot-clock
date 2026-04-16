module main_driver (
    input logic clk,
    output [7:0] main_segments_pin_out,
    output [3:0] decoder_pin //controls the decoder to select correct ss
);
    logic [6:0] ss1, ss2, ss3;
    logic colon1, colon2, colon3;


    game_clock_driver g1 ();
    score_driver s1 ();
    shotclock_driver sh1 ();


endmodule