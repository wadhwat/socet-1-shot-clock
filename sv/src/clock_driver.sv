// Main Shot Clock Driver
module clock_driver (
    input  logic [15:0] raw_deciseconds, // Input value in deciseconds
    output logic [7:0]  seg3, seg2,      // [g, f, e, d, c, b, a] for Digits 3 and 2
    output logic [7:0]  seg1, seg0,      // [g, f, e, d, c, b, a] for Digits 1 and 0
    output logic        colon            // Center colon signal
);

    // Internal variables for time units
    logic [7:0] minutes, seconds, tenths;
    logic [3:0] d3_val, d2_val, d1_val, d0_val;
    logic [6:0] seg3_core, seg2_core, seg1_core, seg0_core;
    logic       dp3, dp2, dp1, dp0;

    // 1. Time Calculation Logic
    always_comb begin
        minutes = raw_deciseconds / 600;
        seconds = (raw_deciseconds % 600) / 10;
        tenths  = raw_deciseconds % 10;

        // 2. Format Selection (The Mode Switch)
        if (raw_deciseconds < 600) begin
            // --- MODE: 0SS.D (Under 1 Minute) ---
            d3_val = 4'h0;           // Force a leading zero under 1 minute
            d2_val = seconds / 10;   // Seconds Tens
            d1_val = seconds % 10;   // Seconds Ones
            d0_val = tenths;         // Deciseconds
            
            colon  = 1'b0;           // Colon OFF
            // DP1 ON (between Seconds and Tenths)
            dp0 = 1'b0;
            dp1 = 1'b1;
            dp2 = 1'b0;
            dp3 = 1'b0;
        end else begin
            // --- MODE: MM:SS (1 Minute and Over) ---
            d3_val = minutes / 10;   // Minutes Tens
            d2_val = minutes % 10;   // Minutes Ones
            d1_val = seconds / 10;   // Seconds Tens
            d0_val = seconds % 10;   // Seconds Ones
            
            colon  = 1'b1;           // Colon ON
            
            // All Decimal Points OFF
            dp0 = 1'b0;
            dp1 = 1'b0;
            dp2 = 1'b0;
            dp3 = 1'b0;
        end
    end

    // 3. Instantiate Decoders for the 4 Digits
    // Mapping 4-bit numbers to 7-segment patterns
    seven_seg_decoder dec3 (.bin(d3_val), .seg(seg3_core));
    seven_seg_decoder dec2 (.bin(d2_val), .seg(seg2_core));
    seven_seg_decoder dec1 (.bin(d1_val), .seg(seg1_core));
    seven_seg_decoder dec0 (.bin(d0_val), .seg(seg0_core));

    assign seg3 = {dp3, seg3_core};
    assign seg2 = {dp2, seg2_core};
    assign seg1 = {dp1, seg1_core};
    assign seg0 = {dp0, seg0_core};

endmodule


// Helper Module: 7-Segment Decoder
// Logic: 1 = Segment ON (Active High)
// Bit Order: [6]=g, [5]=f, [4]=e, [3]=d, [2]=c, [1]=b, [0]=a
module seven_seg_decoder (
    input  logic [3:0] bin,
    output logic [6:0] seg
);
    always_comb begin
        case (bin)
            4'h0: seg = 7'b0111111;
            4'h1: seg = 7'b0000110;
            4'h2: seg = 7'b1011011;
            4'h3: seg = 7'b1001111;
            4'h4: seg = 7'b1100110;
            4'h5: seg = 7'b1101101;
            4'h6: seg = 7'b1111101;
            4'h7: seg = 7'b0000111;
            4'h8: seg = 7'b1111111;
            4'h9: seg = 7'b1101111;
            4'hF: seg = 7'b0000000; // Blanking (All OFF)
            default: seg = 7'b0000000;
        endcase
    end
endmodule
