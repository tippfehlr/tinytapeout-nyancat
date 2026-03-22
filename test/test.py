# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start Nyan Cat test")

    # 10 MHz clock (100 ns period), matching design expectation
    clock = Clock(dut.clk, 100, unit="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await Timer(1, unit="ns")

    # After reset: both piezo outputs must be silent, IOs configured as outputs
    assert dut.uo_out.value == 0x00, \
        f"After reset: expected uo_out=0x00, got {hex(int(dut.uo_out.value))}"
    assert dut.uio_out.value == 0x00, \
        f"After reset: expected uio_out=0x00, got {hex(int(dut.uio_out.value))}"
    assert dut.uio_oe.value == 0xFF, \
        f"Expected uio_oe=0xFF, got {hex(int(dut.uio_oe.value))}"

    dut._log.info("Advancing to first unit tick (600,001 cycles)...")
    # After 600,001 cycles the sequencer loads the first intro note (D#6 on lead).
    # Harmony stays silent (intro silence period).
    await ClockCycles(dut.clk, 600_001)
    await Timer(1, unit="ns")

    harm_out = (int(dut.uo_out.value) >> 1) & 0x01
    assert harm_out == 0, f"Harmony should be silent during intro, got harm_out={harm_out}"
    assert dut.uio_out.value == 0x00, "uio_out changed unexpectedly"
    assert dut.uio_oe.value == 0xFF, "uio_oe changed unexpectedly"

    dut._log.info("Checking lead tone toggles (D#6 half-period = 4018 cycles)...")
    # One cycle later the tone generator fires its first toggle (lead_note is now D#6).
    # Advance 2 cycles to land well within the first half-period and confirm the output
    # has gone from 0 to 1.
    lead_out_before = int(dut.uo_out.value) & 0x01
    await ClockCycles(dut.clk, 2)
    await Timer(1, unit="ns")
    lead_out_after = int(dut.uo_out.value) & 0x01
    assert lead_out_after != lead_out_before, \
        f"Lead tone should have toggled: before={lead_out_before}, after={lead_out_after}"

    dut._log.info("Nyan Cat test passed!")
