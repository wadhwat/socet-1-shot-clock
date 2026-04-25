`timescale 1ns/1ps

module main_driver_tb;

	logic clk;
	logic tick_2640Hz;
	logic n_rst;

	logic [3:0] period_led;
	logic [1:0] pos_led;

	logic [7:0] gc_ss1;
	logic [7:0] gc_ss2;
	logic [7:0] gc_ss3;
	logic [7:0] gc_ss4;

	logic [7:0] scr_ss1;
	logic [7:0] scr_ss2;
	logic [7:0] scr_ss3;
	logic [7:0] scr_ss4;

	logic scr_colon;

	logic [7:0] sc_ss1;
	logic [7:0] sc_ss2;
	logic [7:0] sc_ss3;
	logic [7:0] sc_ss4;

	logic sc_colon;
	logic buzzer_in;

	logic [7:0] main_segments_pin_out;
	logic [3:0] decoder_pin;
	logic gc_colon;
	logic sc_colon_out;
	logic scr_colon_out;
	logic [3:0] period_led_out;
	logic [1:0] pos_led_out;
	logic buzzer_out;

	int err_count;

	main_driver dut (
		.clk(clk),
		.tick_2640Hz(tick_2640Hz),
		.n_rst(n_rst),
		.period_led(period_led),
		.pos_led(pos_led),
		.gc_ss1(gc_ss1),
		.gc_ss2(gc_ss2),
		.gc_ss3(gc_ss3),
		.gc_ss4(gc_ss4),
		.scr_ss1(scr_ss1),
		.scr_ss2(scr_ss2),
		.scr_ss3(scr_ss3),
		.scr_ss4(scr_ss4),
		.scr_colon(scr_colon),
		.sc_ss1(sc_ss1),
		.sc_ss2(sc_ss2),
		.sc_ss3(sc_ss3),
		.sc_ss4(sc_ss4),
		.sc_colon(sc_colon),
		.buzzer_in(buzzer_in),
		.main_segments_pin_out(main_segments_pin_out),
		.decoder_pin(decoder_pin),
		.gc_colon(gc_colon),
		.sc_colon_out(sc_colon_out),
		.scr_colon_out(scr_colon_out),
		.period_led_out(period_led_out),
		.pos_led_out(pos_led_out),
		.buzzer_out(buzzer_out)
	);

	always #5 clk = ~clk;

	task automatic check_bits(
		input string what,
		input logic [31:0] got,
		input logic [31:0] exp
	);
		if (got !== exp) begin
			err_count++;
			$error("FAIL %s: got=%0h expected=%0h @ %0t", what, got, exp, $time);
		end
	endtask

	task automatic pulse_tick;
		begin
			@(negedge clk);
			tick_2640Hz = 1'b1;
			@(posedge clk);
			#1;
			@(negedge clk);
			tick_2640Hz = 1'b0;
		end
	endtask

	task automatic check_current_mux(
		input logic [7:0] exp_seg
	);
		begin
			#1;
			check_bits($sformatf("main_segments for decoder=%0d", decoder_pin), main_segments_pin_out, exp_seg);
		end
	endtask

	initial begin
		$dumpfile("main_driver_tb.vcd");
		$dumpvars(0, main_driver_tb);

		clk = 1'b0;
		tick_2640Hz = 1'b0;
		n_rst = 1'b0;
		err_count = 0;

		period_led = 4'b1010;
		pos_led = 2'b10;

		gc_ss1 = 8'h11;
		gc_ss2 = 8'h22;
		gc_ss3 = 8'h33;
		gc_ss4 = 8'h44;

		scr_ss1 = 8'h55;
		scr_ss2 = 8'h66;
		scr_ss3 = 8'h77;
		scr_ss4 = 8'h88;

		scr_colon = 1'b1;

		sc_ss1 = 8'h99;
		sc_ss2 = 8'hAA;
		sc_ss3 = 8'hBB;
		sc_ss4 = 8'hCC;

		sc_colon = 1'b0;
		buzzer_in = 1'b1;

		// While reset is asserted, decoder is zeroed and segment output is forced off.
		#1;
		check_bits("decoder reset value", decoder_pin, 4'd0);
		check_bits("segment output during reset", main_segments_pin_out, 8'hFF);

		// Pass-through outputs should mirror their inputs.
		check_bits("gc_colon constant", gc_colon, 1'b1);
		check_bits("sc_colon passthrough", sc_colon_out, sc_colon);
		check_bits("scr_colon passthrough", scr_colon_out, scr_colon);
		check_bits("period leds passthrough", period_led_out, period_led);
		check_bits("pos leds passthrough", pos_led_out, pos_led);
		check_bits("buzzer passthrough", buzzer_out, buzzer_in);

		// Release reset and validate all mux selections.
		@(negedge clk);
		n_rst = 1'b1;
		#1;
		check_bits("decoder starts at 0 after reset release", decoder_pin, 4'd0);
		check_current_mux(gc_ss1);
		pulse_tick();

		check_bits("decoder at 1", decoder_pin, 4'd1);
		check_current_mux(gc_ss2);
		pulse_tick();

		check_bits("decoder at 2", decoder_pin, 4'd2);
		check_current_mux(gc_ss3);
		pulse_tick();

		check_bits("decoder at 3", decoder_pin, 4'd3);
		check_current_mux(gc_ss4);
		pulse_tick();

		check_bits("decoder at 4", decoder_pin, 4'd4);
		check_current_mux(scr_ss1);
		pulse_tick();

		check_bits("decoder at 5", decoder_pin, 4'd5);
		check_current_mux(scr_ss2);
		pulse_tick();

		check_bits("decoder at 6", decoder_pin, 4'd6);
		check_current_mux(scr_ss3);
		pulse_tick();

		check_bits("decoder at 7", decoder_pin, 4'd7);
		check_current_mux(scr_ss4);
		pulse_tick();

		check_bits("decoder at 8", decoder_pin, 4'd8);
		check_current_mux(sc_ss1);
		pulse_tick();

		check_bits("decoder at 9", decoder_pin, 4'd9);
		check_current_mux(sc_ss2);
		pulse_tick();

		check_bits("decoder at 10", decoder_pin, 4'd10);
		check_current_mux(sc_ss3);
		pulse_tick();

		check_bits("decoder wraps from 10 to 0", decoder_pin, 4'd0);
		check_current_mux(gc_ss1);

		// Decoder should only advance when tick_2640Hz is asserted.
		@(posedge clk);
		#1;
		check_bits("decoder holds without tick", decoder_pin, 4'd0);

		pulse_tick();
		check_bits("decoder increments to 1", decoder_pin, 4'd1);
		pulse_tick();
		check_bits("decoder increments to 2", decoder_pin, 4'd2);

		repeat (8) pulse_tick();
		check_bits("decoder reaches 10", decoder_pin, 4'd10);

		pulse_tick();
		check_bits("decoder wraps to 0", decoder_pin, 4'd0);

		// Asynchronous reset should clear decoder immediately.
		pulse_tick();
		check_bits("decoder advanced before async reset", decoder_pin, 4'd1);
		#1;
		n_rst = 1'b0;
		#1;
		check_bits("decoder async reset", decoder_pin, 4'd0);
		check_bits("segment output back to reset value", main_segments_pin_out, 8'hFF);

		if (err_count == 0)
			$display("PASS main_driver_tb");
		else
			$display("FAIL main_driver_tb errors=%0d", err_count);

		$finish;
	end

endmodule
