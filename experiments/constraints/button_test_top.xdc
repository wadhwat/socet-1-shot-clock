## =========================================================
## top.xdc
## Target board: Digilent Arty S7-25
## HDL top module: sv/src/top.sv
##
## Board pin reference:
##   constraints/Arty-S7-25-Master.xdc
##
## PCB source:
##   KiCad_Files/ShotClockPCB/17pinPCB/17pinPCB.kicad_pcb
##
## Top module ports:
##   clk
##   rst_in
##   btn_start_stop_raw
##   btn_possession_raw
##   btn_score_up_raw
##   btn_score_down_raw
##   btn_shot_reset_raw
##   period_leds[3:0]
##   possession_leds[1:0]
##   buzzer_drive
##   display_select[3:0]
##   display_segments[7:0]
##   colon_out
##   gc_colon_out
##   sc_colon_out
##   scr_colon_out
##
## Confirmed PCB-to-Arty mappings:
##   PCB net      Arty label  FPGA pin  HDL port
##   Colon        IO1         N13       colon_out
##   SEG_A        IO33        V15       display_segments[0]
##   SEG_B        IO7         V17       display_segments[1]
##   SEG_C        IO3         R14       display_segments[2]
##   SEG_D        IO6         R17       display_segments[3]
##   SEG_E        IO0         L13       display_segments[4]
##   SEG_F        IO5         R16       display_segments[5]
##   SEG_G        IO2         L16       display_segments[6]
##   SEG_DP       IO4         T14       display_segments[7]
##   SEL_A0       IO29        T13       display_select[0]
##   SEL_A1       IO30        T12       display_select[1]
##   SEL_A2       IO31        V13       display_select[2]
##   SEL_A3       IO32        U12       display_select[3]
##   Buzzer       IO28        R11       buzzer_drive
##   LED_POS_HOME IO26        U11       possession_leds[0]
##   LED_POS_AWAY IO27        T11       possession_leds[1]
##   BTN_1        A0          G13       btn_start_stop_raw
##   BTN_2        A1          B16       btn_possession_raw
##   BTN_3        A2          A16       btn_score_up_raw
##   BTN_4        A3          C13       btn_score_down_raw
##   BTN_5        A4          C14       btn_shot_reset_raw
##   BTN_6        A6          B14       rst_in
##   LED_P1       A7          A14       period_leds[0]
##   LED_P2       A8          D16       period_leds[1]
##   LED_P3       A9          D17       period_leds[2]
##   LED_P4       A10         D14       period_leds[3]
##
## Assumptions:
##   - Display segment bit order is display_segments[7:0] = {dp,g,f,e,d,c,b,a}.
##   - Button mapping follows top.sv comments:
##       pb[0]=start/stop, pb[1]=possession, pb[2]=score up,
##       pb[3]=score down, pb[4]=shot reset, pb[5]=reset.
##   - Unconfirmed signals are left commented out intentionally so Vivado does
##     not silently use stale PMOD-header assumptions.
## =========================================================

## 100 MHz onboard clock
set_property -dict { PACKAGE_PIN R2 IOSTANDARD SSTL135 } [get_ports { clk }];
create_clock -add -name sys_clk_pin -period 10.000 -waveform {0.000 5.000} [get_ports { clk }];

## ---------------------------------------------------------
## Confirmed display segment nets
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
## Confirmed LEDs
## ---------------------------------------------------------
set_property -dict { PACKAGE_PIN U11 IOSTANDARD LVCMOS33 } [get_ports { possession_leds[0] }]; # LED_POS_HOME -> IO26 / ck_io26
set_property -dict { PACKAGE_PIN T11 IOSTANDARD LVCMOS33 } [get_ports { possession_leds[1] }]; # LED_POS_AWAY -> IO27 / ck_io27
set_property -dict { PACKAGE_PIN A14 IOSTANDARD LVCMOS33 } [get_ports { period_leds[0] }];     # LED_P1       -> A7   / ck_a7
set_property -dict { PACKAGE_PIN D16 IOSTANDARD LVCMOS33 } [get_ports { period_leds[1] }];     # LED_P2       -> A8   / ck_a8
set_property -dict { PACKAGE_PIN D17 IOSTANDARD LVCMOS33 } [get_ports { period_leds[2] }];     # LED_P3       -> A9   / ck_a9
set_property -dict { PACKAGE_PIN D14 IOSTANDARD LVCMOS33 } [get_ports { period_leds[3] }];     # LED_P4       -> A10  / ck_a10

## ---------------------------------------------------------
## Confirmed buttons
## HDL comments: pb[0]=start/stop, pb[1]=possession, pb[2]=score up,
##               pb[3]=score down, pb[4]=shot reset, pb[5]=reset
## ---------------------------------------------------------
set_property -dict { PACKAGE_PIN K16 IOSTANDARD LVCMOS33 } [get_ports { btn_start_stop_raw }]; # BTN_1 -> A0 / ck_a0
set_property -dict { PACKAGE_PIN J16 IOSTANDARD LVCMOS33 } [get_ports { btn_possession_raw }]; # BTN_2 -> A1 / ck_a1
set_property -dict { PACKAGE_PIN H13 IOSTANDARD LVCMOS33 } [get_ports { btn_score_up_raw }];   # BTN_3 -> A2 / ck_a2
set_property -dict { PACKAGE_PIN C13 IOSTANDARD LVCMOS33 } [get_ports { btn_score_down_raw }]; # BTN_4 -> A3 / ck_a3
set_property -dict { PACKAGE_PIN C14 IOSTANDARD LVCMOS33 } [get_ports { btn_shot_reset_raw }]; # BTN_5 -> A4 / ck_a4
set_property -dict { PACKAGE_PIN G15 IOSTANDARD LVCMOS33 } [get_ports { rst_in }];             # BTN_6 -> A6 / ck_a6
#set_property -dict {  } [get_ports { btn[0] }]; #IO_L18N_T2_A23_15 Sch=btn[0] // rst
#set_property -dict {  } [get_ports { btn[1] }]; #IO_L19P_T3_A22_15 Sch=btn[1] // start/stop
#set_property -dict {  } [get_ports { btn[2] }]; #IO_L19N_T3_A21_VREF_15 Sch=btn[2] // poss
#set_property -dict {  } [get_ports { btn[3] }]; #IO_L20P_T3_A20_15 Sch=btn[3] // score up



## ---------------------------------------------------------
## Confirmed display select, buzzer, and colon nets
## ---------------------------------------------------------
set_property -dict { PACKAGE_PIN T13 IOSTANDARD LVCMOS33 } [get_ports { display_select[0] }]; # SEL_A0 -> IO29 / ck_io29
set_property -dict { PACKAGE_PIN T12 IOSTANDARD LVCMOS33 } [get_ports { display_select[1] }]; # SEL_A1 -> IO30 / ck_io30
set_property -dict { PACKAGE_PIN V13 IOSTANDARD LVCMOS33 } [get_ports { display_select[2] }]; # SEL_A2 -> IO31 / ck_io31
set_property -dict { PACKAGE_PIN U12 IOSTANDARD LVCMOS33 } [get_ports { display_select[3] }]; # SEL_A3 -> IO32 / ck_io32
set_property -dict { PACKAGE_PIN R11 IOSTANDARD LVCMOS33 } [get_ports { buzzer_drive }];      # Buzzer -> IO28 / ck_io28
set_property -dict { PACKAGE_PIN N13 IOSTANDARD LVCMOS33 } [get_ports { colon_out }];         # Colon  -> IO1  / ck_io1

## Extra colon/debug outputs on unused PMOD pins.
set_property -dict { PACKAGE_PIN L17 IOSTANDARD LVCMOS33 } [get_ports { gc_colon_out }];  # PMOD JA pin 1
set_property -dict { PACKAGE_PIN L18 IOSTANDARD LVCMOS33 } [get_ports { sc_colon_out }];  # PMOD JA pin 2
set_property -dict { PACKAGE_PIN M14 IOSTANDARD LVCMOS33 } [get_ports { scr_colon_out }]; # PMOD JA pin 3
