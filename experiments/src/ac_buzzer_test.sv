/*
Standalone main-board buzzer smoke test.

The AT-1224-TWT-5V-2-R is a magnetic transducer, so it needs an AC square
wave near its 2.4 kHz resonant frequency instead of a steady DC level.
*/

`timescale 1ns/1ps

module ac_buzzer_test #(
    parameter int CLK_HZ     = 100_000_000,
    parameter int TONE_HZ    = 2_400,
    parameter int BEEP_MS    = 750,
    parameter int SILENCE_MS = 250
) (
    input  logic clk,
    output logic buzzer_drive,
    output logic buzzer_active_led
);

    localparam int HALF_PERIOD_TICKS = CLK_HZ / (TONE_HZ * 2);
    localparam int BEEP_TICKS        = (CLK_HZ / 1000) * BEEP_MS;
    localparam int SILENCE_TICKS     = (CLK_HZ / 1000) * SILENCE_MS;
    localparam int BURST_TICKS       = BEEP_TICKS + SILENCE_TICKS;

    localparam int HALF_COUNT_WIDTH  = (HALF_PERIOD_TICKS <= 1) ? 1 : $clog2(HALF_PERIOD_TICKS);
    localparam int BURST_COUNT_WIDTH = (BURST_TICKS <= 1) ? 1 : $clog2(BURST_TICKS);

    logic [HALF_COUNT_WIDTH-1:0]  tone_count = '0;
    logic [BURST_COUNT_WIDTH-1:0] burst_count = '0;
    logic                         tone = 1'b0;
    logic                         beep_active;

    assign beep_active = burst_count < BEEP_TICKS;
    assign buzzer_drive = beep_active ? tone : 1'b0;
    assign buzzer_active_led = beep_active;

    always_ff @(posedge clk) begin
        if (burst_count == BURST_TICKS - 1)
            burst_count <= '0;
        else
            burst_count <= burst_count + 1'b1;

        if (!beep_active) begin
            tone_count <= '0;
            tone       <= 1'b0;
        end else if (tone_count == HALF_PERIOD_TICKS - 1) begin
            tone_count <= '0;
            tone       <= ~tone;
        end else begin
            tone_count <= tone_count + 1'b1;
        end
    end

endmodule
