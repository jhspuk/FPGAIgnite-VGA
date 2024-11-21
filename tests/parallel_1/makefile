TOPLEVEL_LANG = verilog
VERILOG_SOURCES = $(shell pwd)/parallel_p.sv
MODULE = tb_parallel_p

# SIM can be changed to any supported simulator, e.g., icarus, modelsim, etc.
SIM ?= icarus

include $(shell cocotb-config --makefiles)/Makefile.sim

