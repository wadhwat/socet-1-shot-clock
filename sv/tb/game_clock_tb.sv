`timescale 1ns/1ps

module game_clock_tb;

    initial begin
        $dumpfile("game_clock_tb.vcd");  // output file name
        $dumpvars(0, game_clock_tb);      // dump all signals in the TB
    end

    localparam int TIMER_WIDTH = 14;
    localparam int PERIOD_MINUTES = 12;
    localparam int SECONDS_PER_MINUTE = 60;
    localparam int TENTHS_PER_SECOND = 10;
    localparam int FULL_PERIOD_TENTHS =
        PERIOD_MINUTES * SECONDS_PER_MINUTE * TENTHS_PER_SECOND;
    localparam logic [TIMER_WIDTH-1:0] MAX_TENTHS = {TIMER_WIDTH{1'b1}};

    localparam int RANDOM_LOAD_ITERATIONS = 256;
    localparam int RANDOM_SEED = 32'hACE1_0242;

    logic clk;
    logic nrst;
    logic tick_10hz;
    logic enable;
    logic game_clock_load;
    logic [TIMER_WIDTH-1:0] game_clock_load_value;
    logic [TIMER_WIDTH-1:0] current_time_value;
    logic expired;

    int err_count;

    game_clock #(
        .PERIOD_MINUTES(PERIOD_MINUTES),
        .SECONDS_PER_MINUTE(SECONDS_PER_MINUTE),
        .TENTHS_PER_SECOND(TENTHS_PER_SECOND),
        .TIMER_WIDTH(TIMER_WIDTH)
    ) dut (
        .clk(clk),
        .nrst(nrst),
        .tick_10hz(tick_10hz),
        .enable(enable),
        .game_clock_load(game_clock_load),
        .game_clock_load_value(game_clock_load_value),
        .current_time_value(current_time_value),
        .expired(expired)
    );

    // 100 MHz
    always #5 clk = ~clk;

    task automatic pulse_tick_10hz();
        @(posedge clk);
        tick_10hz = 1'b1;
        @(posedge clk);
        tick_10hz = 1'b0;
    endtask

    task automatic apply_reset();
        nrst = 1'b0;
        tick_10hz = 1'b0;
        enable = 1'b0;
        game_clock_load = 1'b0;
        game_clock_load_value = '0;
        repeat (5) @(posedge clk);
        nrst = 1'b1;
        @(posedge clk);
    endtask

    task automatic load_timer(input logic [TIMER_WIDTH-1:0] v);
        @(posedge clk);
        game_clock_load = 1'b1;
        game_clock_load_value = v;
        @(posedge clk);
        game_clock_load = 1'b0;
    endtask

    function automatic void check_eq(
        input string what,
        input logic [TIMER_WIDTH-1:0] got,
        input logic [TIMER_WIDTH-1:0] exp
    );
        if (got !== exp) begin
            $error("FAIL %s: got %0d expected %0d @ %0t", what, got, exp, $time);
            err_count++;
        end
    endfunction

    function automatic void check_bit(
        input string what,
        input logic got,
        input logic exp
    );
        if (got !== exp) begin
            $error("FAIL %s: got %b expected %b @ %0t", what, got, exp, $time);
            err_count++;
        end
    endfunction

    initial begin
        clk = 1'b0;
        err_count = 0;
        begin int seed = RANDOM_SEED; void'($urandom(seed)); end

        // --- Reset ---
        apply_reset();
        check_eq("after reset: time",    current_time_value, '0);
        check_bit("after reset: expired", expired, 1'b0);

        // --- Load and readback (full period) ---
        // The timer stores tenths directly; 12 min * 60 s/min * 10 tenths/s = 7200 tenths.
        load_timer(TIMER_WIDTH'(FULL_PERIOD_TENTHS));
        check_eq("load full period",           current_time_value, TIMER_WIDTH'(FULL_PERIOD_TENTHS));
        check_bit("expired clear after load",  expired, 1'b0);

        // --- Load zero with enable: expired asserts same cycle as load completes ---
        enable = 1'b1;
        load_timer(TIMER_WIDTH'(0));
        check_eq("load zero",                         current_time_value, TIMER_WIDTH'(0));
        check_bit("expired high after load 0 enable", expired, 1'b1);
        enable = 1'b0;

        // --- Random loads: full unsigned range for TIMER_WIDTH ---
        begin
            int n;
            logic [TIMER_WIDTH-1:0] rv;
            for (n = 0; n < RANDOM_LOAD_ITERATIONS; n++) begin
                rv = TIMER_WIDTH'($urandom_range(0, int'(MAX_TENTHS)));
                load_timer(rv);
                check_eq($sformatf("random load iter %0d", n), current_time_value, rv);
            end
        end

        // --- Load while countdown in progress ---
        load_timer(TIMER_WIDTH'(20));
        enable = 1'b1;
        repeat (5) pulse_tick_10hz();
        check_eq("mid-run value before load", current_time_value, TIMER_WIDTH'(15));
        load_timer(TIMER_WIDTH'(50));
        check_eq("load mid-run overrides count",       current_time_value, TIMER_WIDTH'(50));
        check_bit("expired clear after mid-run load",  expired, 1'b0);

        // --- No count when disabled ---
        load_timer(TIMER_WIDTH'(10));
        enable = 1'b0;
        repeat (3) pulse_tick_10hz();
        check_eq("hold with enable=0",        current_time_value, TIMER_WIDTH'(10));
        check_bit("expired 0 with enable=0",  expired, 1'b0);

        // --- Decrement with expired=0 verified at each step ---
        load_timer(TIMER_WIDTH'(3));
        enable = 1'b1;
        pulse_tick_10hz();
        check_eq("dec 3->2",        current_time_value, TIMER_WIDTH'(2));
        check_bit("expired 0 at 2", expired, 1'b0);
        pulse_tick_10hz();
        check_eq("dec 2->1",        current_time_value, TIMER_WIDTH'(1));
        check_bit("expired 0 at 1", expired, 1'b0);
        pulse_tick_10hz();
        check_eq("dec 1->0",        current_time_value, TIMER_WIDTH'(0));

        // --- Expired: high for exactly one cycle when 1->0 ---
        load_timer(TIMER_WIDTH'(1));
        enable = 1'b1;
        @(posedge clk);
        check_bit("expired 0 before terminal tick",  expired, 1'b0);
        pulse_tick_10hz();
        check_bit("expired 1 after terminal tick",   expired, 1'b1);
        check_eq("time 0 after terminal",            current_time_value, TIMER_WIDTH'(0));
        @(posedge clk);
        check_bit("expired cleared next cycle",      expired, 1'b0);

        // --- No expiry or decrement when disabled at terminal tick ---
        load_timer(TIMER_WIDTH'(1));
        enable = 1'b0;
        pulse_tick_10hz();
        check_eq("no dec at 1 with enable=0",           current_time_value, TIMER_WIDTH'(1));
        check_bit("no expired at terminal with enable=0", expired, 1'b0);
        enable = 1'b1;

        // --- Saturation at 0; expired stays 0 on subsequent ticks ---
        load_timer(TIMER_WIDTH'(1));
        enable = 1'b1;
        pulse_tick_10hz();   // 1->0, expired fires
        @(posedge clk);      // expired clears
        repeat (4) begin
            pulse_tick_10hz();
            check_eq("saturate at 0",            current_time_value, '0);
            check_bit("expired 0 during saturation", expired, 1'b0);
        end

        // --- Reload after expiry and countdown to 0 again ---
        load_timer(TIMER_WIDTH'(2));
        check_eq("reload after 0", current_time_value, TIMER_WIDTH'(2));
        pulse_tick_10hz();
        pulse_tick_10hz();
        check_bit("expired after reload countdown", expired, 1'b1);
        check_eq("countdown to 0", current_time_value, '0);
        @(posedge clk);
        check_bit("expired clears next cycle after reload path", expired, 1'b0);

        // --- Full period load after expiry ---
        // Note: load_timer waits one posedge before asserting game_clock_load, so
        // expired will already clear naturally; we verify final state is correct.
        load_timer(TIMER_WIDTH'(1));
        enable = 1'b1;
        pulse_tick_10hz();
        check_bit("expired high before full-period load", expired, 1'b1);
        load_timer(TIMER_WIDTH'(FULL_PERIOD_TENTHS));
        check_eq("full period load value",          current_time_value, TIMER_WIDTH'(FULL_PERIOD_TENTHS));
        check_bit("expired 0 after full-period load", expired, 1'b0);

        if (err_count == 0)
            $display("PASS game_clock_tb (%0d checks)", RANDOM_LOAD_ITERATIONS + 34);
        else
            $display("FAIL game_clock_tb errors=%0d", err_count);
        $finish;
    end

endmodule
