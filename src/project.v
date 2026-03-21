/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

// Outputs Nyan Cat lead melody PWM on uo_out[0] (connect to piezo speaker).
// Outputs Morse code "HELLO WORLD" on uo_out[7:1] and uio_out[7:0].
//
// Clock: 25 MHz expected.
// Music: note durations 115ms (2,875,000 cycles) and 231ms (5,775,000 cycles).
//        Tones generated as square waves via a toggle-on-half-period counter.
// Morse: clock divider 1,562,500 cycles per unit => 62.5 ms/unit => ~20 WPM.
//
// Note code assignments (for reference):
//   0: silence (@)
//   1: B1 (MIDI 35, 61.74 Hz, half_period 202477)
//   2: C#2 (MIDI 37, 69.30 Hz, half_period 180386)
//   3: D#2 (MIDI 39, 77.78 Hz, half_period 160706)
//   4: E2 (MIDI 40, 82.41 Hz, half_period 151686)
//   5: F#2 (MIDI 42, 92.50 Hz, half_period 135137)
//   6: G#2 (MIDI 44, 103.83 Hz, half_period 120394)
//   7: B2 (MIDI 47, 123.47 Hz, half_period 101238)
//   8: C#3 (MIDI 49, 138.59 Hz, half_period 90193)
//   9: D#3 (MIDI 51, 155.56 Hz, half_period 80353)
//  10: E3 (MIDI 52, 164.81 Hz, half_period 75843)
//  11: F#3 (MIDI 54, 185.00 Hz, half_period 67569)
//  12: G#3 (MIDI 56, 207.65 Hz, half_period 60197)
//  13: B3 (MIDI 59, 246.94 Hz, half_period 50619)
//  14: D#4 (MIDI 63, 311.13 Hz, half_period 40177)
//  15: E4 (MIDI 64, 329.63 Hz, half_period 37922)
//  16: F#4 (MIDI 66, 369.99 Hz, half_period 33784)
//  17: G#4 (MIDI 68, 415.30 Hz, half_period 30098)
//  18: A#4 (MIDI 70, 466.16 Hz, half_period 26815)
//  19: B4 (MIDI 71, 493.88 Hz, half_period 25310)
//  20: C#5 (MIDI 73, 554.37 Hz, half_period 22548)
//  21: D5 (MIDI 74, 587.33 Hz, half_period 21283)
//  22: D#5 (MIDI 75, 622.25 Hz, half_period 20088)
//  23: E5 (MIDI 76, 659.26 Hz, half_period 18961)
//  24: F#5 (MIDI 78, 739.99 Hz, half_period 16892)
//  25: G#5 (MIDI 80, 830.61 Hz, half_period 15049)
//  26: A#5 (MIDI 82, 932.33 Hz, half_period 13407)
//  27: B5 (MIDI 83, 987.77 Hz, half_period 12655)
//  28: C#6 (MIDI 85, 1108.73 Hz, half_period 11274)
//  29: D#6 (MIDI 87, 1244.51 Hz, half_period 10044)
//  30: E6 (MIDI 88, 1318.51 Hz, half_period 9480)
//  31: F#6 (MIDI 90, 1479.98 Hz, half_period 8446)
module tt_um_example (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock (25 MHz expected)
    input  wire       rst_n     // reset_n - low to reset
);

  // ========== MORSE CODE ("HELLO WORLD") on uo_out[7:1] and uio_out ==========
  // Clock divider: 1,562,500 cycles = 62.5 ms per Morse unit at 25 MHz (~20 WPM)
  localparam MORSE_DIV = 21'd1_562_500;

  reg [20:0] morse_div_cnt;
  reg        morse_tick;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      morse_div_cnt <= 21'd0;
      morse_tick    <= 1'b0;
    end else if (morse_div_cnt == MORSE_DIV - 21'd1) begin
      morse_div_cnt <= 21'd0;
      morse_tick    <= 1'b1;
    end else begin
      morse_div_cnt <= morse_div_cnt + 21'd1;
      morse_tick    <= 1'b0;
    end
  end

  // Morse ROM: {on_off[3], duration[2:0]}
  // "HELLO WORLD" sequence, 67 entries (indices 0-66).
  reg [3:0] morse_rom_data;
  always @(*) begin
    case (morse_step)
      // H: ....
      7'd0:  morse_rom_data = {1'b1, 3'd1}; // ON  dot
      7'd1:  morse_rom_data = {1'b0, 3'd1}; // OFF element gap
      7'd2:  morse_rom_data = {1'b1, 3'd1}; // ON  dot
      7'd3:  morse_rom_data = {1'b0, 3'd1}; // OFF element gap
      7'd4:  morse_rom_data = {1'b1, 3'd1}; // ON  dot
      7'd5:  morse_rom_data = {1'b0, 3'd1}; // OFF element gap
      7'd6:  morse_rom_data = {1'b1, 3'd1}; // ON  dot
      7'd7:  morse_rom_data = {1'b0, 3'd3}; // OFF char gap
      // E: .
      7'd8:  morse_rom_data = {1'b1, 3'd1}; // ON  dot
      7'd9:  morse_rom_data = {1'b0, 3'd3}; // OFF char gap
      // L: .-..
      7'd10: morse_rom_data = {1'b1, 3'd1}; // ON  dot
      7'd11: morse_rom_data = {1'b0, 3'd1}; // OFF element gap
      7'd12: morse_rom_data = {1'b1, 3'd3}; // ON  dash
      7'd13: morse_rom_data = {1'b0, 3'd1}; // OFF element gap
      7'd14: morse_rom_data = {1'b1, 3'd1}; // ON  dot
      7'd15: morse_rom_data = {1'b0, 3'd1}; // OFF element gap
      7'd16: morse_rom_data = {1'b1, 3'd1}; // ON  dot
      7'd17: morse_rom_data = {1'b0, 3'd3}; // OFF char gap
      // L: .-..
      7'd18: morse_rom_data = {1'b1, 3'd1}; // ON  dot
      7'd19: morse_rom_data = {1'b0, 3'd1}; // OFF element gap
      7'd20: morse_rom_data = {1'b1, 3'd3}; // ON  dash
      7'd21: morse_rom_data = {1'b0, 3'd1}; // OFF element gap
      7'd22: morse_rom_data = {1'b1, 3'd1}; // ON  dot
      7'd23: morse_rom_data = {1'b0, 3'd1}; // OFF element gap
      7'd24: morse_rom_data = {1'b1, 3'd1}; // ON  dot
      7'd25: morse_rom_data = {1'b0, 3'd3}; // OFF char gap
      // O: ---
      7'd26: morse_rom_data = {1'b1, 3'd3}; // ON  dash
      7'd27: morse_rom_data = {1'b0, 3'd1}; // OFF element gap
      7'd28: morse_rom_data = {1'b1, 3'd3}; // ON  dash
      7'd29: morse_rom_data = {1'b0, 3'd1}; // OFF element gap
      7'd30: morse_rom_data = {1'b1, 3'd3}; // ON  dash
      7'd31: morse_rom_data = {1'b0, 3'd7}; // OFF word gap
      // W: .--
      7'd32: morse_rom_data = {1'b1, 3'd1}; // ON  dot
      7'd33: morse_rom_data = {1'b0, 3'd1}; // OFF element gap
      7'd34: morse_rom_data = {1'b1, 3'd3}; // ON  dash
      7'd35: morse_rom_data = {1'b0, 3'd1}; // OFF element gap
      7'd36: morse_rom_data = {1'b1, 3'd3}; // ON  dash
      7'd37: morse_rom_data = {1'b0, 3'd3}; // OFF char gap
      // O: ---
      7'd38: morse_rom_data = {1'b1, 3'd3}; // ON  dash
      7'd39: morse_rom_data = {1'b0, 3'd1}; // OFF element gap
      7'd40: morse_rom_data = {1'b1, 3'd3}; // ON  dash
      7'd41: morse_rom_data = {1'b0, 3'd1}; // OFF element gap
      7'd42: morse_rom_data = {1'b1, 3'd3}; // ON  dash
      7'd43: morse_rom_data = {1'b0, 3'd3}; // OFF char gap
      // R: .-.
      7'd44: morse_rom_data = {1'b1, 3'd1}; // ON  dot
      7'd45: morse_rom_data = {1'b0, 3'd1}; // OFF element gap
      7'd46: morse_rom_data = {1'b1, 3'd3}; // ON  dash
      7'd47: morse_rom_data = {1'b0, 3'd1}; // OFF element gap
      7'd48: morse_rom_data = {1'b1, 3'd1}; // ON  dot
      7'd49: morse_rom_data = {1'b0, 3'd3}; // OFF char gap
      // L: .-..
      7'd50: morse_rom_data = {1'b1, 3'd1}; // ON  dot
      7'd51: morse_rom_data = {1'b0, 3'd1}; // OFF element gap
      7'd52: morse_rom_data = {1'b1, 3'd3}; // ON  dash
      7'd53: morse_rom_data = {1'b0, 3'd1}; // OFF element gap
      7'd54: morse_rom_data = {1'b1, 3'd1}; // ON  dot
      7'd55: morse_rom_data = {1'b0, 3'd1}; // OFF element gap
      7'd56: morse_rom_data = {1'b1, 3'd1}; // ON  dot
      7'd57: morse_rom_data = {1'b0, 3'd3}; // OFF char gap
      // D: -..
      7'd58: morse_rom_data = {1'b1, 3'd3}; // ON  dash
      7'd59: morse_rom_data = {1'b0, 3'd1}; // OFF element gap
      7'd60: morse_rom_data = {1'b1, 3'd1}; // ON  dot
      7'd61: morse_rom_data = {1'b0, 3'd1}; // OFF element gap
      7'd62: morse_rom_data = {1'b1, 3'd1}; // ON  dot
      // 4-space word gap before repeating
      7'd63: morse_rom_data = {1'b0, 3'd7}; // OFF word gap 1/4
      7'd64: morse_rom_data = {1'b0, 3'd7}; // OFF word gap 2/4
      7'd65: morse_rom_data = {1'b0, 3'd7}; // OFF word gap 3/4
      7'd66: morse_rom_data = {1'b0, 3'd7}; // OFF word gap 4/4
      default: morse_rom_data = {1'b0, 3'd1};
    endcase
  end

  reg [6:0] morse_step;
  reg [2:0] morse_unit;
  reg       morse_out;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      morse_step <= 7'd0;
      morse_unit <= 3'd0;
      morse_out  <= 1'b0;
    end else if (morse_tick) begin
      morse_out <= morse_rom_data[3];
      if (morse_unit == morse_rom_data[2:0] - 3'd1) begin
        morse_unit <= 3'd0;
        morse_step <= (morse_step == 7'd66) ? 7'd0 : morse_step + 7'd1;
      end else begin
        morse_unit <= morse_unit + 3'd1;
      end
    end
  end

  // ========== NYAN CAT LEAD MELODY on uo_out[0] (piezo speaker PWM) ==========
  // Duration units at 25 MHz: 115ms = 2,875,000 cycles, 231ms = 5,775,000 cycles
  // 242 notes in one loop, then restarts.
  localparam DUR_115 = 23'd2_874_999;  // 115ms - 1 at 25 MHz
  localparam DUR_231 = 23'd5_774_999;  // 231ms - 1 at 25 MHz

  // Music ROM: {dur_flag[5], note_code[4:0]}
  // dur_flag=0 -> 115ms, dur_flag=1 -> 231ms
  // note_code=0 -> silence, 1-31 -> note frequencies
  reg  [5:0] music_rom;
  reg  [7:0] music_step;  // 0-241

  always @(*) begin
    case (music_step)
      8'd  0: music_rom = 6'b0_10110;  // D#5/115
      8'd  1: music_rom = 6'b0_10111;  // E5/115
      8'd  2: music_rom = 6'b1_11000;  // F#5/231
      8'd  3: music_rom = 6'b1_11011;  // B5/231
      8'd  4: music_rom = 6'b0_10110;  // D#5/115
      8'd  5: music_rom = 6'b0_10111;  // E5/115
      8'd  6: music_rom = 6'b0_11000;  // F#5/115
      8'd  7: music_rom = 6'b0_11011;  // B5/115
      8'd  8: music_rom = 6'b0_11100;  // C#6/115
      8'd  9: music_rom = 6'b0_11101;  // D#6/115
      8'd 10: music_rom = 6'b0_11100;  // C#6/115
      8'd 11: music_rom = 6'b0_11111;  // F#6/115
      8'd 12: music_rom = 6'b1_11011;  // B5/231
      8'd 13: music_rom = 6'b1_11000;  // F#5/231
      8'd 14: music_rom = 6'b0_10110;  // D#5/115
      8'd 15: music_rom = 6'b0_10111;  // E5/115
      8'd 16: music_rom = 6'b1_11000;  // F#5/231
      8'd 17: music_rom = 6'b1_11011;  // B5/231
      8'd 18: music_rom = 6'b0_11100;  // C#6/115
      8'd 19: music_rom = 6'b0_11010;  // A#5/115
      8'd 20: music_rom = 6'b0_11011;  // B5/115
      8'd 21: music_rom = 6'b0_11100;  // C#6/115
      8'd 22: music_rom = 6'b0_11110;  // E6/115
      8'd 23: music_rom = 6'b0_11101;  // D#6/115
      8'd 24: music_rom = 6'b0_11110;  // E6/115
      8'd 25: music_rom = 6'b0_11100;  // C#6/115
      8'd 26: music_rom = 6'b1_00100;  // E2/231
      8'd 27: music_rom = 6'b1_01010;  // E3/231
      8'd 28: music_rom = 6'b0_10110;  // D#5/115
      8'd 29: music_rom = 6'b0_10110;  // D#5/115
      8'd 30: music_rom = 6'b0_01011;  // F#3/115
      8'd 31: music_rom = 6'b0_10011;  // B4/115
      8'd 32: music_rom = 6'b0_10101;  // D5/115
      8'd 33: music_rom = 6'b0_10100;  // C#5/115
      8'd 34: music_rom = 6'b0_10011;  // B4/115
      8'd 35: music_rom = 6'b0_00000;  // @/115
      8'd 36: music_rom = 6'b1_00110;  // G#2/231
      8'd 37: music_rom = 6'b1_01100;  // G#3/231
      8'd 38: music_rom = 6'b1_00010;  // C#2/231
      8'd 39: music_rom = 6'b0_10101;  // D5/115
      8'd 40: music_rom = 6'b0_10100;  // C#5/115
      8'd 41: music_rom = 6'b0_10011;  // B4/115
      8'd 42: music_rom = 6'b0_10100;  // C#5/115
      8'd 43: music_rom = 6'b0_10110;  // D#5/115
      8'd 44: music_rom = 6'b0_11000;  // F#5/115
      8'd 45: music_rom = 6'b0_11001;  // G#5/115
      8'd 46: music_rom = 6'b0_10110;  // D#5/115
      8'd 47: music_rom = 6'b0_11000;  // F#5/115
      8'd 48: music_rom = 6'b0_10100;  // C#5/115
      8'd 49: music_rom = 6'b0_10110;  // D#5/115
      8'd 50: music_rom = 6'b0_10011;  // B4/115
      8'd 51: music_rom = 6'b0_10100;  // C#5/115
      8'd 52: music_rom = 6'b0_10011;  // B4/115
      8'd 53: music_rom = 6'b1_00100;  // E2/231
      8'd 54: music_rom = 6'b1_01010;  // E3/231
      8'd 55: music_rom = 6'b0_11001;  // G#5/115
      8'd 56: music_rom = 6'b0_10110;  // D#5/115
      8'd 57: music_rom = 6'b0_11000;  // F#5/115
      8'd 58: music_rom = 6'b0_10100;  // C#5/115
      8'd 59: music_rom = 6'b0_10110;  // D#5/115
      8'd 60: music_rom = 6'b0_10011;  // B4/115
      8'd 61: music_rom = 6'b0_10101;  // D5/115
      8'd 62: music_rom = 6'b0_10110;  // D#5/115
      8'd 63: music_rom = 6'b0_10101;  // D5/115
      8'd 64: music_rom = 6'b0_10100;  // C#5/115
      8'd 65: music_rom = 6'b0_10011;  // B4/115
      8'd 66: music_rom = 6'b0_10100;  // C#5/115
      8'd 67: music_rom = 6'b1_00010;  // C#2/231
      8'd 68: music_rom = 6'b0_10011;  // B4/115
      8'd 69: music_rom = 6'b0_10100;  // C#5/115
      8'd 70: music_rom = 6'b0_10110;  // D#5/115
      8'd 71: music_rom = 6'b0_11000;  // F#5/115
      8'd 72: music_rom = 6'b0_10100;  // C#5/115
      8'd 73: music_rom = 6'b0_10110;  // D#5/115
      8'd 74: music_rom = 6'b0_10100;  // C#5/115
      8'd 75: music_rom = 6'b0_10011;  // B4/115
      8'd 76: music_rom = 6'b1_00111;  // B2/231
      8'd 77: music_rom = 6'b1_00001;  // B1/231
      8'd 78: music_rom = 6'b1_00111;  // B2/231
      8'd 79: music_rom = 6'b1_00100;  // E2/231
      8'd 80: music_rom = 6'b1_01010;  // E3/231
      8'd 81: music_rom = 6'b0_10110;  // D#5/115
      8'd 82: music_rom = 6'b0_10110;  // D#5/115
      8'd 83: music_rom = 6'b0_01011;  // F#3/115
      8'd 84: music_rom = 6'b0_10011;  // B4/115
      8'd 85: music_rom = 6'b0_10101;  // D5/115
      8'd 86: music_rom = 6'b0_10100;  // C#5/115
      8'd 87: music_rom = 6'b0_10011;  // B4/115
      8'd 88: music_rom = 6'b0_00000;  // @/115
      8'd 89: music_rom = 6'b1_00110;  // G#2/231
      8'd 90: music_rom = 6'b1_01100;  // G#3/231
      8'd 91: music_rom = 6'b1_00010;  // C#2/231
      8'd 92: music_rom = 6'b0_10101;  // D5/115
      8'd 93: music_rom = 6'b0_10100;  // C#5/115
      8'd 94: music_rom = 6'b0_10011;  // B4/115
      8'd 95: music_rom = 6'b0_10100;  // C#5/115
      8'd 96: music_rom = 6'b0_10110;  // D#5/115
      8'd 97: music_rom = 6'b0_11000;  // F#5/115
      8'd 98: music_rom = 6'b0_11001;  // G#5/115
      8'd 99: music_rom = 6'b0_10110;  // D#5/115
      8'd100: music_rom = 6'b0_11000;  // F#5/115
      8'd101: music_rom = 6'b0_10100;  // C#5/115
      8'd102: music_rom = 6'b0_10110;  // D#5/115
      8'd103: music_rom = 6'b0_10011;  // B4/115
      8'd104: music_rom = 6'b0_10100;  // C#5/115
      8'd105: music_rom = 6'b0_10011;  // B4/115
      8'd106: music_rom = 6'b1_00100;  // E2/231
      8'd107: music_rom = 6'b1_01010;  // E3/231
      8'd108: music_rom = 6'b0_11001;  // G#5/115
      8'd109: music_rom = 6'b0_10110;  // D#5/115
      8'd110: music_rom = 6'b0_11000;  // F#5/115
      8'd111: music_rom = 6'b0_10100;  // C#5/115
      8'd112: music_rom = 6'b0_10110;  // D#5/115
      8'd113: music_rom = 6'b0_10011;  // B4/115
      8'd114: music_rom = 6'b0_10101;  // D5/115
      8'd115: music_rom = 6'b0_10110;  // D#5/115
      8'd116: music_rom = 6'b0_10101;  // D5/115
      8'd117: music_rom = 6'b0_10100;  // C#5/115
      8'd118: music_rom = 6'b0_10011;  // B4/115
      8'd119: music_rom = 6'b0_10100;  // C#5/115
      8'd120: music_rom = 6'b1_00010;  // C#2/231
      8'd121: music_rom = 6'b0_10011;  // B4/115
      8'd122: music_rom = 6'b0_10100;  // C#5/115
      8'd123: music_rom = 6'b0_10110;  // D#5/115
      8'd124: music_rom = 6'b0_11000;  // F#5/115
      8'd125: music_rom = 6'b0_10100;  // C#5/115
      8'd126: music_rom = 6'b0_10110;  // D#5/115
      8'd127: music_rom = 6'b0_10100;  // C#5/115
      8'd128: music_rom = 6'b0_10011;  // B4/115
      8'd129: music_rom = 6'b1_00111;  // B2/231
      8'd130: music_rom = 6'b1_00001;  // B1/231
      8'd131: music_rom = 6'b1_00111;  // B2/231
      8'd132: music_rom = 6'b1_01010;  // E3/231
      8'd133: music_rom = 6'b0_10000;  // F#4/115
      8'd134: music_rom = 6'b0_10001;  // G#4/115
      8'd135: music_rom = 6'b1_01101;  // B3/231
      8'd136: music_rom = 6'b0_10000;  // F#4/115
      8'd137: music_rom = 6'b0_10001;  // G#4/115
      8'd138: music_rom = 6'b0_10011;  // B4/115
      8'd139: music_rom = 6'b0_10100;  // C#5/115
      8'd140: music_rom = 6'b0_10110;  // D#5/115
      8'd141: music_rom = 6'b0_10011;  // B4/115
      8'd142: music_rom = 6'b0_10111;  // E5/115
      8'd143: music_rom = 6'b0_10110;  // D#5/115
      8'd144: music_rom = 6'b0_10111;  // E5/115
      8'd145: music_rom = 6'b0_11000;  // F#5/115
      8'd146: music_rom = 6'b1_01000;  // C#3/231
      8'd147: music_rom = 6'b1_01010;  // E3/231
      8'd148: music_rom = 6'b0_10000;  // F#4/115
      8'd149: music_rom = 6'b0_10001;  // G#4/115
      8'd150: music_rom = 6'b0_10011;  // B4/115
      8'd151: music_rom = 6'b0_10000;  // F#4/115
      8'd152: music_rom = 6'b0_10111;  // E5/115
      8'd153: music_rom = 6'b0_10110;  // D#5/115
      8'd154: music_rom = 6'b0_10100;  // C#5/115
      8'd155: music_rom = 6'b0_10011;  // B4/115
      8'd156: music_rom = 6'b0_10000;  // F#4/115
      8'd157: music_rom = 6'b0_01110;  // D#4/115
      8'd158: music_rom = 6'b0_01111;  // E4/115
      8'd159: music_rom = 6'b0_10000;  // F#4/115
      8'd160: music_rom = 6'b1_01010;  // E3/231
      8'd161: music_rom = 6'b0_10000;  // F#4/115
      8'd162: music_rom = 6'b0_10001;  // G#4/115
      8'd163: music_rom = 6'b1_01101;  // B3/231
      8'd164: music_rom = 6'b0_10000;  // F#4/115
      8'd165: music_rom = 6'b0_10001;  // G#4/115
      8'd166: music_rom = 6'b0_10011;  // B4/115
      8'd167: music_rom = 6'b0_10011;  // B4/115
      8'd168: music_rom = 6'b0_10100;  // C#5/115
      8'd169: music_rom = 6'b0_10110;  // D#5/115
      8'd170: music_rom = 6'b0_10011;  // B4/115
      8'd171: music_rom = 6'b0_10000;  // F#4/115
      8'd172: music_rom = 6'b0_10001;  // G#4/115
      8'd173: music_rom = 6'b0_10000;  // F#4/115
      8'd174: music_rom = 6'b1_01000;  // C#3/231
      8'd175: music_rom = 6'b0_10011;  // B4/115
      8'd176: music_rom = 6'b0_10010;  // A#4/115
      8'd177: music_rom = 6'b0_10011;  // B4/115
      8'd178: music_rom = 6'b0_10000;  // F#4/115
      8'd179: music_rom = 6'b0_10001;  // G#4/115
      8'd180: music_rom = 6'b0_10011;  // B4/115
      8'd181: music_rom = 6'b0_10111;  // E5/115
      8'd182: music_rom = 6'b0_10110;  // D#5/115
      8'd183: music_rom = 6'b0_10111;  // E5/115
      8'd184: music_rom = 6'b0_11000;  // F#5/115
      8'd185: music_rom = 6'b1_01011;  // F#3/231
      8'd186: music_rom = 6'b1_01101;  // B3/231
      8'd187: music_rom = 6'b1_01010;  // E3/231
      8'd188: music_rom = 6'b0_10000;  // F#4/115
      8'd189: music_rom = 6'b0_10001;  // G#4/115
      8'd190: music_rom = 6'b1_01101;  // B3/231
      8'd191: music_rom = 6'b0_10000;  // F#4/115
      8'd192: music_rom = 6'b0_10001;  // G#4/115
      8'd193: music_rom = 6'b0_10011;  // B4/115
      8'd194: music_rom = 6'b0_10100;  // C#5/115
      8'd195: music_rom = 6'b0_10110;  // D#5/115
      8'd196: music_rom = 6'b0_10011;  // B4/115
      8'd197: music_rom = 6'b0_10111;  // E5/115
      8'd198: music_rom = 6'b0_10110;  // D#5/115
      8'd199: music_rom = 6'b0_10111;  // E5/115
      8'd200: music_rom = 6'b0_11000;  // F#5/115
      8'd201: music_rom = 6'b1_01000;  // C#3/231
      8'd202: music_rom = 6'b1_01010;  // E3/231
      8'd203: music_rom = 6'b0_10000;  // F#4/115
      8'd204: music_rom = 6'b0_10001;  // G#4/115
      8'd205: music_rom = 6'b0_10011;  // B4/115
      8'd206: music_rom = 6'b0_10000;  // F#4/115
      8'd207: music_rom = 6'b0_10111;  // E5/115
      8'd208: music_rom = 6'b0_10110;  // D#5/115
      8'd209: music_rom = 6'b0_10100;  // C#5/115
      8'd210: music_rom = 6'b0_10101;  // D5/115
      8'd211: music_rom = 6'b0_10000;  // F#4/115
      8'd212: music_rom = 6'b0_01110;  // D#4/115
      8'd213: music_rom = 6'b0_01111;  // E4/115
      8'd214: music_rom = 6'b0_10000;  // F#4/115
      8'd215: music_rom = 6'b1_01010;  // E3/231
      8'd216: music_rom = 6'b0_10000;  // F#4/115
      8'd217: music_rom = 6'b0_10001;  // G#4/115
      8'd218: music_rom = 6'b1_01101;  // B3/231
      8'd219: music_rom = 6'b0_10000;  // F#4/115
      8'd220: music_rom = 6'b0_10001;  // G#4/115
      8'd221: music_rom = 6'b0_10011;  // B4/115
      8'd222: music_rom = 6'b0_10011;  // B4/115
      8'd223: music_rom = 6'b0_10100;  // C#5/115
      8'd224: music_rom = 6'b0_10110;  // D#5/115
      8'd225: music_rom = 6'b0_10011;  // B4/115
      8'd226: music_rom = 6'b0_10000;  // F#4/115
      8'd227: music_rom = 6'b0_10001;  // G#4/115
      8'd228: music_rom = 6'b0_10000;  // F#4/115
      8'd229: music_rom = 6'b1_01000;  // C#3/231
      8'd230: music_rom = 6'b0_10011;  // B4/115
      8'd231: music_rom = 6'b0_10010;  // A#4/115
      8'd232: music_rom = 6'b0_10011;  // B4/115
      8'd233: music_rom = 6'b0_10000;  // F#4/115
      8'd234: music_rom = 6'b0_10001;  // G#4/115
      8'd235: music_rom = 6'b0_10011;  // B4/115
      8'd236: music_rom = 6'b0_10111;  // E5/115
      8'd237: music_rom = 6'b0_10110;  // D#5/115
      8'd238: music_rom = 6'b0_10111;  // E5/115
      8'd239: music_rom = 6'b0_11000;  // F#5/115
      8'd240: music_rom = 6'b1_01011;  // F#3/231
      8'd241: music_rom = 6'b1_01101;  // B3/231
      default: music_rom = 6'b0_00000;  // silence
    endcase
  end

  // Note half-period lookup (18-bit): cycles = CLK_FREQ / (2 * note_freq)
  wire [4:0] note_code = music_rom[4:0];
  reg [17:0] note_hp;
  always @(*) begin
    case (note_code)
      5'd0:  note_hp = 18'd0;  // silence
      5'd1:  note_hp = 18'd202477;  // B1 (61.74 Hz)
      5'd2:  note_hp = 18'd180386;  // C#2 (69.30 Hz)
      5'd3:  note_hp = 18'd160706;  // D#2 (77.78 Hz)
      5'd4:  note_hp = 18'd151686;  // E2 (82.41 Hz)
      5'd5:  note_hp = 18'd135137;  // F#2 (92.50 Hz)
      5'd6:  note_hp = 18'd120394;  // G#2 (103.83 Hz)
      5'd7:  note_hp = 18'd101238;  // B2 (123.47 Hz)
      5'd8:  note_hp = 18'd90193;  // C#3 (138.59 Hz)
      5'd9:  note_hp = 18'd80353;  // D#3 (155.56 Hz)
      5'd10:  note_hp = 18'd75843;  // E3 (164.81 Hz)
      5'd11:  note_hp = 18'd67569;  // F#3 (185.00 Hz)
      5'd12:  note_hp = 18'd60197;  // G#3 (207.65 Hz)
      5'd13:  note_hp = 18'd50619;  // B3 (246.94 Hz)
      5'd14:  note_hp = 18'd40177;  // D#4 (311.13 Hz)
      5'd15:  note_hp = 18'd37922;  // E4 (329.63 Hz)
      5'd16:  note_hp = 18'd33784;  // F#4 (369.99 Hz)
      5'd17:  note_hp = 18'd30098;  // G#4 (415.30 Hz)
      5'd18:  note_hp = 18'd26815;  // A#4 (466.16 Hz)
      5'd19:  note_hp = 18'd25310;  // B4 (493.88 Hz)
      5'd20:  note_hp = 18'd22548;  // C#5 (554.37 Hz)
      5'd21:  note_hp = 18'd21283;  // D5 (587.33 Hz)
      5'd22:  note_hp = 18'd20088;  // D#5 (622.25 Hz)
      5'd23:  note_hp = 18'd18961;  // E5 (659.26 Hz)
      5'd24:  note_hp = 18'd16892;  // F#5 (739.99 Hz)
      5'd25:  note_hp = 18'd15049;  // G#5 (830.61 Hz)
      5'd26:  note_hp = 18'd13407;  // A#5 (932.33 Hz)
      5'd27:  note_hp = 18'd12655;  // B5 (987.77 Hz)
      5'd28:  note_hp = 18'd11274;  // C#6 (1108.73 Hz)
      5'd29:  note_hp = 18'd10044;  // D#6 (1244.51 Hz)
      5'd30:  note_hp = 18'd9480;  // E6 (1318.51 Hz)
      5'd31:  note_hp = 18'd8446;  // F#6 (1479.98 Hz)
      default: note_hp = 18'd0;
    endcase
  end

  wire [22:0] dur_max = music_rom[5] ? DUR_231 : DUR_115;

  reg [22:0] dur_cnt;   // counts up to dur_max
  reg [17:0] pwm_cnt;   // counts up to note_hp-1
  reg        pwm_out;   // toggled PWM output

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      music_step <= 8'd0;
      dur_cnt    <= 23'd0;
      pwm_cnt    <= 18'd0;
      pwm_out    <= 1'b0;
    end else begin
      if (dur_cnt == dur_max) begin
        // Advance to next note and reset PWM for clean transition
        music_step <= (music_step == 8'd241) ? 8'd0 : music_step + 8'd1;
        dur_cnt    <= 23'd0;
        pwm_cnt    <= 18'd0;
        pwm_out    <= 1'b0;
      end else begin
        dur_cnt <= dur_cnt + 23'd1;
        if (note_hp == 18'd0) begin
          // Silence: hold output low
          pwm_out <= 1'b0;
          pwm_cnt <= 18'd0;
        end else if (pwm_cnt == note_hp - 18'd1) begin
          pwm_cnt <= 18'd0;
          pwm_out <= ~pwm_out;
        end else begin
          pwm_cnt <= pwm_cnt + 18'd1;
        end
      end
    end
  end

  // Output assignments:
  //   uo_out[0]   = piezo speaker PWM (Nyan Cat lead melody)
  //   uo_out[7:1] = Morse code "HELLO WORLD" (7 identical bits)
  //   uio_out     = Morse code "HELLO WORLD" (8 identical bits)
  assign uo_out  = {{7{morse_out}}, pwm_out};
  assign uio_out = {8{morse_out}};
  assign uio_oe  = 8'hFF;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, ui_in, uio_in, 1'b0};

endmodule
