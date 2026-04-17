module main_driver (
    input logic clk, tick_12Hz, n_rst,
    input [3:0] quad_led, //MSB is quadrant 1
    input [1:0] pos_led, //MSB is Home
    input [7:0] gc_ss1, gc_ss2, gc_ss3, gc_ss4,
    input gc_colon,
    input [7:0] scr_ss1, scr_ss2, scr_ss3, scr_ss4,
    input scr_colon,
    input [7:0] sc_ss1, sc_ss2, sc_ss3, sc_ss4,
    input sc_colon,
    output [7:0] main_segments_pin_out,
    output [3:0] decoder_pin //controls the decoder to select correct ss
);
    logic [6:0] ss1, ss2, ss3;
    logic colon1, colon2, colon3;

    always_ff @(posedge clk or negedge n_rst) begin
        if (!n_rst) begin
            main_segments_pin_out <= 8'd0;
            decoder_pin <= 4'd0;
        end else begin
            if (tick_12Hz) begin
                main_segments_pin_out <= {colon1, ss1}; //MSB is colon, then 7 bits of ss1
                decoder_pin <= decoder_pin + 1'b1; //Cycle through 0-11 to select which digit to update
            end else begin
                main_segments_pin_out <= main_segments_pin_out; //Hold the value steady between updates
                decoder_pin <= decoder_pin; //Hold the value steady between updates
            end
        end
    end

    always_comb begin
        case (decoder_pin)
            4'd0: {ss1, colon1} = {gc_ss1, gc_colon};
            4'd1: {ss1, colon1} = {gc_ss2, gc_colon};
            4'd2: {ss1, colon1} = {gc_ss3, gc_colon};
            4'd3: {ss1, colon1} = {gc_ss4, gc_colon};
            4'd4: {ss1, colon1} = {scr_ss1, scr_colon};
            4'd5: {ss1, colon1} = {scr_ss2, scr_colon};
            4'd6: {ss1, colon1} = {scr_ss3, scr_colon};
            4'd7: {ss1, colon1} = {scr_ss4, scr_colon};
            4'd8: {ss1, colon1} = {sc_ss1, sc_colon};
            4'd9: {ss1, colon1} = {sc_ss2, sc_colon};
            4'd10: {ss1, colon1} = {sc_ss3, sc_colon};
            4'd11: {ss1, colon1} = {sc_ss4, sc_colon};
            default: {ss1, colon1} = 8'd0;
        endcase
    end

endmodule
