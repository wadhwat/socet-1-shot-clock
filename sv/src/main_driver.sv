module main_driver (
    input logic clk,
    output [7:0] main_segments_pin_out,
    output [3:0] decoder_pin //controls the decoder to select correct ss
);
    logic [6:0] ss1, ss2, ss3;
    logic colon1, colon2, colon3;


    game_clock_driver g1 ();
    score_driver s1 ();
    shotclock_driver sh1 ();

    "LED 1 [7:0] (a-g & DP)"
"LED_2 [7:0] (a-g & DP)"
...
"LED 12 [7:0] (a-g & DP)"

colon 1
colon 2
colon 3

buzzer signal

6 LED inputs

input clk
input 480hz

num = 1;
while(true):
  num++;
  switch(num)
  {
  case 1:
    main_segments_pin_out[0] <= LED_1[0]
	...
    M_S_P_O[11] <= LED_1[11]
  case 2:
    ...
  case 12:
    M_S_P_O[0] <= LED_12[0]
	...
    M_S_P_O[11] <= LED_12[11]
  }

  if(num == 12)
    num = 1;
  

endmodule
