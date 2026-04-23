module top_module (
    input  logic clk,                // 100 MHz onboard oscillator
    input  logic n_rst,              // active-low reset
    // n_rst is equivalent to btn_reset (pb[5])

    input  logic btn_start_stop,     // pb[0]
    input  logic btn_possession,     // pb[1]
    input  logic btn_score_up,       // pb[2]
    input  logic btn_score_down,     // pb[3]
    input  logic btn_shot_reset,     // pb[4]

    output logic [3:0] period_leds,
    output logic [1:0] possession_leds,
    output logic buzzer_drive,

    output logic [3:0] display_select,
    output logic [6:0] display_segments,
    output logic display_enable
);


endmodule