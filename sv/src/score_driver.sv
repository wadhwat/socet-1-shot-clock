module score_driver (
	input logic [7:0] home_score,
	input logic [7:0] away_score,
	output logic [7:0] scr_ss1,
	output logic [7:0] scr_ss2,
	output logic [7:0] scr_ss3,
	output logic [7:0] scr_ss4
);

	logic [7:0] home_score_limited;
	logic [7:0] away_score_limited;
	logic [3:0] home_tens;
	logic [3:0] home_ones;
	logic [3:0] away_tens;
	logic [3:0] away_ones;

	function automatic logic [7:0] digit_to_sevenseg_anode(input logic [3:0] digit);
		logic [7:0] cathode_code;
		begin
			// Bit order: dp g f e d c b a (active-high/common-cathode form)
			case (digit)
				4'd0: cathode_code = 8'b00111111;
				4'd1: cathode_code = 8'b00000110;
				4'd2: cathode_code = 8'b01011011;
				4'd3: cathode_code = 8'b01001111;
				4'd4: cathode_code = 8'b01100110;
				4'd5: cathode_code = 8'b01101101;
				4'd6: cathode_code = 8'b01111101;
				4'd7: cathode_code = 8'b00000111;
				4'd8: cathode_code = 8'b01111111;
				4'd9: cathode_code = 8'b01101111;
				default: cathode_code = 8'b01111001; // E
			endcase

			// Convert to active-low/common-anode encoding.
			digit_to_sevenseg_anode = ~cathode_code;
		end
	endfunction

	always_comb begin
		// Score display supports two decimal digits per team.
		home_score_limited = (home_score > 8'd99) ? 8'd99 : home_score;
		away_score_limited = (away_score > 8'd99) ? 8'd99 : away_score;

		home_tens = home_score_limited / 8'd10;
		home_ones = home_score_limited % 8'd10;
		away_tens = away_score_limited / 8'd10;
		away_ones = away_score_limited % 8'd10;

		// Assumed display order in main_driver scan: away tens/ones, then home tens/ones.
		scr_ss1 = digit_to_sevenseg_anode(away_tens);
		scr_ss2 = digit_to_sevenseg_anode(away_ones);
		scr_ss3 = digit_to_sevenseg_anode(home_tens);
		scr_ss4 = digit_to_sevenseg_anode(home_ones);
	end

endmodule
