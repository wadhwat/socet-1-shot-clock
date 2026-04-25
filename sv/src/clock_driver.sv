// Main Shot Clock Driver
module clock_driver (
    input  logic [15:0] raw_deciseconds, // Input value in deciseconds
    output logic [6:0]  seg3, seg2,      // [g, f, e, d, c, b, a] for Digits 3 and 2
    output logic [6:0]  seg1, seg0,      // [g, f, e, d, c, b, a] for Digits 1 and 0
    output logic        colon,           // Center colon signal
    output logic [3:0]  dp               // Decimal points [DP3, DP2, DP1, DP0]
);

    // Internal variables for time units
    logic [7:0] minutes, seconds, tenths;
    logic [3:0] d3_val, d2_val, d1_val, d0_val;

    // 1. Time Calculation Logic
    always_comb begin
        minutes = raw_deciseconds / 600;
        seconds = (raw_deciseconds % 600) / 10;
        tenths  = raw_deciseconds % 10;

        // 2. Format Selection (The Mode Switch)
        if (raw_deciseconds < 600) begin
            // --- MODE: SS.D (Under 1 Minute) ---
            d3_val = 4'hF;           // Blank leftmost digit
            d2_val = seconds / 10;   // Seconds Tens
            d1_val = seconds % 10;   // Seconds Ones
            d0_val = tenths;         // Deciseconds
            
            colon  = 1'b0;           // Colon OFF
            dp     = 4'b0010;        // DP1 ON (between Seconds and Tenths)
        end else begin
            // --- MODE: MM:SS (1 Minute and Over) ---
            d3_val = minutes / 10;   // Minutes Tens
            d2_val = minutes % 10;   // Minutes Ones
            d1_val = seconds / 10;   // Seconds Tens
            d0_val = seconds % 10;   // Seconds Ones
            
            colon  = 1'b1;           // Colon ON
            dp     = 4'b0000;        // All Decimal Points OFF
        end
    end

    // 3. Instantiate Decoders for the 4 Digits
    // Mapping 4-bit numbers to 7-segment patterns
    seven_seg_decoder dec3 (.bin(d3_val), .seg(seg3));
    seven_seg_decoder dec2 (.bin(d2_val), .seg(seg2));
    seven_seg_decoder dec1 (.bin(d1_val), .seg(seg1));
    seven_seg_decoder dec0 (.bin(d0_val), .seg(seg0));

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