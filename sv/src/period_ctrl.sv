// period_ctrl.sv 
// SystemVerilog version of period control module for 4-period shot clock display
// Inputs: clk, nrst (active-low reset), increment (advance period), load
// Outputs: period_state (2 bits), period_leds (one-hot for each period)

module period_ctrl (
    input  logic clk,
    input  logic nrst,           // Active-low reset
    input  logic increment,      // Pulse to advance period
    input  logic load,           // Load period_load_value when high
    input  logic [1:0] period_load_value, // 0-3 period value to load
    output logic [1:0] period_state, // 2 bits: 0-3 for 4 periods
    output logic [3:0] period_leds   // One-hot LED for each period
);

always_ff @(posedge clk or negedge nrst) begin
    if (!nrst) begin
        period_state <= 2'b00;
    end else if (load) begin
        period_state <= period_load_value;
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
