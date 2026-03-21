<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

All 16 output pins (8 dedicated outputs `uo` and 8 bidirectional `uio` configured as outputs)
blink together to transmit the message **"HELLO WORLD"** in Morse code, then repeat continuously.

### Timing (standard Morse code at 20 WPM, 10 MHz clock)

| Symbol | Duration |
|--------|----------|
| Dot (·) | 1 unit = 60 ms = 600,000 clock cycles |
| Dash (−) | 3 units = 180 ms |
| Element gap (between dots/dashes within a character) | 1 unit |
| Character gap | 3 units |
| Word gap | 7 units |

### Morse code sequence

| Letter | Code |
|--------|------|
| H | `....` |
| E | `.` |
| L | `.-..` |
| L | `.-..` |
| O | `---` |
| (space) | 7-unit gap |
| W | `.--` |
| O | `---` |
| R | `.-.` |
| L | `.-..` |
| D | `-..` |

After the final letter D, a 7-unit word gap is inserted before the sequence repeats.

## How to test

Connect LEDs (or a logic analyser) to any of the 16 output pins.
Power the device with a 10 MHz clock. After releasing reset (`rst_n` high), all outputs will
blink the Morse code for "HELLO WORLD" at 20 WPM and loop indefinitely.

No inputs are required; `ui_in` and `uio_in` are ignored.

## External hardware

LEDs connected to `uo[0..7]` or `uio[0..7]` (with appropriate current-limiting resistors)
will visibly display the Morse code message.
