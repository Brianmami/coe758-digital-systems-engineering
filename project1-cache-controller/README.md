# COE 758 Project 1 – Cache Controller

**Course:** COE 758 – Digital Systems Engineering  
**Tools:** VHDL, Xilinx ISE 14, ChipScope Pro

## Overview

A direct-mapped, write-back cache controller in VHDL. The cache has 8 lines of 32 bytes (8-bit tag, 3-bit index, 5-bit offset) and keeps valid and dirty bits. It sits between a CPU request generator (`CPU_gen.vhd`) and an SDRAM controller (`SDRAMController.vhd`), with block RAM as the cache data store (`ipcore_dir/bram.vhd`). `CacheSystem_TB.vhd` is the top level / testbench, and ChipScope cores are used to check the design on hardware.

## Build / run

Open `Project1.xise` in Xilinx ISE 14, regenerate the IP cores from the `.xco` files in `ipcore_dir/` if asked, then synthesize, implement and program the board.
