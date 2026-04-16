`timescale 1ns/1ps

module tb_score_tracker;

    logic clk;
    logic nrst;
    logic plus_one_possession_pulse;
    logic minus_one_possession_pulse;
    logic possession_state;

    logic [7:0] home_score;
    logic [7:0] away_score;

    score_tracker dut (
        .clk(clk),
        .nrst(nrst),
        .plus_one_possession_pulse(plus_one_possession_pulse),
        .minus_one_possession_pulse(minus_one_possession_pulse),
        .possession_state(possession_state),
        .home_score(home_score),
        .away_score(away_score)
    );

    // 10 ns clock
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        nrst = 1'b0;
	plus_one_possession_pulse = 1'b0;
	minus_one_possession_pulse = 1'b0;
        possession_state = 1'b0;

	#12;
	nrst = 1'b1;

	//reset values
	@(posedge clk);
	if(home_score == 8'd0 && away_score == 8'd0)
		$display("Passed Test 1");
	else
		$display("Failed Test 1");

	//do the case where we increment home score
	possession_state = 1'b1;
	plus_one_possession_pulse = 1'b1;
	@(posedge clk);
	plus_one_possession_pulse = 1'b0;	
	@(posedge clk);
	if(home_score == 8'd1 && away_score == 8'd0)
		$display("Passed Test 2");
	else
		$display("Failed Test 2");
	//now increase the away score
	possession_state = 1'b0;
	plus_one_possession_pulse = 1'b1;
	@(posedge clk);
	plus_one_possession_pulse = 1'b0;
	@(posedge clk);
	if(home_score == 8'd1 && away_score == 8'd1)
		$display("Passed Test 3");
	else
		$display("Failed Test 3");
	//decrement the home score
	possession_state = 1'b1;
	minus_one_possession_pulse = 1'b1;
	@(posedge clk);
	minus_one_possession_pulse = 1'b0;
	if(home_score == 8'd0 && away_score == 8'd1)
		$display("Passed Test 4");
	else
		$display("Failed Test 4");

        $finish;
    end

endmodule
