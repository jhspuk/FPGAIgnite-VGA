import cocotb
from cocotb.triggers import RisingEdge, FallingEdge, Timer
from cocotb.result import TestFailure
import random

@cocotb.coroutine
async def reset_dut(dut, duration_ns):
    """Reset the DUT"""
    dut.rst <= 1
    await Timer(duration_ns, units='ns')
    dut.rst <= 0
    await Timer(duration_ns, units='ns')

@cocotb.coroutine
async def drive_input(dut, data):
    """Drive input data to the DUT"""
    dut.data_i <= data
    dut.stb_i <= 1
    await RisingEdge(dut.clk)
    while dut.ack_i != 1:
        await RisingEdge(dut.clk)
    dut.stb_i <= 0
    await RisingEdge(dut.clk)

@cocotb.coroutine
async def check_output(dut, expected_data):
    """Check the output data from the DUT"""
    while dut.stb_o != 1:
        await RisingEdge(dut.clk)
    assert dut.data_o == expected_data, f"Expected {expected_data}, got {dut.data_o.value}"

@cocotb.test()
async def test_ppu(dut):
    """Test the PPU module"""

    # Reset the DUT
    await reset_dut(dut, 10)

    # Initialize inputs
    dut.sync <= 0
    dut.mode <= 0
    dut.data_i <= 0
    dut.stb_i <= 0
    dut.ack_o <= 0

    # Test input handshake and output data
    for i in range(10):
        data = random.randint(0, 255)
        await drive_input(dut, data)
        await check_output(dut, data)

    # Test sync signal
    dut.sync <= 1
    await RisingEdge(dut.clk)
    dut.sync <= 0
    await RisingEdge(dut.clk)
    assert dut.h_count == 0, f"h_count should be 0 after sync, got {dut.h_count.value}"
    assert dut.v_count == 0, f"v_count should be 0 after sync, got {dut.v_count.value}"

    # Test mode switching
    for mode in range(8):
        dut.mode <= mode
        await Timer(10, units='ns')
        # Add specific checks for each mode if necessary

    # Test output handshake
    dut.ack_o <= 1
    await RisingEdge(dut.clk)
    assert dut.stb_o == 0, f"stb_o should be 0 when ack_o is 1, got {dut.stb_o.value}"
    dut.ack_o <= 0

    # Test output availability
    dut.output_available <= 1
    await RisingEdge(dut.clk)
    assert dut.stb_o == 1, f"stb_o should be 1 when output is available, got {dut.stb_o.value}"
    dut.output_available <= 0

    # Additional tests can be added here

    cocotb.log.info("Test completed successfully")