# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # Clock: 25 MHz = 40 ns period
    clock = Clock(dut.clk, 40, unit="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    # After reset all outputs must be 0, bidirectional pins all configured as outputs.
    await Timer(1, unit="ns")
    assert dut.uo_out.value == 0x00, \
        f"After reset: expected uo_out=0x00, got {hex(int(dut.uo_out.value))}"
    assert dut.uio_out.value == 0x00, \
        f"After reset: expected uio_out=0x00, got {hex(int(dut.uio_out.value))}"
    assert dut.uio_oe.value == 0xFF, \
        f"Expected uio_oe=0xFF, got {hex(int(dut.uio_oe.value))}"

    dut._log.info("Verify PWM output on uo_out[0] for first note (D#5, ~622 Hz)")

    # First music note: D#5/115ms.
    # At 25 MHz the half-period is 20088 cycles; PWM toggles every 20088 cycles.
    # After reset: PWM starts low, goes high after 20088 cycles, low after 40176, ...
    D5SHARP_HALF_PERIOD = 20088

    await ClockCycles(dut.clk, D5SHARP_HALF_PERIOD)
    await Timer(1, unit="ns")
    pwm_val = int(dut.uo_out.value) & 0x01
    assert pwm_val == 1, \
        f"Expected PWM high after {D5SHARP_HALF_PERIOD} cycles, got {pwm_val}"

    await ClockCycles(dut.clk, D5SHARP_HALF_PERIOD)
    await Timer(1, unit="ns")
    pwm_val = int(dut.uo_out.value) & 0x01
    assert pwm_val == 0, \
        f"Expected PWM low after {2 * D5SHARP_HALF_PERIOD} cycles, got {pwm_val}"

    dut._log.info("PWM output verified for D#5")

    dut._log.info("Verify Morse code appears on uo_out[7:1] and uio_out after first Morse unit")
    # Morse clock divider: 1,562,500 cycles per unit.
    # The divider starts from 0 when rst_n goes high.
    # At cycle 1,562,499 (since rst) the divider fires (morse_tick is scheduled to 1 via NBA).
    # At cycle 1,562,500 (one cycle later), the Morse state machine sees morse_tick=1 and
    # updates morse_out (also via NBA).  We therefore need to wait until cycle 1,562,501 to
    # sample the updated morse_out after the NBA settle.
    #
    # We've already consumed 2 * D5SHARP_HALF_PERIOD = 40176 cycles since rst.
    MORSE_DIV = 1_562_500
    cycles_since_rst = 2 * D5SHARP_HALF_PERIOD  # 40176
    # +1 to cross from the tick cycle into the output-update cycle
    remaining = MORSE_DIV - (cycles_since_rst % MORSE_DIV) + 1
    await ClockCycles(dut.clk, remaining)
    await Timer(1, unit="ns")

    # H dot1 is ON, so uo_out[7:1] must all be 1 and uio_out must be 0xFF.
    morse_bits = (int(dut.uo_out.value) >> 1) & 0x7F
    assert morse_bits == 0x7F, \
        f"Expected Morse bits 0x7F after first Morse tick, got {hex(morse_bits)}"
    assert int(dut.uio_out.value) == 0xFF, \
        f"Expected uio_out=0xFF after first Morse tick, got {hex(int(dut.uio_out.value))}"

    dut._log.info("Morse output verified")
    dut._log.info("All tests passed!")
