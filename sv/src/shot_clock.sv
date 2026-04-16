module shot_clock(
	input logic clk,
	input logic nrst, 
	input logic enable,
	input logic tick_1hz,
	input logic reload, 
	output logic [9:0] value,
	output logic at_six;
	output logic expired
);

	always_ff @(posedge clk) begin 



	end

