// possession_ctrl.sv
// SystemVerilog module: Tracks which team has possession.
// Inputs: clk, n_rst (active-low reset), possession_toggle_pulse (button)
// Outputs: possession_state (0 or 1), possession_leds (one-hot for each team)

module possession_ctrl (
    input  logic clk,
    input  logic n_rst,                  // Active-low reset
    input  logic possession_toggle_pulse, // Button to switch possession
    output logic possession_state,       // 0 is home team, 1 is away team
    output logic home_led,   
    output logic away_led
);

    always_ff @(posedge clk or negedge n_rst) begin
        if (!n_rst) begin
            possession_state <= 1'b0;
        end else if (possession_toggle_pulse) begin
            possession_state <= ~possession_state;
        end
    end

    always_comb begin
        case (possession_state)
            1'b0: {away_led, home_led} = 2'b01; // Home team
            1'b1: {away_led, home_led} = 2'b10; // Away team
            default: {away_led, home_led} = 2'b00;
        endcase
    end

endmodule
