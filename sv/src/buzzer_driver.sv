// Square-wave buzzer driver: toggles buzzer_out at FREQUENCY while active for buzzer_length deciseconds.

`timescale 1ns/1ps

module buzzer_driver #(
    parameter integer FREQUENCY = 2000,
    parameter integer CLK_FREQ  = 100_000_000
) (
    input  wire              clk,
    input  wire              nrst,
    input  wire              buzzer_pulse,
    input  wire [6:0]        buzzer_length,
    output logic             buzzer_out
);

    localparam integer HALF_PERIOD_CYCLES = CLK_FREQ / (2 * FREQUENCY);
    localparam integer DECISECOND_CYCLES  = CLK_FREQ / 10;

    localparam integer DUR_WIDTH = $clog2(127 * DECISECOND_CYCLES + 1);
    localparam integer HALF_CNT_WIDTH = (HALF_PERIOD_CYCLES <= 1) ? 1 : $clog2(HALF_PERIOD_CYCLES);

    logic        active;
    logic [DUR_WIDTH-1:0] dur_cnt;
    logic [HALF_CNT_WIDTH-1:0] half_cnt;

    always_ff @(posedge clk) begin
        if (!nrst) begin
            active     <= 1'b0;
            buzzer_out <= 1'b0;
            dur_cnt    <= '0;
            half_cnt   <= '0;
        end else if (buzzer_pulse && (buzzer_length != 7'd0)) begin
            active     <= 1'b1;
            dur_cnt    <= DUR_WIDTH'(buzzer_length) * DUR_WIDTH'(DECISECOND_CYCLES);
            half_cnt   <= '0;
            // buzzer_out unchanged on re-trigger (spec: no glitch to sustained low)
        end else if (active) begin
            if (dur_cnt == 1) begin
                // Last active cycle: drive low; skip half-period advance (clean single assignment per cycle).
                dur_cnt    <= '0;
                active     <= 1'b0;
                buzzer_out <= 1'b0;
                half_cnt   <= '0;
            end else begin
                if (half_cnt == HALF_CNT_WIDTH'(HALF_PERIOD_CYCLES - 1)) begin
                    half_cnt   <= '0;
                    buzzer_out <= ~buzzer_out;
                end else begin
                    half_cnt <= half_cnt + 1'b1;
                end
                dur_cnt <= dur_cnt - 1'b1;
            end
        end
    end

endmodule