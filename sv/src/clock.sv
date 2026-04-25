// Game period countdown in tenths of a second; decrements on tick_10hz when enabled.

`timescale 1ns/1ps

module clock #(
    parameter integer PERIOD_MINUTES      = 12,
    parameter integer SECONDS_PER_MINUTE  = 60,
    parameter integer TENTHS_PER_SECOND   = 10,
    parameter integer TIMER_WIDTH       = 14
) (
    input  wire                        clk,
    input  wire                        nrst,
    input  wire                        tick_10hz,
    input  wire                        enable,
    input  wire                        game_clock_load,
    input  wire [TIMER_WIDTH-1:0]      game_clock_load_value,
    output logic [TIMER_WIDTH-1:0]     current_time_value,
    output logic                       expired,
    output logic                       below_10
);

    localparam integer FULL_PERIOD_TENTHS =
        PERIOD_MINUTES * SECONDS_PER_MINUTE * TENTHS_PER_SECOND;
    // High when remaining time is strictly under 10.0 s (100 tenths).
    localparam integer BELOW_10S_TENTHS = 10 * TENTHS_PER_SECOND;

    logic [TIMER_WIDTH-1:0] time_left_tenths;

    always_ff @(posedge clk or negedge nrst) begin
        if (!nrst) begin
            time_left_tenths <= TIMER_WIDTH'(FULL_PERIOD_TENTHS);
            expired <= 1'b0;
        end else if (game_clock_load) begin
            time_left_tenths <= game_clock_load_value;
            expired <= enable && (game_clock_load_value == '0);
        end else begin
            expired <= (enable && tick_10hz && (time_left_tenths == 1));
            if (enable && tick_10hz && (time_left_tenths != 0))
                time_left_tenths <= time_left_tenths - 1'b1;
        end
    end

    assign current_time_value = time_left_tenths;
    assign below_10 = (time_left_tenths < TIMER_WIDTH'(BELOW_10S_TENTHS));

endmodule
