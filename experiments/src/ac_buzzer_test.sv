module ac_buzzer_test #(
    parameter int CLK_HZ      = 100_000_000,
    parameter int TONE_HZ     = 2_400,
    parameter int BEEP_MS     = 500,
    parameter int SILENCE_MS  = 500
) (
    input  logic clk_100mhz,
    output logic buzzer_drive
);

    localparam int HALF_PERIOD_TICKS = CLK_HZ / (TONE_HZ * 2);
    localparam int BEEP_TICKS        = (CLK_HZ / 1000) * BEEP_MS;
    localparam int SILENCE_TICKS     = (CLK_HZ / 1000) * SILENCE_MS;
    localparam int BURST_TICKS       = BEEP_TICKS + SILENCE_TICKS;

    logic [$clog2(HALF_PERIOD_TICKS):0] tone_count = '0;
    logic [$clog2(BURST_TICKS):0]       burst_count = '0;
    logic                               tone = 1'b0;
    logic                               beep_enable;

    assign beep_enable = burst_count < BEEP_TICKS;
    assign buzzer_drive = beep_enable ? tone : 1'b0;

    always_ff @(posedge clk_100mhz) begin
        if (burst_count == BURST_TICKS - 1)
            burst_count <= '0;
        else
            burst_count <= burst_count + 1'b1;

        if (tone_count == HALF_PERIOD_TICKS - 1) begin
            tone_count <= '0;
            tone       <= ~tone;
        end else begin
            tone_count <= tone_count + 1'b1;
        end
    end

endmodule
