## Constraints for basys 3 FPGA

## Reloj de entrada (100 MHz). El de 50 MHz lo deriva Vivado a partir del clk_wiz_0
set_property -dict { PACKAGE_PIN W5 IOSTANDARD LVCMOS33 } [get_ports clk]
create_clock -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]
set_input_jitter [get_clocks sys_clk_pin] 0.1

## Reset (btnC)
set_property -dict { PACKAGE_PIN U18 IOSTANDARD LVCMOS33 } [get_ports reset]

## UART (bridge USB-UART de la Basys3)
set_property -dict { PACKAGE_PIN B18 IOSTANDARD LVCMOS33 } [get_ports rx]   ;# RsRx
set_property -dict { PACKAGE_PIN A18 IOSTANDARD LVCMOS33 } [get_ports tx]   ;# RsTx

## Entradas asíncronas (botón y UART): no tienen relación con el reloj
set_false_path -from [get_ports reset]

## Configuración del bitstream
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

## Leds
##set_property -dict { PACKAGE_PIN U16 IOSTANDARD LVCMOS33 } [get_ports { leds[0] }];
##set_property -dict { PACKAGE_PIN E19 IOSTANDARD LVCMOS33 } [get_ports { leds[1] }];
##set_property -dict { PACKAGE_PIN U19 IOSTANDARD LVCMOS33 } [get_ports { leds[2] }];
##set_property -dict { PACKAGE_PIN V19 IOSTANDARD LVCMOS33 } [get_ports { leds[3] }];
##set_property -dict { PACKAGE_PIN W18 IOSTANDARD LVCMOS33 } [get_ports { leds[4] }];
##set_property -dict { PACKAGE_PIN U15 IOSTANDARD LVCMOS33 } [get_ports { leds[5] }];
##set_property -dict { PACKAGE_PIN U14 IOSTANDARD LVCMOS33 } [get_ports { leds[6] }];
##set_property -dict { PACKAGE_PIN V14 IOSTANDARD LVCMOS33 } [get_ports { leds[7] }];