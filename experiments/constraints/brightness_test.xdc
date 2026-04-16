## =========================================================
## brightness_test.xdc
## Arty S7-25
## Top module ports:
##   clk_100mhz
##   btn_rst_raw
##   btn_cycle
##   disp_sel[3:0]
##   seg[7:0]
## =========================================================

## 100 MHz onboard clock
set_property -dict { PACKAGE_PIN R2 IOSTANDARD SSTL135 } [get_ports { clk_100mhz }];
create_clock -add -name sys_clk_pin -period 10.000 -waveform {0 5.000} [get_ports { clk_100mhz }];

## Button 0 -> cycle frequency
set_property -dict { PACKAGE_PIN G15 IOSTANDARD LVCMOS33 } [get_ports { btn_cycle }];

## Button 1 -> active-low reset
set_property -dict { PACKAGE_PIN K16 IOSTANDARD LVCMOS33 } [get_ports { btn_rst_raw }];

## PMOD JA -> 4-bit display select
set_property -dict { PACKAGE_PIN L17 IOSTANDARD LVCMOS33 } [get_ports { disp_sel[0] }];
set_property -dict { PACKAGE_PIN L18 IOSTANDARD LVCMOS33 } [get_ports { disp_sel[1] }];
set_property -dict { PACKAGE_PIN M14 IOSTANDARD LVCMOS33 } [get_ports { disp_sel[2] }];
set_property -dict { PACKAGE_PIN N14 IOSTANDARD LVCMOS33 } [get_ports { disp_sel[3] }];

## PMOD JB -> 8-bit segments {dp,g,f,e,d,c,b,a}
set_property -dict { PACKAGE_PIN P17 IOSTANDARD LVCMOS33 } [get_ports { seg[0] }];
set_property -dict { PACKAGE_PIN P18 IOSTANDARD LVCMOS33 } [get_ports { seg[1] }];
set_property -dict { PACKAGE_PIN R18 IOSTANDARD LVCMOS33 } [get_ports { seg[2] }];
set_property -dict { PACKAGE_PIN T18 IOSTANDARD LVCMOS33 } [get_ports { seg[3] }];
set_property -dict { PACKAGE_PIN P14 IOSTANDARD LVCMOS33 } [get_ports { seg[4] }];
set_property -dict { PACKAGE_PIN P15 IOSTANDARD LVCMOS33 } [get_ports { seg[5] }];
set_property -dict { PACKAGE_PIN N15 IOSTANDARD LVCMOS33 } [get_ports { seg[6] }];
set_property -dict { PACKAGE_PIN P16 IOSTANDARD LVCMOS33 } [get_ports { seg[7] }];