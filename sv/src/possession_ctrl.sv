// possession_ctrl.sv
// SystemVerilog module: Tracks which team has possession.
// Inputs: clk, nrst (active-low reset), possession_toggle_pulse (button), load
// Outputs: possession_state (0 or 1), possession_leds (one-hot for each team)

module possession_ctrl (
    input  logic clk,
    input  logic nrst,                  // Active-low reset
    input  logic possession_toggle_pulse, // Button to switch possession
    input  logic load,                  // Load possession_load_value when high
    input  logic possession_load_value, // 0 or 1: possession value to load
    output logic possession_state,       // 0 or 1: which team
    output logic [1:0] possession_leds   // One-hot: [team2, team1]
);

    always_ff @(posedge clk or negedge nrst) begin
        if (!nrst) begin
            possession_state <= 1'b0;
        end else if (load) begin
            possession_state <= possession_load_value;
        end else if (possession_toggle_pulse) begin
            possession_state <= ~possession_state;
        end
    end

    always_comb begin
        case (possession_state)
            1'b0: possession_leds = 2'b01; // Team 1
            1'b1: possession_leds = 2'b10; // Team 2
            default: possession_leds = 2'b00;
        endcase
    end

endmodule
