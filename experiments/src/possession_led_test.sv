/*
Standalone main-board possession LED smoke test.

SW0 is active-high reset. SW1 selects the test mode:
  0 = manual possession toggle with BTN0
  1 = automatic LED pattern
*/

`timescale 1ns/1ps

module possession_led_test #(
    parameter int CLK_HZ       = 100_000_000,
    parameter int DEBOUNCE_MS  = 8,
    parameter int AUTO_STEP_MS = 500
) (
    input  logic       clk,
    input  logic       rst_in,
    input  logic       auto_mode,
    input  logic       btn_possession_raw,
    output logic [1:0] possession_leds
);

    localparam int MS_TICKS = CLK_HZ / 1000;
    localparam int MS_COUNT_WIDTH = (MS_TICKS <= 1) ? 1 : $clog2(MS_TICKS);
    localparam int DEBOUNCE_WIDTH = (DEBOUNCE_MS <= 1) ? 1 : $clog2(DEBOUNCE_MS);
    localparam int AUTO_STEP_WIDTH = (AUTO_STEP_MS <= 1) ? 1 : $clog2(AUTO_STEP_MS);

    logic [MS_COUNT_WIDTH-1:0]    ms_count = '0;
    logic [DEBOUNCE_WIDTH-1:0]    debounce_count = '0;
    logic [AUTO_STEP_WIDTH-1:0]   auto_step_count = '0;
    logic [1:0]                   btn_sync = '0;
    logic [1:0]                   auto_mode_sync = '0;
    logic                         ms_tick = 1'b0;
    logic                         btn_stable = 1'b0;
    logic                         possession_toggle_pulse = 1'b0;
    logic                         possession_state = 1'b0;
    logic [2:0]                   auto_phase = 3'd0;

    always_ff @(posedge clk) begin
        btn_sync       <= {btn_sync[0], btn_possession_raw};
        auto_mode_sync <= {auto_mode_sync[0], auto_mode};
    end

    always_ff @(posedge clk) begin
        if (rst_in) begin
            ms_count <= '0;
            ms_tick  <= 1'b0;
        end else if (ms_count == MS_TICKS - 1) begin
            ms_count <= '0;
            ms_tick  <= 1'b1;
        end else begin
            ms_count <= ms_count + 1'b1;
            ms_tick  <= 1'b0;
        end
    end

    always_ff @(posedge clk) begin
        if (rst_in) begin
            debounce_count         <= '0;
            btn_stable             <= 1'b0;
            possession_toggle_pulse <= 1'b0;
        end else begin
            possession_toggle_pulse <= 1'b0;

            if (ms_tick) begin
                if (btn_sync[1] == btn_stable) begin
                    debounce_count <= '0;
                end else if (debounce_count == DEBOUNCE_MS - 1) begin
                    debounce_count <= '0;
                    btn_stable     <= btn_sync[1];

                    if (btn_sync[1])
                        possession_toggle_pulse <= 1'b1;
                end else begin
                    debounce_count <= debounce_count + 1'b1;
                end
            end
        end
    end

    always_ff @(posedge clk) begin
        if (rst_in) begin
            possession_state <= 1'b0;
        end else if (!auto_mode_sync[1] && possession_toggle_pulse) begin
            possession_state <= ~possession_state;
        end
    end

    always_ff @(posedge clk) begin
        if (rst_in || !auto_mode_sync[1]) begin
            auto_step_count <= '0;
            auto_phase      <= 3'd0;
        end else if (ms_tick) begin
            if (auto_step_count == AUTO_STEP_MS - 1) begin
                auto_step_count <= '0;

                if (auto_phase == 3'd5)
                    auto_phase <= 3'd0;
                else
                    auto_phase <= auto_phase + 1'b1;
            end else begin
                auto_step_count <= auto_step_count + 1'b1;
            end
        end
    end

    always_comb begin
        if (auto_mode_sync[1]) begin
            unique case (auto_phase)
                3'd0: possession_leds = 2'b01; // home only
                3'd1: possession_leds = 2'b00; // off gap
                3'd2: possession_leds = 2'b10; // away only
                3'd3: possession_leds = 2'b00; // off gap
                3'd4: possession_leds = 2'b11; // both on
                default: possession_leds = 2'b00;
            endcase
        end else begin
            possession_leds = possession_state ? 2'b10 : 2'b01;
        end
    end

endmodule
