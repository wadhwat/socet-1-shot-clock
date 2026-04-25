`timescale 1ns/1ps

module control_fsm_tb;

    initial begin
        $dumpfile("control_fsm_tb.vcd");
        $dumpvars(0, control_fsm_tb);
    end

    localparam int N_BUTTONS = 5;
    localparam int TIMER_WIDTH = 14;
    localparam int SHOT_TIMER_WIDTH = 10;
    localparam int SECONDS_PER_MINUTE = 60;
    localparam int TENTHS_PER_SECOND = 10;
    localparam int FULL_PERIOD_MINUTES = 15;
    localparam int SHOT_CLOCK_SECONDS = 30;
    localparam int INTERMISSION_SECONDS = 75;
    localparam int HALFTIME_MINUTES = 15;

    localparam int BTN_START_STOP = 0;
    localparam int BTN_POSSESSION = 1;
    localparam int BTN_SHOT_RESET = 4;

    localparam logic [1:0] Q1 = 2'd0;
    localparam logic [1:0] Q2 = 2'd1;
    localparam logic [1:0] Q3 = 2'd2;
    localparam logic [1:0] Q4 = 2'd3;

    localparam logic [TIMER_WIDTH-1:0] FULL_PERIOD_TENTHS =
        TIMER_WIDTH'(FULL_PERIOD_MINUTES * SECONDS_PER_MINUTE * TENTHS_PER_SECOND);
    localparam logic [TIMER_WIDTH-1:0] INTERMISSION_TENTHS =
        TIMER_WIDTH'(INTERMISSION_SECONDS * TENTHS_PER_SECOND);
    localparam logic [TIMER_WIDTH-1:0] HALFTIME_TENTHS =
        TIMER_WIDTH'(HALFTIME_MINUTES * SECONDS_PER_MINUTE * TENTHS_PER_SECOND);
    localparam logic [SHOT_TIMER_WIDTH-1:0] SHOT_CLOCK_TENTHS =
        SHOT_TIMER_WIDTH'(SHOT_CLOCK_SECONDS * TENTHS_PER_SECOND);

    logic clk;
    logic n_rst;
    logic [1:0] period_state;
    logic shot_clock_expired;
    logic game_clock_expired;
    logic tick_10hz;
    logic [N_BUTTONS-1:0] conditioned_buttons;

    logic buzzer_trigger;
    logic period_increment;
    logic possession_increment;
    logic shot_clock_en;
    logic shot_clock_load;
    logic [SHOT_TIMER_WIDTH-1:0] shot_clock_load_value;
    logic game_clock_en;
    logic game_clock_load;
    logic [TIMER_WIDTH-1:0] game_clock_load_value;

    int err_count;

    control_fsm #(
        .N_BUTTONS(N_BUTTONS),
        .TIMER_WIDTH(TIMER_WIDTH),
        .SHOT_TIMER_WIDTH(SHOT_TIMER_WIDTH),
        .SECONDS_PER_MINUTE(SECONDS_PER_MINUTE),
        .TENTHS_PER_SECOND(TENTHS_PER_SECOND),
        .FULL_PERIOD_MINUTES(FULL_PERIOD_MINUTES),
        .SHOT_CLOCK_SECONDS(SHOT_CLOCK_SECONDS),
        .INTERMISSION_SECONDS(INTERMISSION_SECONDS),
        .HALFTIME_MINUTES(HALFTIME_MINUTES)
    ) dut (
        .clk(clk),
        .n_rst(n_rst),
        .period_state(period_state),
        .shot_clock_expired(shot_clock_expired),
        .game_clock_expired(game_clock_expired),
        .tick_10hz(tick_10hz),
        .conditioned_buttons(conditioned_buttons),
        .buzzer_trigger(buzzer_trigger),
        .period_increment(period_increment),
        .possession_increment(possession_increment),
        .shot_clock_en(shot_clock_en),
        .shot_clock_load(shot_clock_load),
        .shot_clock_load_value(shot_clock_load_value),
        .game_clock_en(game_clock_en),
        .game_clock_load(game_clock_load),
        .game_clock_load_value(game_clock_load_value)
    );

    always #5 clk = ~clk;

    task automatic apply_reset();
        n_rst = 1'b0;
        period_state = Q1;
        shot_clock_expired = 1'b0;
        game_clock_expired = 1'b0;
        tick_10hz = 1'b0;
        conditioned_buttons = '0;
        repeat (5) @(posedge clk);
        n_rst = 1'b1;
        @(posedge clk);
    endtask

    task automatic pulse_button(input int button_index);
        @(negedge clk);
        conditioned_buttons[button_index] = 1'b1;
        @(negedge clk);
        conditioned_buttons[button_index] = 1'b0;
    endtask

    task automatic pulse_tick_10hz();
        @(negedge clk);
        tick_10hz = 1'b1;
        @(negedge clk);
        tick_10hz = 1'b0;
    endtask

    task automatic check_bit(input string what, input logic got, input logic exp);
        if (got !== exp) begin
            $error("FAIL %s: got %b expected %b @ %0t", what, got, exp, $time);
            err_count++;
        end
    endtask

    task automatic check_time(input string what, input logic [TIMER_WIDTH-1:0] got, input logic [TIMER_WIDTH-1:0] exp);
        if (got !== exp) begin
            $error("FAIL %s: got %0d expected %0d @ %0t", what, got, exp, $time);
            err_count++;
        end
    endtask

    task automatic check_shot_time(
        input string what,
        input logic [SHOT_TIMER_WIDTH-1:0] got,
        input logic [SHOT_TIMER_WIDTH-1:0] exp
    );
        if (got !== exp) begin
            $error("FAIL %s: got %0d expected %0d @ %0t", what, got, exp, $time);
            err_count++;
        end
    endtask

    task automatic start_clock();
        pulse_button(BTN_START_STOP);
        @(posedge clk);
        check_bit("game_clock_en after start", game_clock_en, 1'b1);
        check_bit("shot_clock_en after start", shot_clock_en, 1'b1);
    endtask

    task automatic expire_game_clock(
        input string what,
        input logic [1:0] period,
        input logic exp_period_increment,
        input logic exp_game_clock_load,
        input logic [TIMER_WIDTH-1:0] exp_load_value
    );
        @(negedge clk);
        period_state = period;
        game_clock_expired = 1'b1;
        #1;
        check_bit({what, " buzzer"}, buzzer_trigger, 1'b1);
        check_bit({what, " game load"}, game_clock_load, exp_game_clock_load);
        check_bit({what, " period increment"}, period_increment, exp_period_increment);
        check_time({what, " load value"}, game_clock_load_value, exp_load_value);
        @(negedge clk);
        game_clock_expired = 1'b0;
        @(posedge clk);
    endtask

    initial begin
        clk = 1'b0;
        err_count = 0;

        apply_reset();
        check_bit("reset game_clock_en", game_clock_en, 1'b0);
        check_bit("reset shot_clock_en", shot_clock_en, 1'b0);
        check_bit("reset buzzer_trigger", buzzer_trigger, 1'b0);
        check_bit("reset game_clock_load", game_clock_load, 1'b0);
        check_time("reset default game load value", game_clock_load_value, FULL_PERIOD_TENTHS);
        check_shot_time("reset shot load value", shot_clock_load_value, SHOT_CLOCK_TENTHS);

        start_clock();

        pulse_button(BTN_START_STOP);
        @(posedge clk);
        check_bit("game_clock_en after stop", game_clock_en, 1'b0);
        check_bit("shot_clock_en after stop", shot_clock_en, 1'b0);

        @(negedge clk);
        conditioned_buttons[BTN_POSSESSION] = 1'b1;
        #1;
        check_bit("possession pulse passes through", possession_increment, 1'b1);
        @(negedge clk);
        conditioned_buttons[BTN_POSSESSION] = 1'b0;
        #1;
        check_bit("possession pulse clears", possession_increment, 1'b0);

        @(negedge clk);
        conditioned_buttons[BTN_SHOT_RESET] = 1'b1;
        #1;
        check_bit("shot reset load", shot_clock_load, 1'b1);
        check_shot_time("shot reset load value", shot_clock_load_value, SHOT_CLOCK_TENTHS);
        @(negedge clk);
        conditioned_buttons[BTN_SHOT_RESET] = 1'b0;

        @(negedge clk);
        shot_clock_expired = 1'b1;
        #1;
        check_bit("shot expired reload", shot_clock_load, 1'b1);
        @(negedge clk);
        shot_clock_expired = 1'b0;

        start_clock();

        expire_game_clock("Q1 expires", Q1, 1'b1, 1'b1, INTERMISSION_TENTHS);
        check_bit("intermission keeps game clock enabled", game_clock_en, 1'b1);
        check_bit("intermission disables shot clock", shot_clock_en, 1'b0);

        expire_game_clock("intermission expires", Q2, 1'b0, 1'b1, FULL_PERIOD_TENTHS);
        check_bit("game resumes after intermission", shot_clock_en, 1'b1);

        expire_game_clock("Q2 expires", Q2, 1'b1, 1'b1, HALFTIME_TENTHS);
        check_bit("halftime disables shot clock", shot_clock_en, 1'b0);

        expire_game_clock("halftime expires", Q3, 1'b0, 1'b1, FULL_PERIOD_TENTHS);
        check_bit("game resumes after halftime", shot_clock_en, 1'b1);

        expire_game_clock("Q3 expires", Q3, 1'b1, 1'b1, INTERMISSION_TENTHS);
        expire_game_clock("intermission before Q4 expires", Q4, 1'b0, 1'b1, FULL_PERIOD_TENTHS);

        expire_game_clock("Q4 expires", Q4, 1'b0, 1'b0, '0);
        check_bit("final state stops game clock", game_clock_en, 1'b0);
        check_bit("final state stops shot clock", shot_clock_en, 1'b0);

        if (err_count == 0)
            $display("PASS control_fsm_tb");
        else
            $display("FAIL control_fsm_tb errors=%0d", err_count);
        $finish;
    end

endmodule
