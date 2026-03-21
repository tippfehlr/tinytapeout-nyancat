/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

// Nyan Cat – lead melody PWM on uo_out[0], harmony PWM on uo_out[1].
//
// Clock: 25 MHz expected.
// Note durations at 25 MHz:
//   115 ms = 2,875,000 cycles   (half-note unit)
//   231 ms = 5,775,000 cycles   (eighth note)
//   346 ms = 8,650,000 cycles   (dotted eighth, harmony only)
//
// Both channels share the same 32-entry note half-period lookup table.
// They start in sync (both reset at cycle 0) and advance independently;
// total loop lengths differ by ~9 ms which is musically negligible.
//
// Note code table:
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
    input  wire       ena,      // always 1 when the design is powered
    input  wire       clk,      // clock (25 MHz expected)
    input  wire       rst_n     // reset_n - low to reset
);

  // ── Duration constants ──────────────────────────────────────────────────
  localparam DUR_115 = 23'd2874999;  // 115ms-1 at 25 MHz
  localparam DUR_231 = 23'd5774999;  // 231ms-1 at 25 MHz
  localparam DUR_346 = 24'd8649999;  // 346ms-1 at 25 MHz (harmony only)

  localparam LEAD_SEQ_LEN = 8'd242;  // number of lead melody entries
  localparam HARM_SEQ_LEN = 8'd227;  // number of harmony melody entries

  // ── Shared note half-period lookup ─────────────────────────────────────
  // Returns clock half-period for a given 5-bit note code (0=silence).
  // Used by both lead and harmony channels.
  function [17:0] note_hp;
    input [4:0] code;
    begin
      case (code)
        5'd0:  note_hp = 18'd0;  // silence
        5'd1: note_hp = 18'd202477;  // B1 (61.74 Hz)
        5'd2: note_hp = 18'd180386;  // C#2 (69.30 Hz)
        5'd3: note_hp = 18'd160706;  // D#2 (77.78 Hz)
        5'd4: note_hp = 18'd151686;  // E2 (82.41 Hz)
        5'd5: note_hp = 18'd135137;  // F#2 (92.50 Hz)
        5'd6: note_hp = 18'd120394;  // G#2 (103.83 Hz)
        5'd7: note_hp = 18'd101238;  // B2 (123.47 Hz)
        5'd8: note_hp = 18'd90193;  // C#3 (138.59 Hz)
        5'd9: note_hp = 18'd80353;  // D#3 (155.56 Hz)
        5'd10: note_hp = 18'd75843;  // E3 (164.81 Hz)
        5'd11: note_hp = 18'd67569;  // F#3 (185.00 Hz)
        5'd12: note_hp = 18'd60197;  // G#3 (207.65 Hz)
        5'd13: note_hp = 18'd50619;  // B3 (246.94 Hz)
        5'd14: note_hp = 18'd40177;  // D#4 (311.13 Hz)
        5'd15: note_hp = 18'd37922;  // E4 (329.63 Hz)
        5'd16: note_hp = 18'd33784;  // F#4 (369.99 Hz)
        5'd17: note_hp = 18'd30098;  // G#4 (415.30 Hz)
        5'd18: note_hp = 18'd26815;  // A#4 (466.16 Hz)
        5'd19: note_hp = 18'd25310;  // B4 (493.88 Hz)
        5'd20: note_hp = 18'd22548;  // C#5 (554.37 Hz)
        5'd21: note_hp = 18'd21283;  // D5 (587.33 Hz)
        5'd22: note_hp = 18'd20088;  // D#5 (622.25 Hz)
        5'd23: note_hp = 18'd18961;  // E5 (659.26 Hz)
        5'd24: note_hp = 18'd16892;  // F#5 (739.99 Hz)
        5'd25: note_hp = 18'd15049;  // G#5 (830.61 Hz)
        5'd26: note_hp = 18'd13407;  // A#5 (932.33 Hz)
        5'd27: note_hp = 18'd12655;  // B5 (987.77 Hz)
        5'd28: note_hp = 18'd11274;  // C#6 (1108.73 Hz)
        5'd29: note_hp = 18'd10044;  // D#6 (1244.51 Hz)
        5'd30: note_hp = 18'd9480;  // E6 (1318.51 Hz)
        5'd31: note_hp = 18'd8446;  // F#6 (1479.98 Hz)
        default: note_hp = 18'd0;
      endcase
    end
  endfunction

  // ── LEAD MELODY ROM ─────────────────────────────────────────────────────
  // Format: {1-bit dur_flag, 5-bit note_code}
  //   dur_flag=0 -> DUR_115, dur_flag=1 -> DUR_231
  // 242 entries (0-241), loops at 241+1
  reg [7:0] lead_step;  // 0-241
  reg [5:0] lead_rom;
  always @(*) begin
    case (lead_step)
      8'd  0: lead_rom = 6'b0_10110;  // D#5/115
      8'd  1: lead_rom = 6'b0_10111;  // E5/115
      8'd  2: lead_rom = 6'b1_11000;  // F#5/231
      8'd  3: lead_rom = 6'b1_11011;  // B5/231
      8'd  4: lead_rom = 6'b0_10110;  // D#5/115
      8'd  5: lead_rom = 6'b0_10111;  // E5/115
      8'd  6: lead_rom = 6'b0_11000;  // F#5/115
      8'd  7: lead_rom = 6'b0_11011;  // B5/115
      8'd  8: lead_rom = 6'b0_11100;  // C#6/115
      8'd  9: lead_rom = 6'b0_11101;  // D#6/115
      8'd 10: lead_rom = 6'b0_11100;  // C#6/115
      8'd 11: lead_rom = 6'b0_11111;  // F#6/115
      8'd 12: lead_rom = 6'b1_11011;  // B5/231
      8'd 13: lead_rom = 6'b1_11000;  // F#5/231
      8'd 14: lead_rom = 6'b0_10110;  // D#5/115
      8'd 15: lead_rom = 6'b0_10111;  // E5/115
      8'd 16: lead_rom = 6'b1_11000;  // F#5/231
      8'd 17: lead_rom = 6'b1_11011;  // B5/231
      8'd 18: lead_rom = 6'b0_11100;  // C#6/115
      8'd 19: lead_rom = 6'b0_11010;  // A#5/115
      8'd 20: lead_rom = 6'b0_11011;  // B5/115
      8'd 21: lead_rom = 6'b0_11100;  // C#6/115
      8'd 22: lead_rom = 6'b0_11110;  // E6/115
      8'd 23: lead_rom = 6'b0_11101;  // D#6/115
      8'd 24: lead_rom = 6'b0_11110;  // E6/115
      8'd 25: lead_rom = 6'b0_11100;  // C#6/115
      8'd 26: lead_rom = 6'b1_00100;  // E2/231
      8'd 27: lead_rom = 6'b1_01010;  // E3/231
      8'd 28: lead_rom = 6'b0_10110;  // D#5/115
      8'd 29: lead_rom = 6'b0_10110;  // D#5/115
      8'd 30: lead_rom = 6'b0_01011;  // F#3/115
      8'd 31: lead_rom = 6'b0_10011;  // B4/115
      8'd 32: lead_rom = 6'b0_10101;  // D5/115
      8'd 33: lead_rom = 6'b0_10100;  // C#5/115
      8'd 34: lead_rom = 6'b0_10011;  // B4/115
      8'd 35: lead_rom = 6'b0_00000;  // @/115
      8'd 36: lead_rom = 6'b1_00110;  // G#2/231
      8'd 37: lead_rom = 6'b1_01100;  // G#3/231
      8'd 38: lead_rom = 6'b1_00010;  // C#2/231
      8'd 39: lead_rom = 6'b0_10101;  // D5/115
      8'd 40: lead_rom = 6'b0_10100;  // C#5/115
      8'd 41: lead_rom = 6'b0_10011;  // B4/115
      8'd 42: lead_rom = 6'b0_10100;  // C#5/115
      8'd 43: lead_rom = 6'b0_10110;  // D#5/115
      8'd 44: lead_rom = 6'b0_11000;  // F#5/115
      8'd 45: lead_rom = 6'b0_11001;  // G#5/115
      8'd 46: lead_rom = 6'b0_10110;  // D#5/115
      8'd 47: lead_rom = 6'b0_11000;  // F#5/115
      8'd 48: lead_rom = 6'b0_10100;  // C#5/115
      8'd 49: lead_rom = 6'b0_10110;  // D#5/115
      8'd 50: lead_rom = 6'b0_10011;  // B4/115
      8'd 51: lead_rom = 6'b0_10100;  // C#5/115
      8'd 52: lead_rom = 6'b0_10011;  // B4/115
      8'd 53: lead_rom = 6'b1_00100;  // E2/231
      8'd 54: lead_rom = 6'b1_01010;  // E3/231
      8'd 55: lead_rom = 6'b0_11001;  // G#5/115
      8'd 56: lead_rom = 6'b0_10110;  // D#5/115
      8'd 57: lead_rom = 6'b0_11000;  // F#5/115
      8'd 58: lead_rom = 6'b0_10100;  // C#5/115
      8'd 59: lead_rom = 6'b0_10110;  // D#5/115
      8'd 60: lead_rom = 6'b0_10011;  // B4/115
      8'd 61: lead_rom = 6'b0_10101;  // D5/115
      8'd 62: lead_rom = 6'b0_10110;  // D#5/115
      8'd 63: lead_rom = 6'b0_10101;  // D5/115
      8'd 64: lead_rom = 6'b0_10100;  // C#5/115
      8'd 65: lead_rom = 6'b0_10011;  // B4/115
      8'd 66: lead_rom = 6'b0_10100;  // C#5/115
      8'd 67: lead_rom = 6'b1_00010;  // C#2/231
      8'd 68: lead_rom = 6'b0_10011;  // B4/115
      8'd 69: lead_rom = 6'b0_10100;  // C#5/115
      8'd 70: lead_rom = 6'b0_10110;  // D#5/115
      8'd 71: lead_rom = 6'b0_11000;  // F#5/115
      8'd 72: lead_rom = 6'b0_10100;  // C#5/115
      8'd 73: lead_rom = 6'b0_10110;  // D#5/115
      8'd 74: lead_rom = 6'b0_10100;  // C#5/115
      8'd 75: lead_rom = 6'b0_10011;  // B4/115
      8'd 76: lead_rom = 6'b1_00111;  // B2/231
      8'd 77: lead_rom = 6'b1_00001;  // B1/231
      8'd 78: lead_rom = 6'b1_00111;  // B2/231
      8'd 79: lead_rom = 6'b1_00100;  // E2/231
      8'd 80: lead_rom = 6'b1_01010;  // E3/231
      8'd 81: lead_rom = 6'b0_10110;  // D#5/115
      8'd 82: lead_rom = 6'b0_10110;  // D#5/115
      8'd 83: lead_rom = 6'b0_01011;  // F#3/115
      8'd 84: lead_rom = 6'b0_10011;  // B4/115
      8'd 85: lead_rom = 6'b0_10101;  // D5/115
      8'd 86: lead_rom = 6'b0_10100;  // C#5/115
      8'd 87: lead_rom = 6'b0_10011;  // B4/115
      8'd 88: lead_rom = 6'b0_00000;  // @/115
      8'd 89: lead_rom = 6'b1_00110;  // G#2/231
      8'd 90: lead_rom = 6'b1_01100;  // G#3/231
      8'd 91: lead_rom = 6'b1_00010;  // C#2/231
      8'd 92: lead_rom = 6'b0_10101;  // D5/115
      8'd 93: lead_rom = 6'b0_10100;  // C#5/115
      8'd 94: lead_rom = 6'b0_10011;  // B4/115
      8'd 95: lead_rom = 6'b0_10100;  // C#5/115
      8'd 96: lead_rom = 6'b0_10110;  // D#5/115
      8'd 97: lead_rom = 6'b0_11000;  // F#5/115
      8'd 98: lead_rom = 6'b0_11001;  // G#5/115
      8'd 99: lead_rom = 6'b0_10110;  // D#5/115
      8'd100: lead_rom = 6'b0_11000;  // F#5/115
      8'd101: lead_rom = 6'b0_10100;  // C#5/115
      8'd102: lead_rom = 6'b0_10110;  // D#5/115
      8'd103: lead_rom = 6'b0_10011;  // B4/115
      8'd104: lead_rom = 6'b0_10100;  // C#5/115
      8'd105: lead_rom = 6'b0_10011;  // B4/115
      8'd106: lead_rom = 6'b1_00100;  // E2/231
      8'd107: lead_rom = 6'b1_01010;  // E3/231
      8'd108: lead_rom = 6'b0_11001;  // G#5/115
      8'd109: lead_rom = 6'b0_10110;  // D#5/115
      8'd110: lead_rom = 6'b0_11000;  // F#5/115
      8'd111: lead_rom = 6'b0_10100;  // C#5/115
      8'd112: lead_rom = 6'b0_10110;  // D#5/115
      8'd113: lead_rom = 6'b0_10011;  // B4/115
      8'd114: lead_rom = 6'b0_10101;  // D5/115
      8'd115: lead_rom = 6'b0_10110;  // D#5/115
      8'd116: lead_rom = 6'b0_10101;  // D5/115
      8'd117: lead_rom = 6'b0_10100;  // C#5/115
      8'd118: lead_rom = 6'b0_10011;  // B4/115
      8'd119: lead_rom = 6'b0_10100;  // C#5/115
      8'd120: lead_rom = 6'b1_00010;  // C#2/231
      8'd121: lead_rom = 6'b0_10011;  // B4/115
      8'd122: lead_rom = 6'b0_10100;  // C#5/115
      8'd123: lead_rom = 6'b0_10110;  // D#5/115
      8'd124: lead_rom = 6'b0_11000;  // F#5/115
      8'd125: lead_rom = 6'b0_10100;  // C#5/115
      8'd126: lead_rom = 6'b0_10110;  // D#5/115
      8'd127: lead_rom = 6'b0_10100;  // C#5/115
      8'd128: lead_rom = 6'b0_10011;  // B4/115
      8'd129: lead_rom = 6'b1_00111;  // B2/231
      8'd130: lead_rom = 6'b1_00001;  // B1/231
      8'd131: lead_rom = 6'b1_00111;  // B2/231
      8'd132: lead_rom = 6'b1_01010;  // E3/231
      8'd133: lead_rom = 6'b0_10000;  // F#4/115
      8'd134: lead_rom = 6'b0_10001;  // G#4/115
      8'd135: lead_rom = 6'b1_01101;  // B3/231
      8'd136: lead_rom = 6'b0_10000;  // F#4/115
      8'd137: lead_rom = 6'b0_10001;  // G#4/115
      8'd138: lead_rom = 6'b0_10011;  // B4/115
      8'd139: lead_rom = 6'b0_10100;  // C#5/115
      8'd140: lead_rom = 6'b0_10110;  // D#5/115
      8'd141: lead_rom = 6'b0_10011;  // B4/115
      8'd142: lead_rom = 6'b0_10111;  // E5/115
      8'd143: lead_rom = 6'b0_10110;  // D#5/115
      8'd144: lead_rom = 6'b0_10111;  // E5/115
      8'd145: lead_rom = 6'b0_11000;  // F#5/115
      8'd146: lead_rom = 6'b1_01000;  // C#3/231
      8'd147: lead_rom = 6'b1_01010;  // E3/231
      8'd148: lead_rom = 6'b0_10000;  // F#4/115
      8'd149: lead_rom = 6'b0_10001;  // G#4/115
      8'd150: lead_rom = 6'b0_10011;  // B4/115
      8'd151: lead_rom = 6'b0_10000;  // F#4/115
      8'd152: lead_rom = 6'b0_10111;  // E5/115
      8'd153: lead_rom = 6'b0_10110;  // D#5/115
      8'd154: lead_rom = 6'b0_10100;  // C#5/115
      8'd155: lead_rom = 6'b0_10011;  // B4/115
      8'd156: lead_rom = 6'b0_10000;  // F#4/115
      8'd157: lead_rom = 6'b0_01110;  // D#4/115
      8'd158: lead_rom = 6'b0_01111;  // E4/115
      8'd159: lead_rom = 6'b0_10000;  // F#4/115
      8'd160: lead_rom = 6'b1_01010;  // E3/231
      8'd161: lead_rom = 6'b0_10000;  // F#4/115
      8'd162: lead_rom = 6'b0_10001;  // G#4/115
      8'd163: lead_rom = 6'b1_01101;  // B3/231
      8'd164: lead_rom = 6'b0_10000;  // F#4/115
      8'd165: lead_rom = 6'b0_10001;  // G#4/115
      8'd166: lead_rom = 6'b0_10011;  // B4/115
      8'd167: lead_rom = 6'b0_10011;  // B4/115
      8'd168: lead_rom = 6'b0_10100;  // C#5/115
      8'd169: lead_rom = 6'b0_10110;  // D#5/115
      8'd170: lead_rom = 6'b0_10011;  // B4/115
      8'd171: lead_rom = 6'b0_10000;  // F#4/115
      8'd172: lead_rom = 6'b0_10001;  // G#4/115
      8'd173: lead_rom = 6'b0_10000;  // F#4/115
      8'd174: lead_rom = 6'b1_01000;  // C#3/231
      8'd175: lead_rom = 6'b0_10011;  // B4/115
      8'd176: lead_rom = 6'b0_10010;  // A#4/115
      8'd177: lead_rom = 6'b0_10011;  // B4/115
      8'd178: lead_rom = 6'b0_10000;  // F#4/115
      8'd179: lead_rom = 6'b0_10001;  // G#4/115
      8'd180: lead_rom = 6'b0_10011;  // B4/115
      8'd181: lead_rom = 6'b0_10111;  // E5/115
      8'd182: lead_rom = 6'b0_10110;  // D#5/115
      8'd183: lead_rom = 6'b0_10111;  // E5/115
      8'd184: lead_rom = 6'b0_11000;  // F#5/115
      8'd185: lead_rom = 6'b1_01011;  // F#3/231
      8'd186: lead_rom = 6'b1_01101;  // B3/231
      8'd187: lead_rom = 6'b1_01010;  // E3/231
      8'd188: lead_rom = 6'b0_10000;  // F#4/115
      8'd189: lead_rom = 6'b0_10001;  // G#4/115
      8'd190: lead_rom = 6'b1_01101;  // B3/231
      8'd191: lead_rom = 6'b0_10000;  // F#4/115
      8'd192: lead_rom = 6'b0_10001;  // G#4/115
      8'd193: lead_rom = 6'b0_10011;  // B4/115
      8'd194: lead_rom = 6'b0_10100;  // C#5/115
      8'd195: lead_rom = 6'b0_10110;  // D#5/115
      8'd196: lead_rom = 6'b0_10011;  // B4/115
      8'd197: lead_rom = 6'b0_10111;  // E5/115
      8'd198: lead_rom = 6'b0_10110;  // D#5/115
      8'd199: lead_rom = 6'b0_10111;  // E5/115
      8'd200: lead_rom = 6'b0_11000;  // F#5/115
      8'd201: lead_rom = 6'b1_01000;  // C#3/231
      8'd202: lead_rom = 6'b1_01010;  // E3/231
      8'd203: lead_rom = 6'b0_10000;  // F#4/115
      8'd204: lead_rom = 6'b0_10001;  // G#4/115
      8'd205: lead_rom = 6'b0_10011;  // B4/115
      8'd206: lead_rom = 6'b0_10000;  // F#4/115
      8'd207: lead_rom = 6'b0_10111;  // E5/115
      8'd208: lead_rom = 6'b0_10110;  // D#5/115
      8'd209: lead_rom = 6'b0_10100;  // C#5/115
      8'd210: lead_rom = 6'b0_10101;  // D5/115
      8'd211: lead_rom = 6'b0_10000;  // F#4/115
      8'd212: lead_rom = 6'b0_01110;  // D#4/115
      8'd213: lead_rom = 6'b0_01111;  // E4/115
      8'd214: lead_rom = 6'b0_10000;  // F#4/115
      8'd215: lead_rom = 6'b1_01010;  // E3/231
      8'd216: lead_rom = 6'b0_10000;  // F#4/115
      8'd217: lead_rom = 6'b0_10001;  // G#4/115
      8'd218: lead_rom = 6'b1_01101;  // B3/231
      8'd219: lead_rom = 6'b0_10000;  // F#4/115
      8'd220: lead_rom = 6'b0_10001;  // G#4/115
      8'd221: lead_rom = 6'b0_10011;  // B4/115
      8'd222: lead_rom = 6'b0_10011;  // B4/115
      8'd223: lead_rom = 6'b0_10100;  // C#5/115
      8'd224: lead_rom = 6'b0_10110;  // D#5/115
      8'd225: lead_rom = 6'b0_10011;  // B4/115
      8'd226: lead_rom = 6'b0_10000;  // F#4/115
      8'd227: lead_rom = 6'b0_10001;  // G#4/115
      8'd228: lead_rom = 6'b0_10000;  // F#4/115
      8'd229: lead_rom = 6'b1_01000;  // C#3/231
      8'd230: lead_rom = 6'b0_10011;  // B4/115
      8'd231: lead_rom = 6'b0_10010;  // A#4/115
      8'd232: lead_rom = 6'b0_10011;  // B4/115
      8'd233: lead_rom = 6'b0_10000;  // F#4/115
      8'd234: lead_rom = 6'b0_10001;  // G#4/115
      8'd235: lead_rom = 6'b0_10011;  // B4/115
      8'd236: lead_rom = 6'b0_10111;  // E5/115
      8'd237: lead_rom = 6'b0_10110;  // D#5/115
      8'd238: lead_rom = 6'b0_10111;  // E5/115
      8'd239: lead_rom = 6'b0_11000;  // F#5/115
      8'd240: lead_rom = 6'b1_01011;  // F#3/231
      8'd241: lead_rom = 6'b1_01101;  // B3/231
      default: lead_rom = 6'b0_00000;
    endcase
  end

  wire [17:0] lead_hp  = note_hp(lead_rom[4:0]);
  wire [22:0] lead_dur = lead_rom[5] ? DUR_231 : DUR_115;

  reg [22:0] lead_dur_cnt;
  reg [17:0] lead_pwm_cnt;
  reg        lead_pwm;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      lead_step    <= 8'd0;
      lead_dur_cnt <= 23'd0;
      lead_pwm_cnt <= 18'd0;
      lead_pwm     <= 1'b0;
    end else begin
      if (lead_dur_cnt == lead_dur) begin
        lead_step    <= (lead_step == LEAD_SEQ_LEN - 8'd1) ? 8'd0 : lead_step + 8'd1;
        lead_dur_cnt <= 23'd0;
        lead_pwm_cnt <= 18'd0;
        lead_pwm     <= 1'b0;
      end else begin
        lead_dur_cnt <= lead_dur_cnt + 23'd1;
        if (lead_hp == 18'd0) begin
          lead_pwm     <= 1'b0;
          lead_pwm_cnt <= 18'd0;
        end else if (lead_pwm_cnt == lead_hp - 18'd1) begin
          lead_pwm_cnt <= 18'd0;
          lead_pwm     <= ~lead_pwm;
        end else begin
          lead_pwm_cnt <= lead_pwm_cnt + 18'd1;
        end
      end
    end
  end

  // ── HARMONY ROM ─────────────────────────────────────────────────────────
  // Format: {2-bit dur_flags, 5-bit note_code}
  //   dur_flags=2'b00 -> DUR_115
  //   dur_flags=2'b01 -> DUR_231
  //   dur_flags=2'b10 -> DUR_346
  // 227 entries (0-226), loops at 226+1
  reg [7:0] harm_step;  // 0-226
  reg [6:0] harm_rom;
  always @(*) begin
    case (harm_step)
      8'd  0: harm_rom = 7'b00_01101;  // B3/115
      8'd  1: harm_rom = 7'b10_00000;  // @/346
      8'd  2: harm_rom = 7'b01_01101;  // B3/231
      8'd  3: harm_rom = 7'b01_00000;  // @/231
      8'd  4: harm_rom = 7'b00_01101;  // B3/115
      8'd  5: harm_rom = 7'b10_00000;  // @/346
      8'd  6: harm_rom = 7'b00_01101;  // B3/115
      8'd  7: harm_rom = 7'b00_11010;  // A#5/115
      8'd  8: harm_rom = 7'b01_00000;  // @/231
      8'd  9: harm_rom = 7'b01_01101;  // B3/231
      8'd 10: harm_rom = 7'b01_00000;  // @/231
      8'd 11: harm_rom = 7'b01_01101;  // B3/231
      8'd 12: harm_rom = 7'b01_00000;  // @/231
      8'd 13: harm_rom = 7'b00_01101;  // B3/115
      8'd 14: harm_rom = 7'b10_00000;  // @/346
      8'd 15: harm_rom = 7'b00_01101;  // B3/115
      8'd 16: harm_rom = 7'b10_00000;  // @/346
      8'd 17: harm_rom = 7'b01_11000;  // F#5/231
      8'd 18: harm_rom = 7'b01_11001;  // G#5/231
      8'd 19: harm_rom = 7'b00_00101;  // F#2/115
      8'd 20: harm_rom = 7'b10_00000;  // @/346
      8'd 21: harm_rom = 7'b00_00011;  // D#2/115
      8'd 22: harm_rom = 7'b00_00000;  // @/115
      8'd 23: harm_rom = 7'b01_01001;  // D#3/231
      8'd 24: harm_rom = 7'b01_10011;  // B4/231
      8'd 25: harm_rom = 7'b01_10100;  // C#5/231
      8'd 26: harm_rom = 7'b01_10101;  // D5/231
      8'd 27: harm_rom = 7'b00_01000;  // C#3/115
      8'd 28: harm_rom = 7'b00_00000;  // @/115
      8'd 29: harm_rom = 7'b00_00101;  // F#2/115
      8'd 30: harm_rom = 7'b00_00000;  // @/115
      8'd 31: harm_rom = 7'b00_01011;  // F#3/115
      8'd 32: harm_rom = 7'b00_00000;  // @/115
      8'd 33: harm_rom = 7'b00_00001;  // B1/115
      8'd 34: harm_rom = 7'b00_00000;  // @/115
      8'd 35: harm_rom = 7'b00_00111;  // B2/115
      8'd 36: harm_rom = 7'b00_00000;  // @/115
      8'd 37: harm_rom = 7'b00_00001;  // B1/115
      8'd 38: harm_rom = 7'b00_00000;  // @/115
      8'd 39: harm_rom = 7'b00_00111;  // B2/115
      8'd 40: harm_rom = 7'b00_00000;  // @/115
      8'd 41: harm_rom = 7'b01_10110;  // D#5/231
      8'd 42: harm_rom = 7'b01_11000;  // F#5/231
      8'd 43: harm_rom = 7'b00_00101;  // F#2/115
      8'd 44: harm_rom = 7'b00_00000;  // @/115
      8'd 45: harm_rom = 7'b00_01011;  // F#3/115
      8'd 46: harm_rom = 7'b00_00000;  // @/115
      8'd 47: harm_rom = 7'b00_00011;  // D#2/115
      8'd 48: harm_rom = 7'b00_00000;  // @/115
      8'd 49: harm_rom = 7'b00_01001;  // D#3/115
      8'd 50: harm_rom = 7'b00_00000;  // @/115
      8'd 51: harm_rom = 7'b00_00110;  // G#2/115
      8'd 52: harm_rom = 7'b00_00000;  // @/115
      8'd 53: harm_rom = 7'b00_01100;  // G#3/115
      8'd 54: harm_rom = 7'b00_00000;  // @/115
      8'd 55: harm_rom = 7'b01_10101;  // D5/231
      8'd 56: harm_rom = 7'b00_01000;  // C#3/115
      8'd 57: harm_rom = 7'b00_00000;  // @/115
      8'd 58: harm_rom = 7'b00_00101;  // F#2/115
      8'd 59: harm_rom = 7'b00_00000;  // @/115
      8'd 60: harm_rom = 7'b00_01011;  // F#3/115
      8'd 61: harm_rom = 7'b00_00000;  // @/115
      8'd 62: harm_rom = 7'b00_00001;  // B1/115
      8'd 63: harm_rom = 7'b00_00000;  // @/115
      8'd 64: harm_rom = 7'b01_10100;  // C#5/231
      8'd 65: harm_rom = 7'b01_10011;  // B4/231
      8'd 66: harm_rom = 7'b01_10100;  // C#5/231
      8'd 67: harm_rom = 7'b01_11000;  // F#5/231
      8'd 68: harm_rom = 7'b01_11001;  // G#5/231
      8'd 69: harm_rom = 7'b00_00101;  // F#2/115
      8'd 70: harm_rom = 7'b10_00000;  // @/346
      8'd 71: harm_rom = 7'b00_00011;  // D#2/115
      8'd 72: harm_rom = 7'b00_00000;  // @/115
      8'd 73: harm_rom = 7'b01_01001;  // D#3/231
      8'd 74: harm_rom = 7'b01_10011;  // B4/231
      8'd 75: harm_rom = 7'b01_10100;  // C#5/231
      8'd 76: harm_rom = 7'b01_10101;  // D5/231
      8'd 77: harm_rom = 7'b00_01000;  // C#3/115
      8'd 78: harm_rom = 7'b00_00000;  // @/115
      8'd 79: harm_rom = 7'b00_00101;  // F#2/115
      8'd 80: harm_rom = 7'b00_00000;  // @/115
      8'd 81: harm_rom = 7'b00_01011;  // F#3/115
      8'd 82: harm_rom = 7'b00_00000;  // @/115
      8'd 83: harm_rom = 7'b00_00001;  // B1/115
      8'd 84: harm_rom = 7'b00_00000;  // @/115
      8'd 85: harm_rom = 7'b00_00111;  // B2/115
      8'd 86: harm_rom = 7'b00_00000;  // @/115
      8'd 87: harm_rom = 7'b00_00001;  // B1/115
      8'd 88: harm_rom = 7'b00_00000;  // @/115
      8'd 89: harm_rom = 7'b00_00111;  // B2/115
      8'd 90: harm_rom = 7'b00_00000;  // @/115
      8'd 91: harm_rom = 7'b01_10110;  // D#5/231
      8'd 92: harm_rom = 7'b01_11000;  // F#5/231
      8'd 93: harm_rom = 7'b00_00101;  // F#2/115
      8'd 94: harm_rom = 7'b00_00000;  // @/115
      8'd 95: harm_rom = 7'b00_01011;  // F#3/115
      8'd 96: harm_rom = 7'b00_00000;  // @/115
      8'd 97: harm_rom = 7'b00_00011;  // D#2/115
      8'd 98: harm_rom = 7'b00_00000;  // @/115
      8'd 99: harm_rom = 7'b00_01001;  // D#3/115
      8'd100: harm_rom = 7'b00_00000;  // @/115
      8'd101: harm_rom = 7'b00_00110;  // G#2/115
      8'd102: harm_rom = 7'b00_00000;  // @/115
      8'd103: harm_rom = 7'b00_01100;  // G#3/115
      8'd104: harm_rom = 7'b00_00000;  // @/115
      8'd105: harm_rom = 7'b01_10101;  // D5/231
      8'd106: harm_rom = 7'b00_01000;  // C#3/115
      8'd107: harm_rom = 7'b00_00000;  // @/115
      8'd108: harm_rom = 7'b00_00101;  // F#2/115
      8'd109: harm_rom = 7'b00_00000;  // @/115
      8'd110: harm_rom = 7'b00_01011;  // F#3/115
      8'd111: harm_rom = 7'b00_00000;  // @/115
      8'd112: harm_rom = 7'b00_00001;  // B1/115
      8'd113: harm_rom = 7'b00_00000;  // @/115
      8'd114: harm_rom = 7'b01_10100;  // C#5/231
      8'd115: harm_rom = 7'b01_10011;  // B4/231
      8'd116: harm_rom = 7'b01_10100;  // C#5/231
      8'd117: harm_rom = 7'b01_10011;  // B4/231
      8'd118: harm_rom = 7'b00_01100;  // G#3/115
      8'd119: harm_rom = 7'b00_00000;  // @/115
      8'd120: harm_rom = 7'b01_10011;  // B4/231
      8'd121: harm_rom = 7'b00_01111;  // E4/115
      8'd122: harm_rom = 7'b00_00000;  // @/115
      8'd123: harm_rom = 7'b00_01001;  // D#3/115
      8'd124: harm_rom = 7'b00_00000;  // @/115
      8'd125: harm_rom = 7'b00_01011;  // F#3/115
      8'd126: harm_rom = 7'b00_00000;  // @/115
      8'd127: harm_rom = 7'b00_01101;  // B3/115
      8'd128: harm_rom = 7'b00_00000;  // @/115
      8'd129: harm_rom = 7'b00_01110;  // D#4/115
      8'd130: harm_rom = 7'b00_00000;  // @/115
      8'd131: harm_rom = 7'b01_10011;  // B4/231
      8'd132: harm_rom = 7'b01_10011;  // B4/231
      8'd133: harm_rom = 7'b00_01100;  // G#3/115
      8'd134: harm_rom = 7'b00_00000;  // @/115
      8'd135: harm_rom = 7'b00_01101;  // B3/115
      8'd136: harm_rom = 7'b00_00000;  // @/115
      8'd137: harm_rom = 7'b00_00111;  // B2/115
      8'd138: harm_rom = 7'b00_00000;  // @/115
      8'd139: harm_rom = 7'b00_01001;  // D#3/115
      8'd140: harm_rom = 7'b00_00000;  // @/115
      8'd141: harm_rom = 7'b00_01011;  // F#3/115
      8'd142: harm_rom = 7'b00_00000;  // @/115
      8'd143: harm_rom = 7'b00_01101;  // B3/115
      8'd144: harm_rom = 7'b00_00000;  // @/115
      8'd145: harm_rom = 7'b01_10011;  // B4/231
      8'd146: harm_rom = 7'b00_01100;  // G#3/115
      8'd147: harm_rom = 7'b00_00000;  // @/115
      8'd148: harm_rom = 7'b01_10011;  // B4/231
      8'd149: harm_rom = 7'b00_01111;  // E4/115
      8'd150: harm_rom = 7'b00_00000;  // @/115
      8'd151: harm_rom = 7'b00_01001;  // D#3/115
      8'd152: harm_rom = 7'b00_00000;  // @/115
      8'd153: harm_rom = 7'b00_01011;  // F#3/115
      8'd154: harm_rom = 7'b00_00000;  // @/115
      8'd155: harm_rom = 7'b00_01101;  // B3/115
      8'd156: harm_rom = 7'b00_00000;  // @/115
      8'd157: harm_rom = 7'b00_01110;  // D#4/115
      8'd158: harm_rom = 7'b00_00000;  // @/115
      8'd159: harm_rom = 7'b01_10011;  // B4/231
      8'd160: harm_rom = 7'b00_01010;  // E3/115
      8'd161: harm_rom = 7'b00_00000;  // @/115
      8'd162: harm_rom = 7'b00_01100;  // G#3/115
      8'd163: harm_rom = 7'b00_00000;  // @/115
      8'd164: harm_rom = 7'b00_01101;  // B3/115
      8'd165: harm_rom = 7'b00_00000;  // @/115
      8'd166: harm_rom = 7'b00_00111;  // B2/115
      8'd167: harm_rom = 7'b00_00000;  // @/115
      8'd168: harm_rom = 7'b00_01001;  // D#3/115
      8'd169: harm_rom = 7'b00_00000;  // @/115
      8'd170: harm_rom = 7'b01_10011;  // B4/231
      8'd171: harm_rom = 7'b01_10010;  // A#4/231
      8'd172: harm_rom = 7'b01_10011;  // B4/231
      8'd173: harm_rom = 7'b00_01100;  // G#3/115
      8'd174: harm_rom = 7'b00_00000;  // @/115
      8'd175: harm_rom = 7'b01_10011;  // B4/231
      8'd176: harm_rom = 7'b00_01111;  // E4/115
      8'd177: harm_rom = 7'b00_00000;  // @/115
      8'd178: harm_rom = 7'b00_01001;  // D#3/115
      8'd179: harm_rom = 7'b00_00000;  // @/115
      8'd180: harm_rom = 7'b00_01011;  // F#3/115
      8'd181: harm_rom = 7'b00_00000;  // @/115
      8'd182: harm_rom = 7'b00_01101;  // B3/115
      8'd183: harm_rom = 7'b00_00000;  // @/115
      8'd184: harm_rom = 7'b00_01110;  // D#4/115
      8'd185: harm_rom = 7'b00_00000;  // @/115
      8'd186: harm_rom = 7'b01_10011;  // B4/231
      8'd187: harm_rom = 7'b01_10011;  // B4/231
      8'd188: harm_rom = 7'b00_01100;  // G#3/115
      8'd189: harm_rom = 7'b00_00000;  // @/115
      8'd190: harm_rom = 7'b00_01101;  // B3/115
      8'd191: harm_rom = 7'b00_00000;  // @/115
      8'd192: harm_rom = 7'b00_00111;  // B2/115
      8'd193: harm_rom = 7'b00_00000;  // @/115
      8'd194: harm_rom = 7'b00_01001;  // D#3/115
      8'd195: harm_rom = 7'b00_10011;  // B4/115
      8'd196: harm_rom = 7'b00_01011;  // F#3/115
      8'd197: harm_rom = 7'b00_00000;  // @/115
      8'd198: harm_rom = 7'b00_01101;  // B3/115
      8'd199: harm_rom = 7'b00_00000;  // @/115
      8'd200: harm_rom = 7'b01_10011;  // B4/231
      8'd201: harm_rom = 7'b00_01100;  // G#3/115
      8'd202: harm_rom = 7'b00_00000;  // @/115
      8'd203: harm_rom = 7'b01_10011;  // B4/231
      8'd204: harm_rom = 7'b00_01111;  // E4/115
      8'd205: harm_rom = 7'b00_00000;  // @/115
      8'd206: harm_rom = 7'b00_01001;  // D#3/115
      8'd207: harm_rom = 7'b00_00000;  // @/115
      8'd208: harm_rom = 7'b00_01011;  // F#3/115
      8'd209: harm_rom = 7'b00_00000;  // @/115
      8'd210: harm_rom = 7'b00_01101;  // B3/115
      8'd211: harm_rom = 7'b00_00000;  // @/115
      8'd212: harm_rom = 7'b00_01110;  // D#4/115
      8'd213: harm_rom = 7'b00_00000;  // @/115
      8'd214: harm_rom = 7'b01_10011;  // B4/231
      8'd215: harm_rom = 7'b00_01010;  // E3/115
      8'd216: harm_rom = 7'b00_00000;  // @/115
      8'd217: harm_rom = 7'b00_01100;  // G#3/115
      8'd218: harm_rom = 7'b00_00000;  // @/115
      8'd219: harm_rom = 7'b00_01101;  // B3/115
      8'd220: harm_rom = 7'b00_00000;  // @/115
      8'd221: harm_rom = 7'b00_00111;  // B2/115
      8'd222: harm_rom = 7'b00_00000;  // @/115
      8'd223: harm_rom = 7'b00_01001;  // D#3/115
      8'd224: harm_rom = 7'b00_00000;  // @/115
      8'd225: harm_rom = 7'b01_10011;  // B4/231
      8'd226: harm_rom = 7'b01_10100;  // C#5/231
      default: harm_rom = 7'b00_00000;
    endcase
  end

  wire [17:0] harm_hp  = note_hp(harm_rom[4:0]);
  wire [23:0] harm_dur = (harm_rom[6:5] == 2'b10) ? DUR_346 :
                         (harm_rom[6:5] == 2'b01) ? {1'b0, DUR_231} :
                                                    {1'b0, DUR_115};

  reg [23:0] harm_dur_cnt;
  reg [17:0] harm_pwm_cnt;
  reg        harm_pwm;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      harm_step    <= 8'd0;
      harm_dur_cnt <= 24'd0;
      harm_pwm_cnt <= 18'd0;
      harm_pwm     <= 1'b0;
    end else begin
      if (harm_dur_cnt == harm_dur) begin
        harm_step    <= (harm_step == HARM_SEQ_LEN - 8'd1) ? 8'd0 : harm_step + 8'd1;
        harm_dur_cnt <= 24'd0;
        harm_pwm_cnt <= 18'd0;
        harm_pwm     <= 1'b0;
      end else begin
        harm_dur_cnt <= harm_dur_cnt + 24'd1;
        if (harm_hp == 18'd0) begin
          harm_pwm     <= 1'b0;
          harm_pwm_cnt <= 18'd0;
        end else if (harm_pwm_cnt == harm_hp - 18'd1) begin
          harm_pwm_cnt <= 18'd0;
          harm_pwm     <= ~harm_pwm;
        end else begin
          harm_pwm_cnt <= harm_pwm_cnt + 18'd1;
        end
      end
    end
  end

  // ── Output assignments ───────────────────────────────────────────────────
  //   uo_out[0] = lead melody PWM  (connect to first piezo speaker)
  //   uo_out[1] = harmony PWM      (connect to second piezo speaker)
  //   uo_out[7:2] = 0
  assign uo_out  = {6'b0, harm_pwm, lead_pwm};
  assign uio_out = 8'h00;
  assign uio_oe  = 8'hFF;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, ui_in, uio_in, 1'b0};

endmodule
