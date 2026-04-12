module brightness_test #(
    parameter int DEBOUNCE_CYCLES = 2_000_000
) (
    input  logic clk_100mhz,
    input  logic rst_n,
    input  logic btn_cycle,
    output logic [3:0] disp_sel,
    output logic [7:0] seg
);

    // ============================================================
    // Frequency choices: full 12-slot frame refresh frequency
    // ============================================================
    localparam int NUM_FREQS = 5;

    localparam int FRAME_HZ_0 = 30;
    localparam int FRAME_HZ_1 = 60;
    localparam int FRAME_HZ_2 = 120;
    localparam int FRAME_HZ_3 = 240;
    localparam int FRAME_HZ_4 = 480;

    // ============================================================
    // Simple button debounce + edge detect
    // ============================================================

    logic btn_sync_0, btn_sync_1;
    logic btn_stable;
    logic btn_stable_prev;
    logic btn_rise;

    logic [$clog2(DEBOUNCE_CYCLES):0] db_count;
    logic btn_sampled;

    always_ff @(posedge clk_100mhz or negedge rst_n) begin
        if (!rst_n) begin
            btn_sync_0      <= 1'b0;
            btn_sync_1      <= 1'b0;
            btn_sampled     <= 1'b0;
            btn_stable      <= 1'b0;
            btn_stable_prev <= 1'b0;
            db_count        <= '0;
        end else begin
            // 2-flop synchronizer
            btn_sync_0 <= btn_cycle;
            btn_sync_1 <= btn_sync_0;

            btn_stable_prev <= btn_stable;

            if (btn_sync_1 == btn_sampled) begin
                db_count <= '0;
            end else begin
                if (db_count == DEBOUNCE_CYCLES - 1) begin
                    btn_sampled <= btn_sync_1;
                    btn_stable  <= btn_sync_1;
                    db_count    <= '0;
                end else begin
                    db_count <= db_count + 1'b1;
                end
            end
        end
    end

    assign btn_rise = btn_stable & ~btn_stable_prev;

    // ============================================================
    // Frequency selection
    // ============================================================
    logic [2:0] freq_sel;
    logic [15:0] frame_hz;

    always_ff @(posedge clk_100mhz or negedge rst_n) begin
        if (!rst_n) begin
            freq_sel <= 3'd0;
        end else if (btn_rise) begin
            if (freq_sel == NUM_FREQS - 1)
                freq_sel <= 3'd0;
            else
                freq_sel <= freq_sel + 1'b1;
        end
    end

    always_comb begin
        unique case (freq_sel)
            3'd0: frame_hz = FRAME_HZ_0;
            3'd1: frame_hz = FRAME_HZ_1;
            3'd2: frame_hz = FRAME_HZ_2;
            3'd3: frame_hz = FRAME_HZ_3;
            3'd4: frame_hz = FRAME_HZ_4;
            default: frame_hz = FRAME_HZ_0;
        endcase
    end

    // ============================================================
    // Slot tick generator
    //
    // slot_rate = frame_hz * 12
    // slot_ticks = 100_000_000 / slot_rate
    // ============================================================
    logic [31:0] slot_ticks;
    logic [31:0] tick_count;
    logic        slot_tick;

    always_comb begin
        slot_ticks = 100_000_000 / (frame_hz * 12);
    end

    always_ff @(posedge clk_100mhz or negedge rst_n) begin
        if (!rst_n) begin
            tick_count <= 32'd0;
            slot_tick  <= 1'b0;
        end else begin
            if (tick_count >= slot_ticks - 1) begin
                tick_count <= 32'd0;
                slot_tick  <= 1'b1;
            end else begin
                tick_count <= tick_count + 1'b1;
                slot_tick  <= 1'b0;
            end
        end
    end

    // ============================================================
    // 12-slot scan counter
    // ============================================================
    logic [3:0] slot_idx;

    always_ff @(posedge clk_100mhz or negedge rst_n) begin
        if (!rst_n) begin
            slot_idx <= 4'd0;
        end else if (slot_tick) begin
            if (slot_idx == 4'd11)
                slot_idx <= 4'd0;
            else
                slot_idx <= slot_idx + 1'b1;
        end
    end

    assign disp_sel = slot_idx;

    // ============================================================
    // Convert frame_hz to 4 decimal digits
    // ============================================================
    logic [3:0] digit_thousands, digit_hundreds, digit_tens, digit_ones;
    logic [3:0] active_digit;
    logic       active_dp;

    always_comb begin
        digit_thousands = (frame_hz / 1000) % 10;
        digit_hundreds  = (frame_hz / 100)  % 10;
        digit_tens      = (frame_hz / 10)   % 10;
        digit_ones      = frame_hz % 10;
    end

    // ============================================================
    // Map slots to displayed content
    // Slots 0..3 show the four digits.
    // Slots 4..11 are blank.
    // ============================================================
    always_comb begin
        active_digit = 4'd0;
        active_dp    = 1'b0;

        unique case (slot_idx)
            4'd0: begin
                active_digit = digit_thousands;
                active_dp    = 1'b0;
            end
            4'd1: begin
                active_digit = digit_hundreds;
                active_dp    = 1'b0;
            end
            4'd2: begin
                active_digit = digit_tens;
                active_dp    = 1'b0;
            end
            4'd3: begin
                active_digit = digit_ones;
                active_dp    = 1'b0;
            end
            default: begin
                active_digit = 4'd0;
                active_dp    = 1'b0;
            end
        endcase
    end

    // ============================================================
    // 7-segment decode
    //
    // seg = {dp,g,f,e,d,c,b,a}
    // ============================================================
    function automatic logic [7:0] seg_decode(
        input logic [3:0] digit,
        input logic       dp
    );
        logic [7:0] s;
        begin
            unique case (digit)
                4'd0: s[6:0] = 7'b0111111;
                4'd1: s[6:0] = 7'b0000110;
                4'd2: s[6:0] = 7'b1011011;
                4'd3: s[6:0] = 7'b1001111;
                4'd4: s[6:0] = 7'b1100110;
                4'd5: s[6:0] = 7'b1101101;
                4'd6: s[6:0] = 7'b1111101;
                4'd7: s[6:0] = 7'b0000111;
                4'd8: s[6:0] = 7'b1111111;
                4'd9: s[6:0] = 7'b1101111;
                default: s[6:0] = 7'b0000000;
            endcase

            s[7] = dp; // decimal point
            return s;
        end
    endfunction

    // Blank unused slots
    always_comb begin
        if (slot_idx <= 4'd3)
            seg = ~seg_decode(active_digit, active_dp);
        else
            seg = 8'b11111111; // all segments off
    end

endmodule