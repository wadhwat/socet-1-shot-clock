/*
Basketball Shot Clock Top Module

MISSING shot clock driver, shot clock
*/

module top #(
    parameter logic [6:0] BUZZER_LENGTH = 7'd20 //2 seconds long
)(
    input  logic clk,                // 100 MHz onboard oscillator
    input  logic rst_in,           // active-high reset input
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
);

    logic n_rst;

    assign n_rst = ~rst_in;

    logic tick_10Hz, tick_1kHz, tick_2640Hz;
    logic btn_start_stop, btn_possession, btn_score_up, btn_score_down, btn_shot_reset;
    logic [1:0] pos_led_wire;
    logic [3:0] period_led_wire;
    logic [7:0] gc_ss1, gc_ss2, gc_ss3, gc_ss4;
    logic [7:0] sc_ss1, sc_ss2, sc_ss3, sc_ss4;
    logic [7:0] scr_ss1, scr_ss2, scr_ss3, scr_ss4; 
    logic possession_state_wire;
    logic [1:0] period_state_wire;
    logic [7:0] home_score_wire, away_score_wire;
    logic buzzer_drive_wire;
    logic game_clock_expired_wire;
    logic buzzer_trigger_wire;
    logic period_increment_wire;
    logic possession_increment_wire;
    logic shot_clock_en_wire;
    logic shot_clock_load_wire;
    logic [9:0] shot_clock_load_value_wire;
    logic game_clock_en_wire;
    logic game_clock_load_wire;
    logic [13:0] game_clock_load_value_wire;
    logic [13:0] game_clock_time_wire;
    logic game_clock_below_10_wire;
    logic final_flash_active_wire;
    logic final_flash_show_9999_wire;

    assign display_enable = 1'b1;

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

    clock_driver cd1 (
        .raw_deciseconds(), //COMPLETE from clock module in tenths of seconds
        
        .seg3(gc_ss3), .seg2(gc_ss2), .seg1(gc_ss1), .seg0(gc_ss0), //COMPLETE to main driver
        .colon(), //COMPLETE to main driver
        .dp() //COMPLETE to main driver
    );

    //IDK how ts works
    clock #(
        .PERIOD_MINUTES(15),
        .SECONDS_PER_MINUTE(60),
        .TENTHS_PER_SECOND(10),
        .TIMER_WIDTH(14)
    ) gc1 (
        .clk(clk),
        .nrst(n_rst),
        .tick_10hz(tick_10Hz),
        .enable(game_clock_en_wire),
        .game_clock_load(game_clock_load_wire),
        .game_clock_load_value(game_clock_load_value_wire),
        
        .current_time_value(game_clock_time_wire), // TODO: once we have the GC driver, connect this to the time input
        .expired(game_clock_expired_wire),
        .below_10(game_clock_below_10_wire)
    );

    buzzer_driver #(
        .FREQUENCY(2000), // 2 kHz tone
        .CLK_FREQ(100_000_000) // 100 MHz clock
    ) bd1 (
        .clk(clk),
        .n_rst(n_rst),
        .buzzer_pulse(buzzer_trigger_wire),
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
        .possession_toggle_pulse(possession_increment_wire),
        .possession_state(possession_state_wire), 
        .possession_leds(pos_led_wire)
    );

    period_ctrl pc2 (
        .clk(clk),
        .n_rst(n_rst),
        .increment(period_increment_wire),
        .period_state(period_state_wire),
        .period_leds(period_led_wire)
    );

    control_fsm #(
        .N_BUTTONS(5),
        .TIMER_WIDTH(14),
        .SHOT_TIMER_WIDTH(10),
        .FULL_PERIOD_MINUTES(15)
    ) cfsm1 (
        .clk(clk),
        .n_rst(n_rst),
        .period_state(period_state_wire),
        .shot_clock_expired(1'b0),
        .game_clock_expired(game_clock_expired_wire),
        .tick_10hz(tick_10Hz),
        .conditioned_buttons({btn_shot_reset, btn_score_down, btn_score_up, btn_possession, btn_start_stop}),
        .buzzer_trigger(buzzer_trigger_wire),
        .period_increment(period_increment_wire),
        .possession_increment(possession_increment_wire),
        .shot_clock_en(shot_clock_en_wire),
        .shot_clock_load(shot_clock_load_wire),
        .shot_clock_load_value(shot_clock_load_value_wire),
        .game_clock_en(game_clock_en_wire),
        .game_clock_load(game_clock_load_wire),
        .game_clock_load_value(game_clock_load_value_wire),
        .final_flash_active(final_flash_active_wire),
        .final_flash_show_9999(final_flash_show_9999_wire)
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

    button_conditioner #(
        .N_BUTTONS(5),
        .STREAK_REQUIRED(6)
    ) bc1 (
        .clk(clk),
        .n_rst(n_rst),
        .tick_1kHz(tick_1kHz),
        .raw_buttons({ btn_shot_reset_raw, btn_score_down_raw, btn_score_up_raw, btn_possession_raw, btn_start_stop_raw}),
        .conditioned_buttons( {btn_shot_reset, btn_score_down, btn_score_up, btn_possession, btn_start_stop} )
    );


endmodule
