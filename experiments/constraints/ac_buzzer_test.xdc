## =========================================================
## ac_buzzer_test.xdc
## Target board: Digilent Arty S7-25 + ShotClock main board
## Top module ports:
##   clk
##   buzzer_drive
##   buzzer_active_led
##
## Main-board mappings reused from:
##   constraints/top.xdc
## =========================================================

## 100 MHz onboard clock
set_property -dict { PACKAGE_PIN R2 IOSTANDARD SSTL135 } [get_ports { clk }];
create_clock -add -name sys_clk_pin -period 10.000 -waveform {0.000 5.000} [get_ports { clk }];

## ShotClock main-board buzzer net: IO28 / ck_io28
set_property -dict { PACKAGE_PIN R11 IOSTANDARD LVCMOS33 } [get_ports { buzzer_drive }];

## Debug indicator: LED_P1 on the main board mirrors the active beep window.
set_property -dict { PACKAGE_PIN A14 IOSTANDARD LVCMOS33 } [get_ports { buzzer_active_led }];
