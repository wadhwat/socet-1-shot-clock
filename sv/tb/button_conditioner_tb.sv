`timescale 1ns/1ps

module button_conditioner_tb;

	// Parameters
	localparam int N_BUTTONS       = 3;
	localparam int STREAK_REQUIRED = 6; // press + 5 more samples

	// DUT I/O
	logic clk;
	logic nrst;
	logic tick_1kHz;
	logic [N_BUTTONS-1:0] raw_buttons;
	logic [N_BUTTONS-1:0] conditioned_buttons;

	integer ticks_seen;

	// Tick generator instance for accurate 1 kHz from 100 MHz
	wire unused_tick_slow;
	tick_generator #(
		.CLK_FREQ_HZ(100_000_000),
		.TICK_FREQ_HZ(1),
		.CONDITIONED(1_000)
	) tick_gen (
		.clk(clk),
		.rst_n(nrst),
		.tick(unused_tick_slow),
		.tick_1kHz(tick_1kHz)
	);

	// Clock: 100 MHz
	initial clk = 0;
	always #5 clk = ~clk;

	always @(posedge clk or negedge nrst) begin
		if (!nrst) begin
			ticks_seen <= 0;
		end else if (tick_1kHz) begin
			ticks_seen <= ticks_seen + 1;
		end
	end

	// DUT instance
	button_conditioner #(
		.N_BUTTONS(N_BUTTONS),
		.STREAK_REQUIRED(STREAK_REQUIRED)
	) dut (
		.clk(clk),
		.nrst(nrst),
		.tick_1kHz(tick_1kHz),
		.raw_buttons(raw_buttons),
		.conditioned_buttons(conditioned_buttons)
	);

	// Apply buttons and wait for the next 1 kHz sampling edge
	task automatic drive_tick(input logic [N_BUTTONS-1:0] btns);
		begin
			raw_buttons = btns;
			wait_1kHz_period(); // wait for the next 1 kHz tick to sample
			@(posedge clk); // allow post-sample settle
		end
	endtask

	// Wait for one 1 kHz period worth of clk cycles (for inspection/debug)
	task automatic wait_1kHz_period;
		repeat(100000) @(posedge clk);
	endtask
        

	// Expect helper
	task automatic expect_eq(input string label, input logic [N_BUTTONS-1:0] got, input logic [N_BUTTONS-1:0] exp);
		if (got !== exp) begin
			$error("%s: expected %b got %b", label, exp, got);
		end else begin
			$display("%0t %s: OK (%b)", $time, label, got);
		end
	endtask

	initial begin
		// Init
		raw_buttons = '0;
		nrst        = 1'b0;
		repeat (2) @(posedge clk);
		nrst = 1'b1;

		// 1) Clean press on button 0: hold high for STREAK_REQUIRED ticks
		repeat (STREAK_REQUIRED) drive_tick(3'b001);
		expect_eq("press b0 after streak", conditioned_buttons, 3'b001);

		// Hold still high; ensure it stays asserted, then release
		drive_tick(3'b001);
		expect_eq("hold b0", conditioned_buttons, 3'b001);
		drive_tick(3'b000);
		expect_eq("release b0", conditioned_buttons, 3'b000);

		// 2) Bounce on button 1: alternating highs/lows, never reaching streak
		drive_tick(3'b010);
		drive_tick(3'b000);
		drive_tick(3'b010);
		drive_tick(3'b000);
		expect_eq("bounce b1", conditioned_buttons, 3'b000);

		// 3) Button 2 press in parallel while button 1 stays low
		repeat (STREAK_REQUIRED) drive_tick(3'b100);
		expect_eq("press b2", conditioned_buttons, 3'b100);

		// 4) Mixed: b0 pressed again while b2 held; both should assert after streak for b0
		repeat (STREAK_REQUIRED) drive_tick(3'b101);
		expect_eq("b0+b2 held", conditioned_buttons, 3'b101);

		// Release all
		drive_tick(3'b000);
		expect_eq("all released", conditioned_buttons, 3'b000);

		// Ensure at least 20 visible 1 kHz ticks before finishing
		while (ticks_seen < 20) @(posedge tick_1kHz);

		$display("All tests completed after %0d ticks", ticks_seen);
		$finish;
	end

endmodule
