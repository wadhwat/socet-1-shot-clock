`timescale 1ns / 1ps

module brightness_test_tb;

    logic clk_100mhz;
    logic rst_n;
    logic btn_cycle;

    logic [3:0] disp_sel;
    logic [7:0] seg;

    // Fast debounce for simulation
    localparam int TB_DEBOUNCE_CYCLES = 20;

    // DUT
    brightness_test #(
        .DEBOUNCE_CYCLES(TB_DEBOUNCE_CYCLES)
    ) dut (
        .clk_100mhz(clk_100mhz),
        .rst_n      (rst_n),
        .btn_cycle  (btn_cycle),
        .disp_sel   (disp_sel),
        .seg        (seg)
    );

    // ============================================================
    // 100 MHz clock
    // ============================================================
    initial begin
        clk_100mhz = 1'b0;
        forever #5 clk_100mhz = ~clk_100mhz;
    end

    // ============================================================
    // Helpers
    // ============================================================
    task automatic press_button(input int hold_ns, input int gap_ns);
        begin
            $display("[%0t ns] TEST: press_button start", $time);
            btn_cycle = 1'b1;
            #(hold_ns);
            btn_cycle = 1'b0;
            $display("[%0t ns] TEST: press_button end", $time);
            #(gap_ns);
        end
    endtask

    task automatic print_status(input string tag);
        begin
            $display("[%0t ns] %s | rst_n=%0b btn=%0b freq_sel=%0d frame_hz=%0d slot_idx=%0d disp_sel=%0d seg=0x%02h",
                     $time, tag, rst_n, btn_cycle,
                     dut.freq_sel, dut.frame_hz, dut.slot_idx, disp_sel, seg);
        end
    endtask

    task automatic expect_frame_hz(input int expected_hz, input string label);
        begin
            if (dut.frame_hz === expected_hz) begin
                $display("[%0t ns] PASS: %s | frame_hz=%0d",
                         $time, label, dut.frame_hz);
            end
            else begin
                $display("[%0t ns] FAIL: %s | expected frame_hz=%0d, got %0d",
                         $time, label, expected_hz, dut.frame_hz);
            end
        end
    endtask

    task automatic expect_freq_sel(input int expected_sel, input string label);
        begin
            if (dut.freq_sel === expected_sel) begin
                $display("[%0t ns] PASS: %s | freq_sel=%0d",
                         $time, label, dut.freq_sel);
            end
            else begin
                $display("[%0t ns] FAIL: %s | expected freq_sel=%0d, got %0d",
                         $time, label, expected_sel, dut.freq_sel);
            end
        end
    endtask

    // ============================================================
    // Monitor frequency changes
    // ============================================================
    logic [2:0]  prev_freq_sel;
    logic [15:0] prev_frame_hz;

    always_ff @(posedge clk_100mhz) begin
        if (!rst_n) begin
            prev_freq_sel  <= dut.freq_sel;
            prev_frame_hz  <= dut.frame_hz;
        end
        else begin
            if (dut.freq_sel != prev_freq_sel || dut.frame_hz != prev_frame_hz) begin
                $display("[%0t ns] INFO: frequency changed | freq_sel %0d -> %0d | frame_hz %0d -> %0d",
                         $time, prev_freq_sel, dut.freq_sel, prev_frame_hz, dut.frame_hz);
            end

            prev_freq_sel <= dut.freq_sel;
            prev_frame_hz <= dut.frame_hz;
        end
    end

    // ============================================================
    // Print each slot tick
    // This can get noisy, so only prints for slots 0..3
    // ============================================================
    always_ff @(posedge clk_100mhz) begin
        if (rst_n && dut.slot_tick) begin
            if (dut.slot_idx <= 4'd3) begin
                $display("[%0t ns] SCAN: slot_idx=%0d disp_sel=%0d seg=0x%02h frame_hz=%0d",
                         $time, dut.slot_idx, disp_sel, seg, dut.frame_hz);
            end
        end
    end

    // ============================================================
    // Main stimulus
    // ============================================================
    initial begin
        rst_n     = 1'b0;
        btn_cycle = 1'b0;

        $display("============================================================");
        $display("Starting brightness_test_tb");
        $display("Using DEBOUNCE_CYCLES = %0d", TB_DEBOUNCE_CYCLES);
        $display("============================================================");

        print_status("Initial state before reset release");

        // Hold reset
        #100;
        rst_n = 1'b1;
        $display("[%0t ns] TEST: released reset", $time);

        #200;
        print_status("After reset release");
        expect_freq_sel(0, "Default frequency select after reset");
        expect_frame_hz(30, "Default frame_hz after reset");

        // --------------------------------------------------------
        // Press 1 -> 60 Hz
        // --------------------------------------------------------
        press_button(500, 1000);
        #500;
        print_status("After press 1");
        expect_freq_sel(1, "After 1st button press");
        expect_frame_hz(60, "After 1st button press");

        // --------------------------------------------------------
        // Press 2 -> 120 Hz
        // --------------------------------------------------------
        press_button(500, 1000);
        #500;
        print_status("After press 2");
        expect_freq_sel(2, "After 2nd button press");
        expect_frame_hz(120, "After 2nd button press");

        // --------------------------------------------------------
        // Press 3 -> 240 Hz
        // --------------------------------------------------------
        press_button(500, 1000);
        #500;
        print_status("After press 3");
        expect_freq_sel(3, "After 3rd button press");
        expect_frame_hz(240, "After 3rd button press");

        // --------------------------------------------------------
        // Press 4 -> 480 Hz
        // --------------------------------------------------------
        press_button(500, 1000);
        #500;
        print_status("After press 4");
        expect_freq_sel(4, "After 4th button press");
        expect_frame_hz(480, "After 4th button press");

        // --------------------------------------------------------
        // Press 5 -> wrap back to 30 Hz
        // --------------------------------------------------------
        press_button(500, 1000);
        #500;
        print_status("After press 5");
        expect_freq_sel(0, "After 5th button press wrap");
        expect_frame_hz(30, "After 5th button press wrap");

        // --------------------------------------------------------
        // Let scan run a little
        // --------------------------------------------------------
        $display("[%0t ns] TEST: letting scan run for observation", $time);
        #20_000;

        print_status("Final status before finish");

        $display("============================================================");
        $display("Finished brightness_test_tb");
        $display("============================================================");

        $finish;
    end

endmodule