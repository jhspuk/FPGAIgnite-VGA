import os
import sys
from pathlib import Path

import cocotb
from cocotb.runner import get_runner
from cocotb.triggers import Timer
from cocotb.clock import Clock
from cocotbext.wishbone.driver import WishboneMaster
from cocotbext.wishbone.driver import WBOp

@cocotb.test()
async def wishbone_stuff(dut):
    """Test for wihsbone stuff"""
    await init(dut)
    wbs = WishboneMaster(dut, "WB", dut.WB_CLK_I,
                          width=32,   # size of data bus
                          timeout=100,
                          signals_dict={
                                      "cyc":  "CYC_I",
                                      "stb":  "STB_I",
                                      "we":   "WE_I",
                                      "adr":  "ADR_I",
                                      "datwr":"DAT_I",
                                      "datrd":"DAT_O",
                                      "ack":  "ACK_O" },case_insensitive=False)

    #wbOp is (addr, dat)
    wbRes = await wbs.send_cycle([WBOp(0, 0xcafe), WBOp(0,0), WBOp(1,0)])

    # adr: address of the operation
    # dat: data to write, None indicates a read cycle
    # idle: number of clock cycles between asserting cyc and stb
    # sel: the selection mask for the operation

    await cocotb.triggers.ClockCycles(dut.CLK_I, 20, rising=True)

    await PostTestDelay(dut)


async def init(dut):
    c = Clock(dut.CLK_I  , 20, 'ns')
    await cocotb.start(c.start())

    c_wb = Clock(dut.WB_CLK_I  , 20, 'ns')
    await cocotb.start(c_wb.start()) 

    await cocotb.triggers.ClockCycles(dut.CLK_I, 20, rising=True)


async def PostTestDelay(dut):
    await cocotb.triggers.ClockCycles(dut.CLK_I, 2, rising=True)
    # dut.reset.value = 1
    await cocotb.triggers.ClockCycles(dut.CLK_I, 2, rising=True)


def adder_runner():
    """Simulate the adder example using the Python runner.

    This file can be run directly or via pytest discovery.
    """
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "vhdl")
    sim = os.getenv("SIM", "ghdl")

    proj_path = "../"
    
    
    
    vhdl_sources = [proj_path + "tests/wishbone_2/" + "vga_controller.vhd"]

    
    # https://docs.cocotb.org/en/stable/library_reference.html#cocotb.runner.get_runner
    runner = get_runner(sim)

    # https://docs.cocotb.org/en/stable/library_reference.html#cocotb.runner.Simulator.build
    runner.build(
        vhdl_sources=vhdl_sources,
        hdl_toplevel="vga_controller",
        always=True,
        build_args= ["-fsynopsys"]
    )

    
    WaveformOptionVcd = "--vcd=waveforms.vcd"

    # https://docs.cocotb.org/en/stable/library_reference.html#cocotb.runner.Simulator.test
    #runner.test(hdl_toplevel="adder", test_module="test_adder_solution")
    #runner.test(hdl_toplevel="adder", test_module="test_adder_solution", test_args=WaveformOptionVcd,)
    #runner.test(hdl_toplevel="adder", test_module="test_adder_solution", test_args=[WaveformOptionVcd],)
    runner.test(hdl_toplevel="vga_controller", test_module="testbench", test_args=['-fsynopsys'],plusargs=[WaveformOptionVcd])


if __name__ == "__main__":
    adder_runner()
