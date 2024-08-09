import os
import sys
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer
from cocotb.binary import BinaryValue
from cocotb.binary import BinaryRepresentation
import random



# Helper function to reset the DUT
async def reset_dut(dut):
    #dut.output_available.value = 1  ## this is impossible cause internal reg? only inputs are set
    dut.rst.value = 1
    dut.sync.value = 0
    dut.data_i.value = 0
    dut.stb_i.value = 0
    dut.ack_o.value = 0
    await cocotb.triggers.ClockCycles(dut.clk, 10, rising=True)
    dut.rst.value = 0
    await cocotb.triggers.ClockCycles(dut.clk, 10, rising=True)

@cocotb.test()
async def test_ppu(dut):
    """Test the PPU module"""

    # Create a clock on the clk input
    clock = Clock(dut.clk, 10, units="ns")  # 100 MHz clock
    await cocotb.start(clock.start())  ## await was missing -Justin

    # Reset the DUT
    await reset_dut(dut)
    i = 0
    # Basic test variables, test data needs to be binary value!
    data = [BinaryValue(random.randrange(0,100,1),8)] ### how does this work??? 42 value, 8bits
    for i in range (9):
        data += [BinaryValue(random.randrange(0,100,1),8)] ### how does this work??? 42 value, 8bits
    i = 0
    for i in range (10):
        dut.sync.value = 1

    # Wait for a rising edge on sync
        await RisingEdge(dut.sync)

    # Test the input handshake
        dut.stb_i.value = 1
    
        dut.data_i.value = data[i]
        await RisingEdge(dut.clk)
        while not dut.ack_i.value:
            await RisingEdge(dut.clk)

        dut.stb_i.value = 0

    # Wait for processing to start
        await Timer(50, units='ns')

    # Test the output handshake
        while not dut.stb_o.value:      ## this stb_o needs to become 1
            await RisingEdge(dut.clk)
        dut.ack_o.value = 1
        await RisingEdge(dut.clk)
        dut.ack_o.value = 0

        assert dut.data_o.value == data[i]
        print(f"Output data match {i}: expected {data[i]} got {dut.data_o.value}")

        await Timer(100, units='ns')

    pass
