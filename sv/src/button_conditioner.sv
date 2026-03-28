module button_conditioner #(
    parameter integer STREAK_REQUIRED = 5  // Number of consecutive highs needed
)(
    input  wire clk,
    input  logic nrst,
    input  logic tick_1kHz,               // Clean 1 kHz sample tick from tick_generator
    input  logic raw_button_signal,
    output logic conditioned_button_signal
);

localparam integer STREAK_WIDTH = (STREAK_REQUIRED > 0) ? $clog2(STREAK_REQUIRED + 1) : 1;
reg [STREAK_WIDTH-1:0] high_streak_count; // Tracks consecutive highs

always @(posedge clk or negedge nrst) begin
    if (!nrst) begin
        high_streak_count <= '0;
        conditioned_button_signal <= 1'b0;
    end else if (tick_1kHz) begin
        // Compute next streak with saturation at STREAK_REQUIRED to avoid overflow
        if (raw_button_signal) begin
            if (high_streak_count < STREAK_REQUIRED[STREAK_WIDTH-1:0]) begin
                high_streak_count <= high_streak_count + 1'b1;
            end
        end else begin
            high_streak_count <= '0;
        end

        // Output goes high once we have the required run of highs; drops as soon as the button reads low
        if (raw_button_signal && (high_streak_count + 1'b1 >= STREAK_REQUIRED[STREAK_WIDTH-1:0])) begin
            conditioned_button_signal <= 1'b1;
        end else if (!raw_button_signal) begin
            conditioned_button_signal <= 1'b0;
        end
    end
end

endmodule