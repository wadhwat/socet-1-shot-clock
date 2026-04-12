`timescale 1ns / 1ps

module brightness_test_tb;

    logic clk_100mhz;
    logic rst_n;
    logic btn_cycle;

    logic [3:0] disp_sel;
    logic [7:0] seg;

    localparam int TB_DEBOUNCE_CYCLES = 20;

    brightness_test #(
        .DEBOUNCE_CYCLES(TB_DEBOUNCE_CYCLES)
    ) dut (
        .clk_100mhz(clk_100mhz),
        .rst_n      (rst_n),
        .btn_cycle  (btn_cycle),
        .disp_sel   (disp_sel),
        .seg        (seg)
    );

    // 100 MHz clock
    initial begin
        clk_100mhz = 1'b0;
        forever #5 clk_100mhz = ~clk_100mhz;
    end

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

    task automatic expect_freq(input int expected_sel, input int expected_hz, input string label);
        begin
            if (dut.freq_sel !== expected_sel)
                $display("[%0t ns] FAIL: %s | expected freq_sel=%0d got %0d",
                         $time, label, expected_sel, dut.freq_sel);
            else
                $display("[%0t ns] PASS: %s | freq_sel=%0d",
                         $time, label, dut.freq_sel);

            if (dut.frame_hz !== expected_hz)
                $display("[%0t ns] FAIL: %s | expected frame_hz=%0d got %0d",
                         $time, label, expected_hz, dut.frame_hz);
            else
                $display("[%0t ns] PASS: %s | frame_hz=%0d",
                         $time, label, dut.frame_hz);
        end
    endtask

    // Active-low 7-seg decode: {dp,g,f,e,d,c,b,a}
    function automatic logic [7:0] seg_decode_active_low(input logic [3:0] digit);
        begin
            case (digit)
                4'd0: seg_decode_active_low = 8'hC0;
                4'd1: seg_decode_active_low = 8'hF9;
                4'd2: seg_decode_active_low = 8'hA4;
                4'd3: seg_decode_active_low = 8'hB0;
                4'd4: seg_decode_active_low = 8'h99;
                4'd5: seg_decode_active_low = 8'h92;
                4'd6: seg_decode_active_low = 8'h82;
                4'd7: seg_decode_active_low = 8'hF8;
                4'd8: seg_decode_active_low = 8'h80;
                4'd9: seg_decode_active_low = 8'h90;
                default: seg_decode_active_low = 8'hFF;
            endcase
        end
    endfunction

    function automatic logic [3:0] expected_digit_for_slot(
        input int freq,
        input int slot
    );
        int thousands, hundreds, tens, ones;
        begin
            thousands = (freq / 1000) % 10;
            hundreds  = (freq / 100)  % 10;
            tens      = (freq / 10)   % 10;
            ones      = freq % 10;

            case (slot)
                0: expected_digit_for_slot = thousands[3:0];
                1: expected_digit_for_slot = hundreds[3:0];
                2: expected_digit_for_slot = tens[3:0];
                3: expected_digit_for_slot = ones[3:0];
                default: expected_digit_for_slot = 4'd0;
            endcase
        end
    endfunction

    task automatic verify_one_full_scan(input int expected_hz, input string label);
        logic [11:0] seen_slots;
        logic [7:0] expected_seg;
        logic [3:0] expected_digit;
        int tick_count;
        begin
            seen_slots = 12'b0;
            tick_count = 0;

            $display("[%0t ns] TEST: begin scan verification for %s", $time, label);

            while (seen_slots != 12'hFFF && tick_count < 30) begin
                @(posedge clk_100mhz);
                if (dut.slot_tick) begin
                    tick_count = tick_count + 1;
                    seen_slots[disp_sel] = 1'b1;

                    if (disp_sel <= 3) begin
                        expected_digit = expected_digit_for_slot(expected_hz, disp_sel);
                        expected_seg   = seg_decode_active_low(expected_digit);

                        if (seg !== expected_seg) begin
                            $display("[%0t ns] FAIL: %s | slot %0d expected digit %0d seg=0x%02h got 0x%02h",
                                     $time, label, disp_sel, expected_digit, expected_seg, seg);
                        end else begin
                            $display("[%0t ns] PASS: %s | slot %0d digit %0d seg=0x%02h",
                                     $time, label, disp_sel, expected_digit, seg);
                        end
                    end else begin
                        if (seg !== 8'hFF) begin
                            $display("[%0t ns] FAIL: %s | slot %0d expected blank seg=0xFF got 0x%02h",
                                     $time, label, disp_sel, seg);
                        end else begin
                            $display("[%0t ns] PASS: %s | slot %0d blank",
                                     $time, label, disp_sel);
                        end
                    end
                end
            end

            if (seen_slots != 12'hFFF) begin
                $display("[%0t ns] FAIL: %s | did not observe all 12 slots, seen mask = 0x%03h",
                         $time, label, seen_slots);
            end else begin
                $display("[%0t ns] PASS: %s | observed all slots 0..11",
                         $time, label);
            end
        end
    endtask

    initial begin
        rst_n     = 1'b0;
        btn_cycle = 1'b0;

        $display("============================================================");
        $display("Starting brightness_test_tb");
        $display("Using DEBOUNCE_CYCLES = %0d", TB_DEBOUNCE_CYCLES);
        $display("============================================================");

        #100;
        rst_n = 1'b1;
        $display("[%0t ns] TEST: released reset", $time);

        #200;
        expect_freq(0, 30, "After reset");

        // Walk frequencies
        press_button(500, 1000);
        #500;
        expect_freq(1, 60, "After press 1");

        press_button(500, 1000);
        #500;
        expect_freq(2, 120, "After press 2");

        press_button(500, 1000);
        #500;
        expect_freq(3, 240, "After press 3");

        press_button(500, 1000);
        #500;
        expect_freq(4, 480, "After press 4");

        press_button(500, 1000);
        #500;
        expect_freq(0, 30, "After press 5 wrap");

        // Let it run long enough for real scan checks
        verify_one_full_scan(30, "Scan check at 30 Hz");

        $display("============================================================");
        $display("Finished brightness_test_tb");
        $display("============================================================");
        $finish;
    end

endmodule