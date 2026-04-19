module top_module #(
    parameter integer N_BUTTONS = 6,
)(
    input  logic clk,                // 100 MHz onboard oscillator
    input  logic n_rst,              // active-low reset

    input  logic possession_state,
    input  logic period_state,   
    input  logic shot_clock_expired,
    input  logic game_clock_expired,

    input  logic [N_BUTTONS-1:0] conditioned_buttons,

    output logic        buzzer_trigger,
    output logic        period_increment,

    output logic        shot_clock_en,
    output logic        shot_clock_load,
    output logic        shot_clock_load_value,
    
    output logic        game_clock_en,
    output logic        game_clock_load,
    output logic        game_clock_load_value,
);



endmodule