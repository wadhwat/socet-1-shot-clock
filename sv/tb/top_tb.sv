`timescale 1ns/1ps

module top_tb;

    initial begin
        $dumpfile("top_tb.vcd");
        $dumpvars(0, top_tb);
    end

    localparam int TIMER_WIDTH = 16;

    localparam int BTN_START_STOP = 0;
    localparam int BTN_POSSESSION = 1;
    localparam int BTN_SCORE_UP   = 2;
    localparam int BTN_SCORE_DOWN = 3;
    localparam int BTN_SHOT_RESET = 4;

    localparam logic [TIMER_WIDTH-1:0] FULL_PERIOD_TENTHS = TIMER_WIDTH'(15 * 60 * 10);
    localparam logic [TIMER_WIDTH-1:0] INTERMISSION_TENTHS = TIMER_WIDTH'(75 * 10);
    localparam logic [TIMER_WIDTH-1:0] HALFTIME_TENTHS = TIMER_WIDTH'(15 * 60 * 10);
    localparam logic [TIMER_WIDTH-1:0] SHOT_CLOCK_TENTHS = TIMER_WIDTH'(30 * 10);

    logic clk;
    logic rst_in;
    logic btn_start_stop_raw;
    logic btn_possession_raw;
    logic btn_score_up_raw;
    logic btn_score_down_raw;
    logic btn_shot_reset_raw;

    logic [3:0] period_leds;
    logic [1:0] possession_leds;
    logic buzzer_drive;
    logic [3:0] display_select;
    logic [7:0] display_segments;
    logic gc_colon_out;
    logic sc_colon_out;
    logic scr_colon_out;

    int err_count;

    top #(
        .BUZZER_LENGTH(7'd1),
        .TIMER_WIDTH(TIMER_WIDTH)
    ) dut (
        .clk(clk),
        .rst_in(rst_in),
        .btn_start_stop_raw(btn_start_stop_raw),
        .btn_possession_raw(btn_possession_raw),
        .btn_score_up_raw(btn_score_up_raw),
        .btn_score_down_raw(btn_score_down_raw),
        .btn_shot_reset_raw(btn_shot_reset_raw),
        .period_leds(period_leds),
        .possession_leds(possession_leds),
        .buzzer_drive(buzzer_drive),
        .display_select(display_select),
        .display_segments(display_segments),
        .gc_colon_out(gc_colon_out),
        .sc_colon_out(sc_colon_out),
        .scr_colon_out(scr_colon_out)
    );

    always #5 clk = ~clk;

    task automatic check_bit(input string what, input logic got, input logic exp);
        if (got !== exp) begin
            $error("FAIL %s: got %b expected %b @ %0t", what, got, exp, $time);
            err_count++;
        end
    endtask

    task automatic check_vec2(input string what, input logic [1:0] got, input logic [1:0] exp);
        if (got !== exp) begin
            $error("FAIL %s: got %b expected %b @ %0t", what, got, exp, $time);
            err_count++;
        end
    endtask

    task automatic check_vec4(input string what, input logic [3:0] got, input logic [3:0] exp);
        if (got !== exp) begin
            $error("FAIL %s: got %b expected %b @ %0t", what, got, exp, $time);
            err_count++;
        end
    endtask

    task automatic check_time(
        input string what,
        input logic [TIMER_WIDTH-1:0] got,
        input logic [TIMER_WIDTH-1:0] exp
    );
        if (got !== exp) begin
            $error("FAIL %s: got %0d expected %0d @ %0t", what, got, exp, $time);
            err_count++;
        end
    endtask

    task automatic check_byte(input string what, input logic [7:0] got, input logic [7:0] exp);
        if (got !== exp) begin
            $error("FAIL %s: got %b expected %b @ %0t", what, got, exp, $time);
            err_count++;
        end
    endtask

    task automatic set_raw_button(input int button_index, input logic value);
        case (button_index)
            BTN_START_STOP: btn_start_stop_raw = value;
            BTN_POSSESSION: btn_possession_raw = value;
            BTN_SCORE_UP:   btn_score_up_raw   = value;
            BTN_SCORE_DOWN: btn_score_down_raw = value;
            BTN_SHOT_RESET: btn_shot_reset_raw = value;
            default: begin end
        endcase
    endtask

    task automatic pulse_forced_1khz();
        @(negedge clk);
        force dut.tick_1kHz = 1'b1;
        @(posedge clk);
        #1;
        release dut.tick_1kHz;
        @(negedge clk);
        #1;
    endtask

    task automatic pulse_forced_2640hz();
        @(negedge clk);
        force dut.tick_2640Hz = 1'b1;
        @(posedge clk);
        #1;
        release dut.tick_2640Hz;
        @(negedge clk);
        #1;
    endtask

    task automatic condition_button(input int button_index);
        set_raw_button(button_index, 1'b1);
        repeat (6) pulse_forced_1khz();
        #1;
    endtask

    task automatic finish_button(input int button_index);
        @(posedge clk);
        #1;
        set_raw_button(button_index, 1'b0);
        pulse_forced_1khz();
        @(posedge clk);
        #1;
    endtask

    task automatic press_button(input int button_index);
        condition_button(button_index);
        finish_button(button_index);
    endtask

    task automatic apply_reset();
        rst_in = 1'b1;
        btn_start_stop_raw = 1'b0;
        btn_possession_raw = 1'b0;
        btn_score_up_raw = 1'b0;
        btn_score_down_raw = 1'b0;
        btn_shot_reset_raw = 1'b0;

        repeat (5) @(posedge clk);
        rst_in = 1'b0;
        repeat (2) @(posedge clk);
        #1;
    endtask

    task automatic check_expire_game_clock(
        input string what,
        input logic [3:0] exp_period_leds,
        input logic exp_period_increment,
        input logic exp_game_clock_load,
        input logic [TIMER_WIDTH-1:0] exp_load_value
    );
        force dut.game_clock_expired_wire = 1'b1;
        #1;
        check_bit({what, " buzzer trigger"}, dut.buzzer_trigger_wire, 1'b1);
        check_bit({what, " period increment"}, dut.period_increment_wire, exp_period_increment);
        check_bit({what, " game load"}, dut.game_clock_load_wire, exp_game_clock_load);
        check_time({what, " load value"}, dut.game_clock_load_value_wire, exp_load_value);

        @(posedge clk);
        #1;
        release dut.game_clock_expired_wire;
        @(posedge clk);
        #1;
        check_vec4({what, " period LEDs"}, period_leds, exp_period_leds);
    endtask

    initial begin
        clk = 1'b0;
        err_count = 0;

        apply_reset();
        check_vec4("reset period LEDs", period_leds, 4'b0001);
        check_vec2("reset possession LEDs", possession_leds, 2'b01);
        check_bit("reset game clock disabled", dut.game_clock_en_wire, 1'b0);
        check_bit("reset shot clock disabled", dut.shot_clock_en_wire, 1'b0);
        check_time("reset game clock time", dut.game_clock_time_wire, FULL_PERIOD_TENTHS);
        check_time("reset home score", TIMER_WIDTH'(dut.home_score_wire), '0);
        check_time("reset away score", TIMER_WIDTH'(dut.away_score_wire), '0);

        repeat (10) begin : scan_check
            logic [3:0] exp_select;
            exp_select = display_select + 4'd1;
            pulse_forced_2640hz();
            check_vec4("display select increments", display_select, exp_select);
        end
        pulse_forced_2640hz();
        check_vec4("display select wraps", display_select, 4'd0);

        press_button(BTN_START_STOP);
        check_bit("start enables game clock", dut.game_clock_en_wire, 1'b1);
        check_bit("start enables shot clock", dut.shot_clock_en_wire, 1'b1);

        press_button(BTN_START_STOP);
        check_bit("stop disables game clock", dut.game_clock_en_wire, 1'b0);
        check_bit("stop disables shot clock", dut.shot_clock_en_wire, 1'b0);

        press_button(BTN_SCORE_UP);
        check_time("home score increments", TIMER_WIDTH'(dut.home_score_wire), TIMER_WIDTH'(1));
        check_time("away score unchanged", TIMER_WIDTH'(dut.away_score_wire), '0);

        press_button(BTN_POSSESSION);
        check_vec2("possession toggles to away", possession_leds, 2'b10);

        press_button(BTN_SCORE_UP);
        press_button(BTN_SCORE_UP);
        check_time("away score increments twice", TIMER_WIDTH'(dut.away_score_wire), TIMER_WIDTH'(2));

        press_button(BTN_SCORE_DOWN);
        check_time("away score decrements", TIMER_WIDTH'(dut.away_score_wire), TIMER_WIDTH'(1));

        condition_button(BTN_SHOT_RESET);
        check_bit("shot reset asserts load", dut.shot_clock_load_wire, 1'b1);
        check_time("shot reset load value", dut.shot_clock_load_value_wire, SHOT_CLOCK_TENTHS);
        finish_button(BTN_SHOT_RESET);

        press_button(BTN_START_STOP);
        check_bit("restart enables game clock", dut.game_clock_en_wire, 1'b1);
        check_bit("restart enables shot clock", dut.shot_clock_en_wire, 1'b1);

        check_expire_game_clock("Q1 expires", 4'b0010, 1'b1, 1'b1, INTERMISSION_TENTHS);
        check_bit("intermission keeps game clock enabled", dut.game_clock_en_wire, 1'b1);
        check_bit("intermission disables shot clock", dut.shot_clock_en_wire, 1'b0);

        check_expire_game_clock("intermission expires", 4'b0010, 1'b0, 1'b1, FULL_PERIOD_TENTHS);
        check_bit("Q2 game resumes shot clock", dut.shot_clock_en_wire, 1'b1);

        check_expire_game_clock("Q2 expires", 4'b0100, 1'b1, 1'b1, HALFTIME_TENTHS);
        check_bit("halftime disables shot clock", dut.shot_clock_en_wire, 1'b0);

        check_expire_game_clock("halftime expires", 4'b0100, 1'b0, 1'b1, FULL_PERIOD_TENTHS);
        check_bit("Q3 game resumes shot clock", dut.shot_clock_en_wire, 1'b1);

        check_expire_game_clock("Q3 expires", 4'b1000, 1'b1, 1'b1, INTERMISSION_TENTHS);
        check_expire_game_clock("intermission before Q4 expires", 4'b1000, 1'b0, 1'b1, FULL_PERIOD_TENTHS);

        check_expire_game_clock("Q4 expires", 4'b1000, 1'b0, 1'b0, '0);
        check_bit("final state stops game clock", dut.game_clock_en_wire, 1'b0);
        check_bit("final state stops shot clock", dut.shot_clock_en_wire, 1'b0);

        force dut.game_clock_time_wire = '0;
        #1;
        check_byte("game clock zero display digit", dut.gc_ss4, 8'b11000000);
        release dut.game_clock_time_wire;
        check_bit("score colon tied off", scr_colon_out, 1'b0);

        if (err_count == 0)
            $display("PASS top_tb");
        else
            $display("FAIL top_tb errors=%0d", err_count);
        $finish;
    end

endmodule
