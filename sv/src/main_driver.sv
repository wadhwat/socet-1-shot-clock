module main_driver (
    input logic clk, tick_2640Hz, n_rst,
    input logic [3:0] period_led, //MSB is quadrant 1
    input logic home_led, away_led,
    input logic [7:0] gc_ss1, gc_ss2, gc_ss3, gc_ss4,
    input logic gc_colon,
    input logic [7:0] scr_ss1, scr_ss2, scr_ss3, scr_ss4,
    input logic scr_colon,
    input logic [7:0] sc_ss1, sc_ss2, sc_ss3, sc_ss4,
    input logic sc_colon,
    input logic buzzer_in,

    output logic [7:0] main_segments_pin_out,
    output logic [3:0] decoder_pin, //controls the decoder to select correct ss
    output logic gc_colon_out,
    output logic sc_colon_out, scr_colon_out,
    output logic [3:0] period_led_out,
    output logic [1:0] pos_led_out,
    output logic buzzer_out
);

    assign gc_colon_out = gc_colon; 
    assign sc_colon_out = sc_colon; 
    assign scr_colon_out = scr_colon; 
    assign period_led_out = period_led;
    assign pos_led_out = {away_led, home_led};
    assign buzzer_out = buzzer_in;
    //MIGHT!! need to add assign to XOR the ss before they leave to make them work with Anode.

    //DECODER LOOP: 0 -> 10
    always_ff @(posedge clk or negedge n_rst) begin
        if (!n_rst) begin
            decoder_pin <= 4'd0;
        end else begin
            if (tick_2640Hz) begin
                if (decoder_pin == 4'd10)
                    decoder_pin <= 4'd0;
                else
                    decoder_pin <= decoder_pin + 1'b1;
            end
        end
    end

    //OUTPUT LOGIC
    always_comb begin
        if (!n_rst)
            main_segments_pin_out = 8'b11111111;
        else begin
            case (decoder_pin)
                4'd0: main_segments_pin_out = gc_ss1;
                4'd1: main_segments_pin_out = gc_ss2;
                4'd2: main_segments_pin_out = gc_ss3;
                4'd3: main_segments_pin_out = gc_ss4;
                4'd4: main_segments_pin_out = scr_ss1;
                4'd5: main_segments_pin_out = scr_ss2;
                4'd6: main_segments_pin_out = scr_ss3;
                4'd7: main_segments_pin_out = scr_ss4;
                //4'd8: main_segments_pin_out = sc_ss1;
                4'd9: main_segments_pin_out = sc_ss2;
                4'd10: main_segments_pin_out = sc_ss3;
                4'd11: {main_segments_pin_out} = {1'b0, sc_ss4};
                default: main_segments_pin_out = 8'b00000110; //E for error
            endcase
        end
    end

endmodule
