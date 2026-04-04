module score_tracker(
    input logic clk,
    input logic nrst,
    input logic plus_one_possession_pulse,
    input logic minus_one_possession_pulse,
    input logic possession_state, // 1 is the home team and 0 is the away team
    output logic [7:0] home_score,
    output logic [7:0] away_score
);

    always_ff @(posedge clk or negedge nrst) begin
        if (!nrst) begin
            home_score <= 8'd0;
            away_score <= 8'd0;
        end
        else if (plus_one_possession_pulse) begin
            if (possession_state)
                home_score <= home_score + 8'd1;
            else
                away_score <= away_score + 8'd1;
        end
        else if (minus_one_possession_pulse) begin
            if (possession_state) begin
                if (home_score != 8'd0)
                    home_score <= home_score - 8'd1;
            end
            else begin
                if (away_score != 8'd0)
                    away_score <= away_score - 8'd1;
            end
        end
    end

endmodule
