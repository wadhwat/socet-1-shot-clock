// period_ctrl.sv 
// SystemVerilog version of period control module for 4-period shot clock display
// Inputs: clk, n_rst (active-low reset), increment (advance period)
// Outputs: period_state (2 bits), period_leds (one-hot for each period)

module period_ctrl (
    input  logic clk,
    input  logic n_rst,           // Active-low reset
    input  logic increment,      // Pulse to advance period
    output logic [1:0] period_state, // 2 bits: 0-3 for 4 periods
    output logic [3:0] period_leds   // One-hot LED for each period
);

always_ff @(posedge clk or negedge n_rst) begin
    if (!n_rst) begin
        period_state <= 2'b00;
    end else if (increment) begin
        if (period_state < 2'b11)
            period_state <= period_state + 1'b1;
        // Optionally, hold at 3 or wrap to 0
    end
end

always_comb begin
    case (period_state)
        2'b00: period_leds = 4'b0001;
        2'b01: period_leds = 4'b0010;
        2'b10: period_leds = 4'b0100;
        2'b11: period_leds = 4'b1000;
        default: period_leds = 4'b0000;
    endcase
end

endmodule
