`timescale 1ns/1ps

module game_clock_tb;

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

    initial begin
        clk = 1'b0;
        err_count = 0;
        void'($urandom(RANDOM_SEED));

        apply_reset();
        check_eq("after reset current_time", current_time_value, '0);
        if (expired !== 1'b0) begin
            $error("FAIL after reset expired");
            err_count++;
        end

        // --- Load and readback ---
        load_timer(TIMER_WIDTH'(12 * 60 * 10));
        check_eq("load 1200", current_time_value, TIMER_WIDTH'(1200));

        // --- Random loads: full unsigned range for TIMER_WIDTH ---
        begin
            int n;
            logic [TIMER_WIDTH-1:0] rv;
            for (n = 0; n < RANDOM_LOAD_ITERATIONS; n++) begin
                rv = TIMER_WIDTH'($urandom_range(0, MAX_TENTHS));
                load_timer(rv);
                check_eq($sformatf("random load iter %0d", n), current_time_value, rv);
            end
        end

        // --- No count when disabled ---
        load_timer(TIMER_WIDTH'(10));
        enable = 1'b0;
        repeat (3) pulse_tick_10hz();
        check_eq("hold with enable=0", current_time_value, TIMER_WIDTH'(10));
        enable = 1'b1;

        // --- Decrement ---
        load_timer(TIMER_WIDTH'(3));
        enable = 1'b1;
        pulse_tick_10hz();
        check_eq("dec 3->2", current_time_value, TIMER_WIDTH'(2));
        pulse_tick_10hz();
        check_eq("dec 2->1", current_time_value, TIMER_WIDTH'(1));
        pulse_tick_10hz();
        check_eq("dec 1->0", current_time_value, TIMER_WIDTH'(0));

        // --- Expired: high for exactly one cycle after hitting 0 ---
        load_timer(TIMER_WIDTH'(1));
        enable = 1'b1;
        @(posedge clk);
        if (expired !== 1'b0) begin
            $error("FAIL expired before terminal tick");
            err_count++;
        end
        pulse_tick_10hz();
        @(posedge clk);
        if (expired !== 1'b1) begin
            $error("FAIL expired not high cycle after 0");
            err_count++;
        end
        @(posedge clk);
        if (expired !== 1'b0) begin
            $error("FAIL expired not one cycle");
            err_count++;
        end

        // --- Stay at 0, no underflow ---
        repeat (4) pulse_tick_10hz();
        check_eq("saturate at 0", current_time_value, '0);

        // --- Reload after expiry path ---
        load_timer(TIMER_WIDTH'(2));
        check_eq("reload after 0", current_time_value, TIMER_WIDTH'(2));
        pulse_tick_10hz();
        pulse_tick_10hz();
        @(posedge clk);
        check_eq("countdown to 0", current_time_value, '0);
        @(posedge clk);
        if (expired !== 1'b1) begin
            $error("FAIL expired after reload countdown");
            err_count++;
        end
        load_timer(TIMER_WIDTH'(FULL_PERIOD_TENTHS));
        check_eq("full period load", current_time_value, TIMER_WIDTH'(FULL_PERIOD_TENTHS));
        if (expired !== 1'b0) begin
            $error("FAIL expired cleared on load");
            err_count++;
        end

        if (err_count == 0)
            $display("PASS game_clock_tb (%0d checks)", RANDOM_LOAD_ITERATIONS + 20);
        else
            $display("FAIL game_clock_tb errors=%0d", err_count);
        $finish;
    end

endmodule
