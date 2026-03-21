# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    dut._log.info("Test Morse code: HELLO WORLD")

    # Each clock cycle equals one Morse unit (no clock divider in design).
    # After reset, all outputs must be 0.
    assert dut.uo_out.value == 0x00, f"After reset: expected uo_out=0x00, got {hex(int(dut.uo_out.value))}"
    assert dut.uio_out.value == 0x00, f"After reset: expected uio_out=0x00, got {hex(int(dut.uio_out.value))}"
    # Bidirectional pins are always configured as outputs.
    assert dut.uio_oe.value == 0xFF, f"Expected uio_oe=0xFF, got {hex(int(dut.uio_oe.value))}"

    # Helper to advance one unit and check output value
    async def check_unit(expected, label):
        await ClockCycles(dut.clk, 1)
        await Timer(1, unit="ns")  # cocotb resumes in the active region before NBA updates;
        # this 1 ns advance lets non-blocking assignments propagate before sampling
        val = int(dut.uo_out.value)
        assert val == expected, f"{label}: expected {hex(expected)}, got {hex(val)}"
        assert int(dut.uio_out.value) == expected, f"{label} uio_out mismatch"

    ON  = 0xFF
    OFF = 0x00

    # H: ....  (steps 0-7)
    # dot ON, gap, dot ON, gap, dot ON, gap, dot ON, char_gap(3)
    dut._log.info("H: ....")
    await check_unit(ON,  "H dot1")
    await check_unit(OFF, "H gap1")
    await check_unit(ON,  "H dot2")
    await check_unit(OFF, "H gap2")
    await check_unit(ON,  "H dot3")
    await check_unit(OFF, "H gap3")
    await check_unit(ON,  "H dot4")
    await check_unit(OFF, "H char_gap unit0")
    await check_unit(OFF, "H char_gap unit1")
    await check_unit(OFF, "H char_gap unit2")

    # E: .  (steps 8-9)
    dut._log.info("E: .")
    await check_unit(ON,  "E dot")
    await check_unit(OFF, "E char_gap unit0")
    await check_unit(OFF, "E char_gap unit1")
    await check_unit(OFF, "E char_gap unit2")

    # L: .-..  (steps 10-17)
    dut._log.info("L: .-..")
    await check_unit(ON,  "L dot1")
    await check_unit(OFF, "L gap1")
    await check_unit(ON,  "L dash unit0")
    await check_unit(ON,  "L dash unit1")
    await check_unit(ON,  "L dash unit2")
    await check_unit(OFF, "L gap2")
    await check_unit(ON,  "L dot2")
    await check_unit(OFF, "L gap3")
    await check_unit(ON,  "L dot3")
    await check_unit(OFF, "L char_gap unit0")
    await check_unit(OFF, "L char_gap unit1")
    await check_unit(OFF, "L char_gap unit2")

    dut._log.info("Morse code test passed!")
