# COE 758 Tutorial 1 – Xilinx ISE and ChipScope

**Course:** COE 758 – Digital Systems Engineering  
**Tools:** VHDL, Xilinx ISE 14, ChipScope Pro (Spartan-3E board)

## Overview

Introductory FPGA design that reads switches and drives LEDs, with ChipScope ICON / ILA / VIO cores added so internal signals can be watched and driven on the running hardware.

## Build / run

Create an ISE project, add `tutorial1.vhd` and the `tutorial1.ucf` pin constraints, regenerate the ChipScope cores (ICON, ILA, VIO) in CORE Generator, then synthesize and program the board.
