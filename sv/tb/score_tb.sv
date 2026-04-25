`timescale 1ns/1ps

module score_tb;

	logic clk;
	logic nrst;
	logic plus_one_possession_pulse;
	logic minus_one_possession_pulse;
	logic possession_state;

	logic [7:0] home_score;
	logic [7:0] away_score;
	logic [7:0] scr_ss1;
	logic [7:0] scr_ss2;
	logic [7:0] scr_ss3;
	logic [7:0] scr_ss4;

	score_tracker u_score_tracker (
		.clk(clk),
		.nrst(nrst),
		.plus_one_possession_pulse(plus_one_possession_pulse),
		.minus_one_possession_pulse(minus_one_possession_pulse),
		.possession_state(possession_state),
		.home_score(home_score),
		.away_score(away_score)
	);

	score_driver u_score_driver (
		.home_score(home_score),
		.away_score(away_score),
		.scr_ss1(scr_ss1),
		.scr_ss2(scr_ss2),
		.scr_ss3(scr_ss3),
		.scr_ss4(scr_ss4)
	);

	always #5 clk = ~clk;

	function automatic logic [7:0] digit_to_sevenseg_anode(input logic [3:0] digit);
		logic [7:0] cathode_code;
		begin
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
				default: cathode_code = 8'b01111001;
			endcase

			digit_to_sevenseg_anode = ~cathode_code;
		end
	endfunction

	task automatic apply_plus(input logic team);
		begin
			@(negedge clk);
			possession_state = team;
			plus_one_possession_pulse = 1'b1;
			minus_one_possession_pulse = 1'b0;

			@(negedge clk);
			plus_one_possession_pulse = 1'b0;
		end
	endtask

	task automatic apply_minus(input logic team);
		begin
			@(negedge clk);
			possession_state = team;
			plus_one_possession_pulse = 1'b0;
			minus_one_possession_pulse = 1'b1;

			@(negedge clk);
			minus_one_possession_pulse = 1'b0;
		end
	endtask

	task automatic apply_plus_and_minus(input logic team);
		begin
			@(negedge clk);
			possession_state = team;
			plus_one_possession_pulse = 1'b1;
			minus_one_possession_pulse = 1'b1;

			@(negedge clk);
			plus_one_possession_pulse = 1'b0;
			minus_one_possession_pulse = 1'b0;
		end
	endtask

	task automatic check_state(
		input logic [7:0] expected_home,
		input logic [7:0] expected_away,
		input string label
	);
		logic [7:0] expected_scr_ss1;
		logic [7:0] expected_scr_ss2;
		logic [7:0] expected_scr_ss3;
		logic [7:0] expected_scr_ss4;
		logic [7:0] home_limited;
		logic [7:0] away_limited;
		logic [3:0] home_tens;
		logic [3:0] home_ones;
		logic [3:0] away_tens;
		logic [3:0] away_ones;
		logic home_overflow;
		logic away_overflow;
		begin
			#1;

			if (home_score !== expected_home) begin
				$error("%s: home_score expected %0d got %0d", label, expected_home, home_score);
				$fatal;
			end
			if (away_score !== expected_away) begin
				$error("%s: away_score expected %0d got %0d", label, expected_away, away_score);
				$fatal;
			end

			home_overflow = expected_home > 8'd99;
			away_overflow = expected_away > 8'd99;
			home_limited = home_overflow ? 8'd99 : expected_home;
			away_limited = away_overflow ? 8'd99 : expected_away;

			home_tens = home_limited / 8'd10;
			home_ones = home_limited % 8'd10;
			away_tens = away_limited / 8'd10;
			away_ones = away_limited % 8'd10;

			expected_scr_ss1 = digit_to_sevenseg_anode(away_tens);
			expected_scr_ss2 = digit_to_sevenseg_anode(away_ones);
			expected_scr_ss3 = digit_to_sevenseg_anode(home_tens);
			expected_scr_ss4 = digit_to_sevenseg_anode(home_ones);

			if (away_overflow)
				expected_scr_ss2[7] = 1'b0;
			if (home_overflow)
				expected_scr_ss4[7] = 1'b0;

			if (scr_ss1 !== expected_scr_ss1) begin
				$error("%s: scr_ss1 expected %b got %b", label, expected_scr_ss1, scr_ss1);
				$fatal;
			end
			if (scr_ss2 !== expected_scr_ss2) begin
				$error("%s: scr_ss2 expected %b got %b", label, expected_scr_ss2, scr_ss2);
				$fatal;
			end
			if (scr_ss3 !== expected_scr_ss3) begin
				$error("%s: scr_ss3 expected %b got %b", label, expected_scr_ss3, scr_ss3);
				$fatal;
			end
			if (scr_ss4 !== expected_scr_ss4) begin
				$error("%s: scr_ss4 expected %b got %b", label, expected_scr_ss4, scr_ss4);
				$fatal;
			end

			$display("PASS: %s (home=%0d away=%0d)", label, home_score, away_score);
		end
	endtask

	initial begin
		clk = 1'b0;
		nrst = 1'b0;
		plus_one_possession_pulse = 1'b0;
		minus_one_possession_pulse = 1'b0;
		possession_state = 1'b0;

		// Verify asynchronous reset behavior and initial decoded output.
		#1;
		check_state(8'd0, 8'd0, "reset asserted");

		repeat (2) @(negedge clk);
		nrst = 1'b1;
		@(negedge clk);
		check_state(8'd0, 8'd0, "after reset release");

		apply_plus(1'b0);
		check_state(8'd1, 8'd0, "home plus one");

		apply_plus(1'b1);
		check_state(8'd1, 8'd1, "away plus one");

		apply_plus(1'b1);
		check_state(8'd1, 8'd2, "away plus one again");

		apply_minus(1'b1);
		check_state(8'd1, 8'd1, "away minus one");

		apply_minus(1'b0);
		check_state(8'd0, 8'd1, "home minus one");

		apply_minus(1'b0);
		check_state(8'd0, 8'd1, "home underflow blocked at zero");

		apply_plus_and_minus(1'b0);
		check_state(8'd1, 8'd1, "plus dominates minus when both high");

		repeat (99) begin
			apply_plus(1'b1);
		end
		check_state(8'd1, 8'd100, "away reaches 100 (display overflow indicator)");

		repeat (254) begin
			apply_plus(1'b0);
		end
		check_state(8'd255, 8'd100, "home saturates at 255");

		apply_plus(1'b0);
		check_state(8'd255, 8'd100, "home remains saturated at 255");

		apply_minus(1'b1);
		check_state(8'd255, 8'd99, "away back below overflow threshold");

		apply_minus(1'b0);
		check_state(8'd254, 8'd99, "home decrements from saturation");

		$display("All score_tb checks passed.");
		$finish;
	end

endmodule