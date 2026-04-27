## =========================================================
## experimental_top.xdc
## Target board: Digilent Arty S7-25
## HDL top module: experiments/src/experimental_top.sv
##
## Experiment:
##   Breadboard one physical 4-digit 7-segment display wired in the
##   shot-clock display position. Reset and possession are Arty switches;
##   start/stop, score-up, shot reset, and display-mode cycle are Arty buttons.
##
## Board pin reference:
##   constraints/Arty-S7-25-Master.xdc
##
## Output mappings reused from:
##   constraints/top.xdc
## =========================================================

## 100 MHz onboard clock
set_property -dict { PACKAGE_PIN R2 IOSTANDARD SSTL135 } [get_ports { clk }];
create_clock -add -name sys_clk_pin -period 10.000 -waveform {0.000 5.000} [get_ports { clk }];

## ---------------------------------------------------------
## Arty onboard experiment controls
## ---------------------------------------------------------
set_property -dict { PACKAGE_PIN H14 IOSTANDARD LVCMOS33 } [get_ports { sw_n_rst }];            # sw[0], 1=run
set_property -dict { PACKAGE_PIN H18 IOSTANDARD LVCMOS33 } [get_ports { sw_possession }];       # sw[1], 0=home, 1=away
set_property -dict { PACKAGE_PIN G15 IOSTANDARD LVCMOS33 } [get_ports { btn_start_stop_raw }];  # btn[0]
set_property -dict { PACKAGE_PIN K16 IOSTANDARD LVCMOS33 } [get_ports { btn_score_up_raw }];    # btn[1]
set_property -dict { PACKAGE_PIN J16 IOSTANDARD LVCMOS33 } [get_ports { btn_shot_reset_raw }];  # btn[2]
set_property -dict { PACKAGE_PIN H13 IOSTANDARD LVCMOS33 } [get_ports { btn_display_mode_raw }]; # btn[3]

## ---------------------------------------------------------
## Display segment nets
## HDL: display_segments[7:0] = {dp,g,f,e,d,c,b,a}
## ---------------------------------------------------------
set_property -dict { PACKAGE_PIN V15 IOSTANDARD LVCMOS33 } [get_ports { display_segments[0] }]; # SEG_A -> IO33 / ck_io33
set_property -dict { PACKAGE_PIN V17 IOSTANDARD LVCMOS33 } [get_ports { display_segments[1] }]; # SEG_B -> IO7  / ck_io7
set_property -dict { PACKAGE_PIN R14 IOSTANDARD LVCMOS33 } [get_ports { display_segments[2] }]; # SEG_C -> IO3  / ck_io3
set_property -dict { PACKAGE_PIN R17 IOSTANDARD LVCMOS33 } [get_ports { display_segments[3] }]; # SEG_D -> IO6  / ck_io6
set_property -dict { PACKAGE_PIN L13 IOSTANDARD LVCMOS33 } [get_ports { display_segments[4] }]; # SEG_E -> IO0  / ck_io0
set_property -dict { PACKAGE_PIN R16 IOSTANDARD LVCMOS33 } [get_ports { display_segments[5] }]; # SEG_F -> IO5  / ck_io5
set_property -dict { PACKAGE_PIN L16 IOSTANDARD LVCMOS33 } [get_ports { display_segments[6] }]; # SEG_G -> IO2  / ck_io2
set_property -dict { PACKAGE_PIN T14 IOSTANDARD LVCMOS33 } [get_ports { display_segments[7] }]; # SEG_DP -> IO4 / ck_io4

## ---------------------------------------------------------
## LEDs
## ---------------------------------------------------------
set_property -dict { PACKAGE_PIN U11 IOSTANDARD LVCMOS33 } [get_ports { possession_leds[0] }]; # LED_POS_HOME -> IO26 / ck_io26
set_property -dict { PACKAGE_PIN T11 IOSTANDARD LVCMOS33 } [get_ports { possession_leds[1] }]; # LED_POS_AWAY -> IO27 / ck_io27
set_property -dict { PACKAGE_PIN A14 IOSTANDARD LVCMOS33 } [get_ports { period_leds[0] }];     # LED_P1       -> A7   / ck_a7
set_property -dict { PACKAGE_PIN D16 IOSTANDARD LVCMOS33 } [get_ports { period_leds[1] }];     # LED_P2       -> A8   / ck_a8
set_property -dict { PACKAGE_PIN D17 IOSTANDARD LVCMOS33 } [get_ports { period_leds[2] }];     # LED_P3       -> A9   / ck_a9
set_property -dict { PACKAGE_PIN D14 IOSTANDARD LVCMOS33 } [get_ports { period_leds[3] }];     # LED_P4       -> A10  / ck_a10

## ---------------------------------------------------------
## Display select, buzzer, and colon nets
## ---------------------------------------------------------
set_property -dict { PACKAGE_PIN T13 IOSTANDARD LVCMOS33 } [get_ports { display_select[0] }]; # SEL_A0 -> IO29 / ck_io29
set_property -dict { PACKAGE_PIN T12 IOSTANDARD LVCMOS33 } [get_ports { display_select[1] }]; # SEL_A1 -> IO30 / ck_io30
set_property -dict { PACKAGE_PIN V13 IOSTANDARD LVCMOS33 } [get_ports { display_select[2] }]; # SEL_A2 -> IO31 / ck_io31
set_property -dict { PACKAGE_PIN U12 IOSTANDARD LVCMOS33 } [get_ports { display_select[3] }]; # SEL_A3 -> IO32 / ck_io32
set_property -dict { PACKAGE_PIN R11 IOSTANDARD LVCMOS33 } [get_ports { buzzer_drive }];      # Buzzer -> IO28 / ck_io28
set_property -dict { PACKAGE_PIN N13 IOSTANDARD LVCMOS33 } [get_ports { colon_out }];         # Colon  -> IO1  / ck_io1
