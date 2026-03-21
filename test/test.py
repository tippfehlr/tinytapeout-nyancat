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

    # After reset all outputs must be 0; bidirectional pins configured as outputs.
    await Timer(1, unit="ns")
    assert dut.uo_out.value == 0x00, \
        f"After reset: expected uo_out=0x00, got {hex(int(dut.uo_out.value))}"
    assert dut.uio_out.value == 0x00, \
        f"After reset: expected uio_out=0x00, got {hex(int(dut.uio_out.value))}"
    assert dut.uio_oe.value == 0xFF, \
        f"Expected uio_oe=0xFF, got {hex(int(dut.uio_oe.value))}"
    assert (int(dut.uo_out.value) & 0xFC) == 0x00, \
        f"Expected uo_out[7:2]=0 after reset, got {hex(int(dut.uo_out.value))}"

    dut._log.info("Verify lead PWM on uo_out[0] for first note (D#5, ~622 Hz)")

    # First lead note: D#5/115ms.
    # At 25 MHz the half-period is 20088 cycles.
    # After reset, lead_pwm_cnt starts at 0 and increments each edge.
    # Toggle condition: pwm_cnt == hp - 1 == 20087.
    # At edge 10+20088 (10 reset + 20088 post-rst), pwm_cnt = 20087 -> toggle -> lead_pwm = 1.
    LEAD_D5SHARP_HP = 20088   # half-period in cycles

    await ClockCycles(dut.clk, LEAD_D5SHARP_HP)
    await Timer(1, unit="ns")
    lead_pwm = int(dut.uo_out.value) & 0x01
    assert lead_pwm == 1, \
        f"Expected lead PWM high after {LEAD_D5SHARP_HP} edges post-rst, got {lead_pwm}"

    await ClockCycles(dut.clk, LEAD_D5SHARP_HP)
    await Timer(1, unit="ns")
    lead_pwm = int(dut.uo_out.value) & 0x01
    assert lead_pwm == 0, \
        f"Expected lead PWM low after {2 * LEAD_D5SHARP_HP} edges post-rst, got {lead_pwm}"

    dut._log.info("Lead PWM verified for D#5")

    dut._log.info("Verify harmony PWM on uo_out[1] for first note (B3, ~247 Hz)")

    # First harmony note: B3/115ms (half-period = 50619 cycles).
    # After reset, harm_pwm_cnt starts at 0 and increments each edge.
    # Toggle condition: pwm_cnt == 50618.
    # We have consumed 2 * LEAD_D5SHARP_HP = 40176 edges since rst_n went high.
    # harm_pwm_cnt is currently 40176.
    # Remaining edges to first toggle: (50619 - 1) - 40176 = 10442.
    HARM_B3_HP = 50619   # half-period for B3 (246.94 Hz)

    cycles_since_rst = 2 * LEAD_D5SHARP_HP   # 40176
    remaining_to_first_toggle = HARM_B3_HP - (cycles_since_rst % HARM_B3_HP)

    await ClockCycles(dut.clk, remaining_to_first_toggle)
    await Timer(1, unit="ns")
    harm_pwm = (int(dut.uo_out.value) >> 1) & 0x01
    assert harm_pwm == 1, \
        f"Expected harmony PWM high at first B3 toggle, got {harm_pwm}"

    # After the toggle, counter resets to 0, so the next toggle is a full HARM_B3_HP later.
    await ClockCycles(dut.clk, HARM_B3_HP)
    await Timer(1, unit="ns")
    harm_pwm = (int(dut.uo_out.value) >> 1) & 0x01
    assert harm_pwm == 0, \
        f"Expected harmony PWM low at second B3 toggle, got {harm_pwm}"

    dut._log.info("Harmony PWM verified for B3")

    # Verify uo_out[7:2] remain 0 throughout
    assert (int(dut.uo_out.value) & 0xFC) == 0x00, \
        f"Expected uo_out[7:2]=0 throughout, got {hex(int(dut.uo_out.value))}"

    dut._log.info("All tests passed!")
