module tick_generator #(
    parameter integer CLK_FREQ_HZ = 100_000_000, // Clock frequency in Hz REPLACE WITH ACTUAL CLOCK FREQ
    parameter integer TICK_FREQ_HZ = 10,         // Desired main tick frequency in Hz
    parameter integer CONDITIONED = 1_000        // Conditioned tick freq 1,000 Hz 
) (
    input wire clk,   // Input clock signal
    input wire rst_n, // Active-low reset signal
    output reg tick_10Hz,  // Output tick signal
    output reg tick_1kHz // Output conditioned tick signal
);

    localparam integer COUNT_MAX = CLK_FREQ_HZ / TICK_FREQ_HZ; // Number of clock cycles per tick
    localparam integer CONDITIONED_COUNT_MAX = (CLK_FREQ_HZ / CONDITIONED > 0) ? (CLK_FREQ_HZ / CONDITIONED) : 1; // Guard against divide-by-zero

    reg [31:0] counter;             // Counter to keep track of main tick cycles
    reg [31:0] conditioned_counter; // Counter for conditioned tick

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            conditioned_counter <= 0;
            tick_10Hz <= 0;
            tick_1kHz <= 0;
        end else begin
            // Main tick generation
            if (counter >= COUNT_MAX - 1) begin
                counter <= 0;
                tick_10Hz <= 1;
            end else begin
                counter <= counter + 1;
                tick_10Hz <= 0;
            end

            // Conditioned tick generation using an independent divider
            if (conditioned_counter >= CONDITIONED_COUNT_MAX - 1) begin
                conditioned_counter <= 0;
                tick_1kHz <= 1;
            end else begin
                conditioned_counter <= conditioned_counter + 1;
                tick_1kHz <= 0;
            end
        end
    end

endmodule