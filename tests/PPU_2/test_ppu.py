import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer
import random

# Helper function to reset the DUT
async def reset_dut(dut):
    dut.rst.value = 1
    dut.sync.value = 0
    dut.data_i.value = 0
    dut.stb_i.value = 0
    dut.ack_o.value = 0
    await Timer(100, units='ns')
    dut.rst.value = 0
    await Timer(100, units='ns')

@cocotb.test()
async def test_ppu(dut):
    """Test the PPU module"""

    # Create a clock on the clk input
    clock = Clock(dut.clk, 10, units="ns")  # 100 MHz clock
    cocotb.start_soon(clock.start())

    # Reset the DUT
    await reset_dut(dut)

    # Basic test variables
    test_data = [random.randint(0, 255) for _ in range(10)]
    dut.sync.value = 1

    # Wait for a rising edge on sync
    await RisingEdge(dut.sync)

    # Test the input handshake
    dut.stb_i.value = 1
    for data in test_data:
        dut.data_i.value = data
        await RisingEdge(dut.clk)
        while not dut.ack_i.value:
            await RisingEdge(dut.clk)

    dut.stb_i.value = 0

    # Wait for processing to start
    await Timer(50, units='ns')

    # Test the output handshake
    for i in range(len(test_data)):
        while not dut.stb_o.value:
            await RisingEdge(dut.clk)
        dut.ack_o.value = 1
        await RisingEdge(dut.clk)
        dut.ack_o.value = 0

        assert dut.data_o.value == test_data[i], f"Output data mismatch: expected {test_data[i]} but got {int(dut.data_o.value)}"

    await Timer(100, units='ns')

