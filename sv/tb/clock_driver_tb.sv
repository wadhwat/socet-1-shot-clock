`timescale 1ns / 1ps

module clock_driver_tb;

    localparam int RANDOM_TESTS = 250;

    logic [15:0] tb_raw_deciseconds;
    logic [7:0]  tb_seg3, tb_seg2, tb_seg1, tb_seg0;
    logic        tb_colon;
    integer      err_count;
    integer      test_count;

    clock_driver dut (
        .raw_deciseconds(tb_raw_deciseconds),
        .seg3(tb_seg3),
        .seg2(tb_seg2),
        .seg1(tb_seg1),
        .seg0(tb_seg0),
        .colon(tb_colon)
    );

    initial begin
        $dumpfile("clock_driver_tb.vcd");
        $dumpvars(0, clock_driver_tb);

        err_count = 0;
        test_count = 0;

        check_case(16'd0,    "0 ds -> 000.0");
        check_case(16'd9,    "9 ds -> 000.9");
        check_case(16'd99,   "99 ds -> 009.9");
        check_case(16'd140,  "140 ds -> 014.0");
        check_case(16'd599,  "599 ds -> 059.9");
        check_case(16'd600,  "600 ds -> 01:00");
        check_case(16'd601,  "601 ds -> 01:00");
        check_case(16'd750,  "750 ds -> 01:15");
        check_case(16'd1400, "1400 ds -> 02:20");

        run_random_cases();

        if (err_count == 0)
            $display("PASS clock_driver_tb (%0d checks)", test_count);
        else
            $display("FAIL clock_driver_tb errors=%0d checks=%0d", err_count, test_count);

        $finish;
    end

    task automatic check_case(
        input logic [15:0] raw_ds,
        input string      label
    );
        logic [3:0] exp_d3;
        logic [3:0] exp_d2;
        logic [3:0] exp_d1;
        logic [3:0] exp_d0;
        logic       exp_colon;
        logic [3:0] exp_dp_mask;
        logic [7:0] exp_seg3;
        logic [7:0] exp_seg2;
        logic [7:0] exp_seg1;
        logic [7:0] exp_seg0;
        logic [3:0] act_dp_mask;
        begin
            tb_raw_deciseconds = raw_ds;
            #1;

            expected_digits(raw_ds, exp_d3, exp_d2, exp_d1, exp_d0, exp_colon, exp_dp_mask);
            exp_seg3 = expected_seg(exp_d3, exp_dp_mask[3]);
            exp_seg2 = expected_seg(exp_d2, exp_dp_mask[2]);
            exp_seg1 = expected_seg(exp_d1, exp_dp_mask[1]);
            exp_seg0 = expected_seg(exp_d0, exp_dp_mask[0]);
            act_dp_mask = {tb_seg3[7], tb_seg2[7], tb_seg1[7], tb_seg0[7]};
            test_count++;

            if (tb_seg3 !== exp_seg3) begin
                err_count++;
                $display("FAIL %s seg3 expected=%b actual=%b", label, exp_seg3, tb_seg3);
            end
            if (tb_seg2 !== exp_seg2) begin
                err_count++;
                $display("FAIL %s seg2 expected=%b actual=%b", label, exp_seg2, tb_seg2);
            end
            if (tb_seg1 !== exp_seg1) begin
                err_count++;
                $display("FAIL %s seg1 expected=%b actual=%b", label, exp_seg1, tb_seg1);
            end
            if (tb_seg0 !== exp_seg0) begin
                err_count++;
                $display("FAIL %s seg0 expected=%b actual=%b", label, exp_seg0, tb_seg0);
            end
            if (tb_colon !== exp_colon) begin
                err_count++;
                $display("FAIL %s colon expected=%b actual=%b", label, exp_colon, tb_colon);
            end
            if (act_dp_mask !== exp_dp_mask) begin
                err_count++;
                $display("FAIL %s dp-mask expected=%b actual=%b", label, exp_dp_mask, act_dp_mask);
            end
        end
    endtask

    task automatic run_random_cases;
        int i;
        logic [15:0] raw_ds;
        string label;
        begin
            for (i = 0; i < RANDOM_TESTS; i++) begin
                raw_ds = 16'($urandom_range(16'd0, 16'd59999));
                label = $sformatf("random case %0d raw_ds=%0d", i, raw_ds);
                check_case(raw_ds, label);
            end
        end
    endtask

    task automatic expected_digits(
        input  logic [15:0] raw_ds,
        output logic [3:0]  exp_d3,
        output logic [3:0]  exp_d2,
        output logic [3:0]  exp_d1,
        output logic [3:0]  exp_d0,
        output logic        exp_colon,
        output logic [3:0]  exp_dp_mask
    );
        int minutes;
        int seconds;
        int tenths;
        begin
            minutes = raw_ds / 600;
            seconds = (raw_ds % 600) / 10;
            tenths  = raw_ds % 10;

            if (raw_ds < 600) begin
                exp_d3 = 4'd0;
                exp_d2 = 4'(seconds / 10);
                exp_d1 = 4'(seconds % 10);
                exp_d0 = 4'(tenths);
                exp_colon = 1'b0;
                exp_dp_mask = 4'b0010;
            end else begin
                exp_d3 = 4'(minutes / 10);
                exp_d2 = 4'(minutes % 10);
                exp_d1 = 4'(seconds / 10);
                exp_d0 = 4'(seconds % 10);
                exp_colon = 1'b1;
                exp_dp_mask = 4'b0000;
            end
        end
    endtask

    function automatic logic [7:0] expected_seg(
        input logic [3:0] digit,
        input logic       dp_on
    );
        begin
            case (digit)
                4'd0: expected_seg[6:0] = 7'b0111111;
                4'd1: expected_seg[6:0] = 7'b0000110;
                4'd2: expected_seg[6:0] = 7'b1011011;
                4'd3: expected_seg[6:0] = 7'b1001111;
                4'd4: expected_seg[6:0] = 7'b1100110;
                4'd5: expected_seg[6:0] = 7'b1101101;
                4'd6: expected_seg[6:0] = 7'b1111101;
                4'd7: expected_seg[6:0] = 7'b0000111;
                4'd8: expected_seg[6:0] = 7'b1111111;
                4'd9: expected_seg[6:0] = 7'b1101111;
                default: expected_seg[6:0] = 7'b0000000;
            endcase
            expected_seg[7] = dp_on;
        end
    endfunction

endmodule
