## =========================================================
## possession_led_test.xdc
## Target board: Digilent Arty S7-25 + ShotClock main board
## Top module ports:
##   clk
##   rst_in
##   auto_mode
##   btn_possession_raw
##   possession_leds[1:0]
##
## Main-board LED mappings reused from:
##   constraints/top.xdc
## =========================================================

## 100 MHz onboard clock
set_property -dict { PACKAGE_PIN R2 IOSTANDARD SSTL135 } [get_ports { clk }];
create_clock -add -name sys_clk_pin -period 10.000 -waveform {0.000 5.000} [get_ports { clk }];

## Arty onboard controls for this standalone test
set_property -dict { PACKAGE_PIN H14 IOSTANDARD LVCMOS33 } [get_ports { rst_in }];             # Arty SW0, high = reset
set_property -dict { PACKAGE_PIN H18 IOSTANDARD LVCMOS33 } [get_ports { auto_mode }];          # Arty SW1, high = auto pattern
set_property -dict { PACKAGE_PIN G15 IOSTANDARD LVCMOS33 } [get_ports { btn_possession_raw }]; # Arty BTN0, manual toggle

## ShotClock main-board possession LEDs
set_property -dict { PACKAGE_PIN U11 IOSTANDARD LVCMOS33 } [get_ports { possession_leds[0] }]; # LED_POS_HOME -> IO26 / ck_io26
set_property -dict { PACKAGE_PIN T11 IOSTANDARD LVCMOS33 } [get_ports { possession_leds[1] }]; # LED_POS_AWAY -> IO27 / ck_io27
