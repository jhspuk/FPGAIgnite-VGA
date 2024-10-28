# FPGAIgnite-VGA
VGA team of the FPGA Ignite Hackathon

## Continuing Work on the Project
1. The most promising design can currently be found in the `verilator_sims` folder.
2. The design consists of two modules: the VGA driver and the PPU. One is located in `ppu.v` and the other in `vga_driver.sv`. The pinout and necessary signal connections are documented in the image below:
   ![alt text](ppu.png)

- For fabrication, please delete the signals marked in gray.
- When discussing with the FPGA team, the signals marked in blue are particularly important.
- It’s uncertain whether we should keep the two-module structure or merge them into a single module (this may be an optimization consideration).
