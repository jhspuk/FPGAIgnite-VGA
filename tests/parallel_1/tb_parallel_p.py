import cocotb
from cocotb.triggers import RisingEdge, Timer, with_timeout

async def clock_gen(dut):
    """Generate clock pulses."""
    while True:
        dut.clk.value = 0
        await Timer(5, units='ns')
        dut.clk.value = 1
        await Timer(5, units='ns')

async def reset_dut(dut):
    """Reset the DUT."""
    dut.rst.value = 1
    await Timer(100, units='ns')
    dut.rst.value = 0
    await Timer(100, units='ns')

async def send_data(dut, data, stb_delay):
    """Send data to the DUT with a strobe signal."""
    dut.data_i.value = data
    dut.stb_i.value = 1
    await Timer(stb_delay, units='ns')
    dut.stb_i.value = 0

@cocotb.test()
async def run_test(dut):
    """Test the PPU module."""
    # Start the clock and reset the DUT
    cocotb.start_soon(clock_gen(dut))
    await reset_dut(dut)

    # Wait for two clock cycles to stabilize the DUT
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    # Test case: Send data 0xAA with a strobe signal
    dut._log.info("Sending data: 0xAA")
    dut.ack_o.value = 1  # Ensure ack_o is high before sending data
    await send_data(dut, 0xAA, 10)

    await RisingEdge(dut.clk)
    dut._log.info("Data sent, waiting for ack...")

    try:
        # Wait for the acknowledge signal with a timeout of 500 ns
        await with_timeout(RisingEdge(dut.ack_i), 500, 'ns')
    except cocotb.result.SimTimeoutError:
        dut._log.error("Timeout waiting for ack_i signal")
        assert False, "Timeout waiting for ack_i signal"

    assert dut.data_o.value == 0xAA, f"Expected 0xAA, got {hex(dut.data_o.value)}"
    dut._log.info("Test passed with data: 0xAA")

