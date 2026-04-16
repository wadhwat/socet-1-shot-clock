## =========================================================
## ac_buzzer_test.xdc
## Arty S7-25
## Top module ports:
##   clk_100mhz
##   buzzer_drive
## =========================================================

## 100 MHz onboard clock
set_property -dict { PACKAGE_PIN R2 IOSTANDARD SSTL135 } [get_ports { clk_100mhz }];
create_clock -add -name sys_clk_pin -period 10.000 -waveform {0 5.000} [get_ports { clk_100mhz }];

## PMOD JA pin 1 -> transistor select/base/gate input for AT1224TWT buzzer drive
set_property -dict { PACKAGE_PIN L17 IOSTANDARD LVCMOS33 } [get_ports { buzzer_drive }];
