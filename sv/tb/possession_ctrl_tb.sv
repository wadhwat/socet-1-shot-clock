`timescale 1ns/1ps

module possession_ctrl_tb;

    logic clk;
    logic n_rst;
    logic possession_toggle_pulse;
    logic possession_state;
    logic [1:0] possession_leds;

    int err_count;

    possession_ctrl dut (
        .clk(clk),
        .n_rst(n_rst),
        .possession_toggle_pulse(possession_toggle_pulse),
        .possession_state(possession_state),
        .possession_leds(possession_leds)
    );

    always #5 clk = ~clk;

    task automatic check_eq(
        input string label,
        input logic got,
        input logic exp
    );
        if (got !== exp) begin
            $error("FAIL %s: got %b expected %b @ %0t", label, got, exp, $time);
            err_count++;
        end
    endtask

    task automatic check_leds(
        input string label,
        input logic [1:0] got,
        input logic [1:0] exp
    );
        if (got !== exp) begin
            $error("FAIL %s: got %b expected %b @ %0t", label, got, exp, $time);
            err_count++;
        end
    endtask

    task automatic pulse_toggle();
        @(negedge clk);
        possession_toggle_pulse = 1'b1;
        @(negedge clk);
        possession_toggle_pulse = 1'b0;
    endtask

    initial begin
        clk = 1'b0;
        err_count = 0;
        possession_toggle_pulse = 1'b0;

        n_rst = 1'b0;
        repeat (2) @(posedge clk);
        check_eq("reset state", possession_state, 1'b0);
        check_leds("reset leds", possession_leds, 2'b01);

        n_rst = 1'b1;
        @(posedge clk);
        check_eq("state holds after reset release", possession_state, 1'b0);
        check_leds("leds hold after reset release", possession_leds, 2'b01);

        pulse_toggle();
        @(posedge clk);
        #1;
        check_eq("state toggles to away", possession_state, 1'b1);
        check_leds("leds show away", possession_leds, 2'b10);

        pulse_toggle();
        @(posedge clk);
        #1;
        check_eq("state toggles back to home", possession_state, 1'b0);
        check_leds("leds show home", possession_leds, 2'b01);

        @(negedge clk);
        possession_toggle_pulse = 1'b0;
        @(posedge clk);
        #1;
        check_eq("state holds without pulse", possession_state, 1'b0);
        check_leds("leds hold without pulse", possession_leds, 2'b01);

        n_rst = 1'b0;
        @(posedge clk);
        #1;
        check_eq("async reset returns home", possession_state, 1'b0);
        check_leds("async reset leds", possession_leds, 2'b01);

        if (err_count == 0)
            $display("PASS possession_ctrl_tb");
        else
            $display("FAIL possession_ctrl_tb errors=%0d", err_count);

        $finish;
    end

endmodule