module button_conditioner #(
    parameter integer N_BUTTONS = 5,
    parameter integer STREAK_REQUIRED = 6  // Total consecutive 1 kHz highs required (initial high + 5 more)
)(
    input  logic clk,
    input  logic n_rst,
    input  logic tick_1kHz,               // Clean 1 kHz sample tick from tick_generator
    input  logic [N_BUTTONS-1:0] raw_buttons,
    output logic [N_BUTTONS-1:0] conditioned_buttons
);

reg [3:0] streak_count [N_BUTTONS-1:0];
reg       pressed_seen [N_BUTTONS-1:0]; // Blocks repeat until release

integer i;

always @(posedge clk or negedge n_rst) begin
    if (!n_rst) begin
        for (i = 0; i < N_BUTTONS; i = i + 1) begin
            streak_count[i] <= '0;
            pressed_seen[i] <= 1'b0;
            conditioned_buttons[i] <= 1'b0;
        end
    end else if (tick_1kHz) begin
        for (i = 0; i < N_BUTTONS; i = i + 1) begin
            // Default to no pulse this tick; set high only when firing a one-shot
            conditioned_buttons[i] <= 1'b0;

            // Compute next streak with saturation at STREAK_REQUIRED to avoid overflow
            if (raw_buttons[i]) begin
                if (streak_count[i] < STREAK_REQUIRED[3:0]) begin
                    streak_count[i] <= streak_count[i] + 1'b1;
                end

                // Fire a one-cycle pulse once per press when streak is met
                if ((streak_count[i] + 1'b1 >= STREAK_REQUIRED[3:0]) && !pressed_seen[i]) begin
                    conditioned_buttons[i] <= 1'b1;
                    pressed_seen[i]        <= 1'b1;
                end
            end else begin
                streak_count[i] <= '0;
                pressed_seen[i]  <= 1'b0;
                conditioned_buttons[i] <= 1'b0;
            end
        end
    end else begin
        // No sampling this cycle; keep outputs low so pulses are single-cycle on clk domain
        for (i = 0; i < N_BUTTONS; i = i + 1) begin
            conditioned_buttons[i] <= 1'b0;
        end
    end
end

endmodule