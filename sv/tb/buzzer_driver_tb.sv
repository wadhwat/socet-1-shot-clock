`timescale 1ns/1ps

module buzzer_driver_tb;

    initial begin
        $dumpfile("buzzer_driver_tb.vcd");
        $dumpvars(0, buzzer_driver_tb);
    end

    localparam int CLK_FREQ  = 1000;
    localparam int FREQUENCY = 100;

    localparam int HALF_PERIOD_CYCLES = CLK_FREQ / (2 * FREQUENCY); // 5
    localparam int DECISECOND_CYCLES  = CLK_FREQ / 10;               // 100

    logic clk;
    logic nrst;
    logic buzzer_pulse;
    logic [6:0] buzzer_length;
    logic buzzer_out;

    int err_count;
    int tests_passed;
    int tests_failed;

    buzzer_driver #(
        .FREQUENCY(FREQUENCY),
        .CLK_FREQ (CLK_FREQ)
    ) dut (
        .clk           (clk),
        .nrst          (nrst),
        .buzzer_pulse  (buzzer_pulse),
        .buzzer_length (buzzer_length),
        .buzzer_out    (buzzer_out)
    );

    always #5 clk = ~clk;

    function automatic void fail(input string msg);
        $error("FAIL: %s @ %0t", msg, $time);
        err_count++;
    endfunction

    function automatic void pass_test(input string name);
        $display("PASS: %s", name);
        tests_passed++;
    endfunction

    function automatic void fail_test(input string name);
        $display("FAIL: %s", name);
        tests_failed++;
    endfunction

    task automatic apply_reset(input int cycles);
        nrst = 1'b0;
        repeat (cycles) @(posedge clk);
        nrst = 1'b1;
        @(posedge clk);
    endtask

    task automatic pulse_buzzer_once();
        @(posedge clk);
        buzzer_pulse = 1'b1;
        @(posedge clk);
        buzzer_pulse = 1'b0;
    endtask

    // Observe `total_cycles` posedges after returning from this task's first @(posedge clk).
    // Counts edges on buzzer_out; consecutive edges must be exactly `half_period` cycles apart.
    task automatic check_toggle_cadence(
        input int total_cycles,
        input int half_period,
        input int exp_edges
    );
        int c;
        logic prev;
        int last_edge_c;
        int edge_count;
        prev = buzzer_out;
        last_edge_c = -1;
        edge_count = 0;
        for (c = 0; c < total_cycles; c++) begin
            @(posedge clk);
            if (buzzer_out !== prev) begin
                if (last_edge_c >= 0) begin
                    if ((c - last_edge_c) !== half_period)
                        fail($sformatf("toggle spacing: got %0d expected %0d @ cycle %0d",
                            c - last_edge_c, half_period, c));
                end
                last_edge_c = c;
                edge_count++;
                prev = buzzer_out;
            end
        end
        if (edge_count !== exp_edges)
            fail($sformatf("edge count: got %0d expected %0d", edge_count, exp_edges));
    endtask

    task automatic expect_low_for_cycles(input int n);
        repeat (n) begin
            @(posedge clk);
            if (buzzer_out !== 1'b0)
                fail("expected buzzer_out low while inactive");
        end
    endtask

    // Active buzz window: verify toggle cadence and no sustained low longer than half_period.
    task automatic check_buzz_window(
        input int total_cycles,
        input int half_period,
        input int exp_edges
    );
        int c;
        int low_run;
        logic prev;
        int last_edge_c;
        int edge_count;
        low_run = 0;
        prev = buzzer_out;
        last_edge_c = -1;
        edge_count = 0;
        for (c = 0; c < total_cycles; c++) begin
            @(posedge clk);
            if (buzzer_out === 1'b0 && prev === 1'b0)
                low_run++;
            else
                low_run = 0;
            if (low_run > half_period)
                fail($sformatf("sustained low too long (%0d) during active buzz @ cycle %0d", low_run, c));
            if (buzzer_out !== prev) begin
                if (last_edge_c >= 0) begin
                    if ((c - last_edge_c) !== half_period)
                        fail($sformatf("toggle spacing: got %0d expected %0d @ cycle %0d",
                            c - last_edge_c, half_period, c));
                end
                last_edge_c = c;
                edge_count++;
            end
            prev = buzzer_out;
        end
        if (edge_count !== exp_edges)
            fail($sformatf("edge count: got %0d expected %0d", edge_count, exp_edges));
    endtask

    initial begin
        int e0;

        clk = 1'b0;
        nrst = 1'b0;
        buzzer_pulse = 1'b0;
        buzzer_length = 7'd0;
        err_count = 0;
        tests_passed = 0;
        tests_failed = 0;

        // Let clock run, apply reset via task
        #1;
        apply_reset(5);

        // --- Test 1: Reset behavior ---
        $display("--- Test 1: Reset behavior ---");
        e0 = err_count;
        begin
            int k;
            nrst = 1'b0;
            for (k = 0; k < 3; k++) begin
                @(posedge clk);
                if (buzzer_out !== 1'b0)
                    fail("Test 1: buzzer_out must be 0 during reset");
            end
            nrst = 1'b1;
            @(posedge clk);
            if (buzzer_out !== 1'b0)
                fail("Test 1: buzzer_out must stay 0 after reset with no pulse");
        end
        if (err_count == e0) pass_test("Test 1: Reset behavior");
        else fail_test("Test 1: Reset behavior");

        // --- Test 2: Basic buzz ---
        $display("--- Test 2: Basic buzz ---");
        e0 = err_count;
        buzzer_length = 7'd1;
        pulse_buzzer_once();
        // 100 active cycles: 99 advance the half-period counter; final cycle ends low => 19 observed edges.
        check_toggle_cadence(100, HALF_PERIOD_CYCLES, 19);
        @(posedge clk);
        if (buzzer_out !== 1'b0)
            fail("Test 2: buzzer_out must be low after buzz ends");
        if (err_count == e0) pass_test("Test 2: Basic buzz");
        else fail_test("Test 2: Basic buzz");

        // --- Test 3: Output stays low after buzz ends ---
        $display("--- Test 3: Output stays low after buzz ends ---");
        e0 = err_count;
        expect_low_for_cycles(50);
        if (err_count == e0) pass_test("Test 3: Low after buzz");
        else fail_test("Test 3: Low after buzz");

        // --- Test 4: Longer buzz ---
        $display("--- Test 4: Longer buzz ---");
        e0 = err_count;
        buzzer_length = 7'd3;
        pulse_buzzer_once();
        check_toggle_cadence(300, HALF_PERIOD_CYCLES, 59);
        @(posedge clk);
        if (buzzer_out !== 1'b0)
            fail("Test 4: must be low after 300-cycle buzz");
        if (err_count == e0) pass_test("Test 4: Longer buzz");
        else fail_test("Test 4: Longer buzz");

        // --- Test 5: Re-trigger while buzzing ---
        $display("--- Test 5: Re-trigger while buzzing ---");
        e0 = err_count;
        buzzer_length = 7'd2;
        pulse_buzzer_once();
        repeat (50) @(posedge clk);
        buzzer_length = 7'd3;
        pulse_buzzer_once();
        // 300 cycles from re-trigger point (single window: cadence + no long sustained low)
        check_buzz_window(300, HALF_PERIOD_CYCLES, 59);
        @(posedge clk);
        if (buzzer_out !== 1'b0)
            fail("Test 5: must be low after re-triggered buzz");
        if (err_count == e0) pass_test("Test 5: Re-trigger");
        else fail_test("Test 5: Re-trigger");

        // --- Test 6: Zero length does nothing ---
        $display("--- Test 6: Zero length does nothing ---");
        e0 = err_count;
        buzzer_length = 7'd0;
        pulse_buzzer_once();
        expect_low_for_cycles(50);
        if (err_count == e0) pass_test("Test 6: Zero length");
        else fail_test("Test 6: Zero length");

        // --- Test 7: Reset during active buzz ---
        $display("--- Test 7: Reset during active buzz ---");
        e0 = err_count;
        buzzer_length = 7'd5;
        pulse_buzzer_once();
        repeat (30) @(posedge clk);
        nrst = 1'b0;
        @(posedge clk);
        if (buzzer_out !== 1'b0)
            fail("Test 7: buzzer_out must be 0 within one cycle of reset assert");
        repeat (4) @(posedge clk);
        if (buzzer_out !== 1'b0)
            fail("Test 7: buzzer_out must stay 0 during reset");
        nrst = 1'b1;
        @(posedge clk);
        repeat (10) @(posedge clk);
        if (buzzer_out !== 1'b0)
            fail("Test 7: buzzer must not resume without pulse");
        if (err_count == e0) pass_test("Test 7: Reset during buzz");
        else fail_test("Test 7: Reset during buzz");

        // --- Test 8: Back-to-back pulses ---
        $display("--- Test 8: Back-to-back pulses ---");
        e0 = err_count;
        buzzer_length = 7'd1;
        pulse_buzzer_once();
        check_toggle_cadence(100, HALF_PERIOD_CYCLES, 19);
        @(posedge clk);
        buzzer_length = 7'd1;
        pulse_buzzer_once();
        check_toggle_cadence(100, HALF_PERIOD_CYCLES, 19);
        @(posedge clk);
        if (buzzer_out !== 1'b0)
            fail("Test 8: low after second buzz");
        if (err_count == e0) pass_test("Test 8: Back-to-back");
        else fail_test("Test 8: Back-to-back");

        // --- Summary ---
        $display("--- Summary ---");
        $display("Tests passed: %0d", tests_passed);
        $display("Tests failed: %0d", tests_failed);
        $display("Check errors: %0d", err_count);
        if (err_count == 0 && tests_failed == 0)
            $display("PASS buzzer_driver_tb");
        else
            $display("FAIL buzzer_driver_tb");
        $finish;
    end

endmodule
