/*
Basketball Shot Clock Top Module

MISSING shot clock driver, shot clock
*/

module top #(
    parameter logic [6:0] BUZZER_LENGTH = 7'd20 //2 seconds long
)(
    input  logic clk,                // 100 MHz onboard oscillator
    input  logic n_rst,              // active-low reset
    // n_rst is equivalent to btn_reset (pb[5])

    input  logic btn_start_stop_raw,     // pb[0]
    input  logic btn_possession_raw,     // pb[1]
    input  logic btn_score_up_raw,       // pb[2]
    input  logic btn_score_down_raw,     // pb[3]
    input  logic btn_shot_reset_raw,     // pb[4]

    //Non SS Outputs
    output logic [3:0] period_leds,
    output logic [1:0] possession_leds,
    output logic buzzer_drive,

    //SS Outputs
    output logic [3:0] display_select,
    output logic [7:0] display_segments,
    output logic display_enable
);

    logic tick_10Hz, tick_1kHz, tick_2640Hz;
    logic btn_start_stop, btn_possession, btn_score_up, btn_score_down, btn_shot_reset;
    logic [1:0] pos_led_wire;
    logic [3:0] period_led_wire;
    logic [7:0] scr_ss1, scr_ss2, scr_ss3, scr_ss4; 
    logic possession_state_wire;
    logic [7:0] home_score_wire, away_score_wire;
    logic buzzer_drive_wire;
    logic expired_wire;

    main_driver m1 (
        .clk(clk),
        .tick_2640Hz(tick_2640Hz),
        .n_rst(n_rst),
        .period_led(period_led_wire),
        .pos_led(pos_led_wire),
        .gc_ss1(gc_ss1), .gc_ss2(gc_ss2), .gc_ss3(gc_ss3), .gc_ss4(gc_ss4), //COMPLETE
        .scr_ss1(scr_ss1), .scr_ss2(scr_ss2), .scr_ss3(scr_ss3), .scr_ss4(scr_ss4),
        .scr_colon(1'b0), 
        .sc_ss1(sc_ss1), .sc_ss2(sc_ss2), .sc_ss3(sc_ss3), .sc_ss4(sc_ss4),
        .sc_colon(1'b0),
        .buzzer_in(buzzer_drive_wire),

        //ERROR: WIDTH MISMATCH, NEED GC DRIVER TO RESOLVE
        .main_segments_pin_out(display_segments),
        .decoder_pin(display_select),
        //.gc_colon(), //always set 
        .sc_colon_out(), 
        //.scr_colon_out(),   //do we have a PCB trace for this?
        .period_led_out(period_leds), 
        .pos_led_out(possession_leds),
        .buzzer_out(buzzer_drive)
    );

    //IDK how ts works
    game_clock #(
        .PERIOD_MINUTES(12),
        .SECONDS_PER_MINUTE(60),
        .TENTHS_PER_SECOND(10),
        .TIMER_WIDTH(14)
    ) gc1 (
        .clk(clk),
        .nrst(n_rst),
        .tick_10hz(tick_10Hz),
        .enable(), // COMPLETE from control FSM
        .game_clock_load(), // COMPLETE from control FSM
        .game_clock_load_value(), // COMPLETE from control FSM (probably just full time in tenths)
        
        .current_time_value(), // COMPLETE to needed modules
        .expired(expired_wire), //goes to buzzer driver
        .below_10() // COMPLETE should go to 
    );

    buzzer_driver #(
        .FREQUENCY(2000), // 2 kHz tone
        .CLK_FREQ(100_000_000) // 100 MHz clock
    ) bd1 (
        .clk(clk),
        .nrst(n_rst),
        .buzzer_pulse(expired_wire), //wire from game_clock.sv
        .buzzer_length(BUZZER_LENGTH), //Parameter set at top of top.sv
        .buzzer_out(buzzer_drive_wire)
    );

    score_driver sd1 (
        .home_score(home_score_wire), 
        .away_score(away_score_wire), 
        .scr_ss1(scr_ss1),
        .scr_ss2(scr_ss2),
        .scr_ss3(scr_ss3),
        .scr_ss4(scr_ss4)
    );

    score_tracker st1 (
        .clk(clk),
        .nrst(n_rst),
        .plus_one_possession_pulse(btn_score_up),
        .minus_one_possession_pulse(btn_score_down),
        .possession_state(possession_state_wire), // Assuming home 0
        .home_score(home_score_wire), 
        .away_score(away_score_wire) 
    );

    possession_ctrl pc1 (  //Is a driver as well already technically so...
        .clk(clk),
        .n_rst(n_rst),
        .possession_toggle_pulse(btn_possession),
        .possession_state(possession_state_wire), 
        .possession_leds(pos_led_wire)
    );

    period_ctrl pc2 (
        .clk(clk),
        .n_rst(n_rst),
        .increment(), //from control fsm i think
        .period_state(), //complete output to needed module
        .period_leds(period_led_wire)
    );

    tick_generator #(
        .CLK_FREQ_HZ(100_000_000), // 100 MHz clock
        .TICK_FREQ_HZ(10),         // 10 Hz tick for period changes
        .TICK_2640_HZ(2640),      // 2,640 Hz tick for shot clock
        .CONDITIONED(1_000)       // 1,000 Hz tick for score updates and shot clock
    ) tg (
        .clk(clk),
        .rst_n(n_rst),
        .tick_10Hz(tick_10Hz),
        .tick_1kHz(tick_1kHz),
        .tick_2640Hz(tick_2640Hz)
    );

    button_conditioner bc1 #(
        .N_BUTTONS(5),
        .STREAK_REQUIRED(6)
    )(
        .clk(clk),
        .n_rst(n_rst),
        .tick_1kHz(tick_1kHz),
        .raw_buttons({ btn_shot_reset_raw, btn_score_down_raw, btn_score_up_raw, btn_possession_raw, btn_start_stop_raw}),
        .conditioned_buttons( {btn_shot_reset, btn_score_down, btn_score_up, btn_possession, btn_start_stop} )
    );


endmodule