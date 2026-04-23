module top (
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
    output logic [7:0] display_segments,
    output logic display_enable
);

    main_driver m1 (
        .clk(clk),
        .tick_2640Hz(tick_2640Hz),
        .n_rst(n_rst),
        .quad_led(period_leds),
        .pos_led(possession_leds),
        .gc_ss1(gc_ss1), .gc_ss2(gc_ss2), .gc_ss3(gc_ss3), .gc_ss4(gc_ss4),
        .scr_ss1(scr_ss1), .scr_ss2(scr_ss2), .scr_ss3(scr_ss3), .scr_ss4(scr_ss4),
        .scr_colon(scr_colon),
        .sc_ss1(sc_ss1), .sc_ss2(sc_ss2), .sc_ss3(sc_ss3), .sc_ss4(sc_ss4),
        .sc_colon(sc_colon),
        .buzzer_in(buzzer_drive),

        .main_segments_pin_out(display_segments),
        .decoder_pin(display_select),
        .gc_colon(),
        .sc_colon_out(), 
        .scr_colon_out(), 
        .quad_led_out(), 
        .pos_led_out()
    );

    tick_generator #(
        .CLK_FREQ_HZ(100_000_000), // 100 MHz clock
        .TICK_FREQ_HZ(10),         // 10 Hz tick for period changes
        .TICK_12_HZ(12),          // 12 Hz tick for possession changes
        .CONDITIONED(1_000)       // 1,000 Hz tick for score updates and shot clock
    ) tg (
        .clk(clk),
        .rst_n(n_rst),
        .tick_10Hz(tick_10Hz),
        .tick_1kHz(tick_1kHz),
        .tick_12Hz(tick_12Hz)
    );

endmodule