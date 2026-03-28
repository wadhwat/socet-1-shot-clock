// buzzer_ctrl.sv
// SystemVerilog module: Generates a fixed-duration buzzer output when a timer expires.
// Inputs: clk, nrst (active-low reset), trigger (pulse)
// Output: buzzer (drive signal)

module buzzer_ctrl (
    input  logic clk,
    input  logic nrst,         // Active-low reset
    input  logic trigger,      // Pulse to start buzzer
    output logic buzzer        // Buzzer drive signal
);

    // Parameter: number of clock cycles for buzzer duration
    parameter BUZZER_CYCLES = 50_000_000; // Example: 1 second at 50 MHz

    logic [$clog2(BUZZER_CYCLES)-1:0] counter;
    logic active;

    always_ff @(posedge clk or negedge nrst) begin
        if (!nrst) begin
            counter <= 0;
            active  <= 0;
        end else if (trigger && !active) begin
            active  <= 1;
            counter <= BUZZER_CYCLES - 1;
        end else if (active) begin
            if (counter == 0)
                active <= 0;
            else
                counter <= counter - 1;
        end
    end

    assign buzzer = active;

endmodule
