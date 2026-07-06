# socet-1-shot-clock

## Description

This project is a SystemVerilog implementation of a basketball shot clock
controller. It manages the game clock, shot clock, score tracking, period
state, possession indicators, seven-segment display outputs, button inputs,
and buzzer control for an FPGA-based scoreboard system.

## Repository Layout

* `sv/src/` - SystemVerilog source modules for the clock, display drivers,
  control FSM, scoring, possession, and top-level integration.
* `sv/tb/` - Testbenches for the main hardware modules.
* `constraints/` - FPGA constraint files for the top-level design.
* `experiments/` - Prototype modules, constraints, and experiment notes.
* `KiCad_Files/` - PCB design files and related component libraries.

## Authors

* Tejas Wadhwa
* Jean-Milan Albarede
* Mehmet Mercan
* Hemant Garg
* Ian Kozloski
