module top_module (
    input  logic        clk,                // 100 MHz onboard oscillator
    input  logic        n_rst,              // active-low reset

    input  logic        btn_start_stop,     // pb[0]
    input  logic        btn_possession,     // pb[1]
    input  logic        btn_score_up,       // pb[2]
    input  logic        btn_score_down,     // pb[3]
    input  logic        btn_shot_reset,     // pb[4]
    input  logic        btn_show_hide,      // pb[5]   // only keep if still used
    input  logic        btn_reset_raw,      // pb[6]   // only if distinct from n_rst

    output logic [3:0]  period_leds,
    output logic [1:0]  possession_leds,
    output logic        buzzer_drive,

    output logic [3:0]  display_select,
    output logic [6:0]  display_segments,
    output logic        display_enable
);


endmodule