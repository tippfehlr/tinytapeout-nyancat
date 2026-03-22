/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

// Nyan Cat theme player
// Clock: 10 MHz
// Unit time: 60 ms (600,000 cycles) — 125 BPM
// uo_out[0] = lead melody piezo
// uo_out[1] = harmony piezo
// Structure: intro (2 bars) → theme (4 bars×2) → verse (4 bars×2) → repeat from theme
module tt_um_example (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // === Unit clock: one tick every 60 ms at 10 MHz ===
  localparam UNIT_CYCLES   = 600_000;
  localparam LEAD_ROM_SIZE = 290;
  localparam HARM_ROM_SIZE = 144;

  reg [19:0] unit_cnt;
  reg        unit_tick;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      unit_cnt  <= 20'd0;
      unit_tick <= 1'b0;
    end else if (unit_cnt == UNIT_CYCLES - 1) begin
      unit_cnt  <= 20'd0;
      unit_tick <= 1'b1;
    end else begin
      unit_cnt  <= unit_cnt + 20'd1;
      unit_tick <= 1'b0;
    end
  end

  // === Lead ROM: {note_id[4:0], dur_minus1[1:0]} ===
  // note_id=0 → REST; dur_minus1+1 = duration in 60 ms units (1–4)
  reg [8:0] lead_ptr;
  reg [6:0] lead_rom_out;

  always @(*) begin
    case (lead_ptr)
      9'd0: lead_rom_out = 7'd57;
      9'd1: lead_rom_out = 7'd81;
      9'd2: lead_rom_out = 7'd101;
      9'd3: lead_rom_out = 7'd1;
      9'd4: lead_rom_out = 7'd25;
      9'd5: lead_rom_out = 7'd1;
      9'd6: lead_rom_out = 7'd57;
      9'd7: lead_rom_out = 7'd81;
      9'd8: lead_rom_out = 7'd101;
      9'd9: lead_rom_out = 7'd25;
      9'd10: lead_rom_out = 7'd41;
      9'd11: lead_rom_out = 7'd61;
      9'd12: lead_rom_out = 7'd41;
      9'd13: lead_rom_out = 7'd9;
      9'd14: lead_rom_out = 7'd25;
      9'd15: lead_rom_out = 7'd1;
      9'd16: lead_rom_out = 7'd101;
      9'd17: lead_rom_out = 7'd1;
      9'd18: lead_rom_out = 7'd57;
      9'd19: lead_rom_out = 7'd81;
      9'd20: lead_rom_out = 7'd101;
      9'd21: lead_rom_out = 7'd1;
      9'd22: lead_rom_out = 7'd25;
      9'd23: lead_rom_out = 7'd1;
      9'd24: lead_rom_out = 7'd41;
      9'd25: lead_rom_out = 7'd9;
      9'd26: lead_rom_out = 7'd25;
      9'd27: lead_rom_out = 7'd41;
      9'd28: lead_rom_out = 7'd85;
      9'd29: lead_rom_out = 7'd61;
      9'd30: lead_rom_out = 7'd85;
      9'd31: lead_rom_out = 7'd41;
      9'd32: lead_rom_out = 7'd102;
      9'd33: lead_rom_out = 7'd0;
      9'd34: lead_rom_out = 7'd118;
      9'd35: lead_rom_out = 7'd0;
      9'd36: lead_rom_out = 7'd56;
      9'd37: lead_rom_out = 7'd0;
      9'd38: lead_rom_out = 7'd57;
      9'd39: lead_rom_out = 7'd1;
      9'd40: lead_rom_out = 7'd21;
      9'd41: lead_rom_out = 7'd65;
      9'd42: lead_rom_out = 7'd37;
      9'd43: lead_rom_out = 7'd21;
      9'd44: lead_rom_out = 7'd1;
      9'd45: lead_rom_out = 7'd21;
      9'd46: lead_rom_out = 7'd1;
      9'd47: lead_rom_out = 7'd37;
      9'd48: lead_rom_out = 7'd1;
      9'd49: lead_rom_out = 7'd66;
      9'd50: lead_rom_out = 7'd0;
      9'd51: lead_rom_out = 7'd65;
      9'd52: lead_rom_out = 7'd37;
      9'd53: lead_rom_out = 7'd21;
      9'd54: lead_rom_out = 7'd37;
      9'd55: lead_rom_out = 7'd57;
      9'd56: lead_rom_out = 7'd101;
      9'd57: lead_rom_out = 7'd117;
      9'd58: lead_rom_out = 7'd57;
      9'd59: lead_rom_out = 7'd101;
      9'd60: lead_rom_out = 7'd37;
      9'd61: lead_rom_out = 7'd57;
      9'd62: lead_rom_out = 7'd21;
      9'd63: lead_rom_out = 7'd37;
      9'd64: lead_rom_out = 7'd21;
      9'd65: lead_rom_out = 7'd57;
      9'd66: lead_rom_out = 7'd1;
      9'd67: lead_rom_out = 7'd101;
      9'd68: lead_rom_out = 7'd1;
      9'd69: lead_rom_out = 7'd117;
      9'd70: lead_rom_out = 7'd57;
      9'd71: lead_rom_out = 7'd101;
      9'd72: lead_rom_out = 7'd37;
      9'd73: lead_rom_out = 7'd57;
      9'd74: lead_rom_out = 7'd21;
      9'd75: lead_rom_out = 7'd65;
      9'd76: lead_rom_out = 7'd57;
      9'd77: lead_rom_out = 7'd65;
      9'd78: lead_rom_out = 7'd37;
      9'd79: lead_rom_out = 7'd21;
      9'd80: lead_rom_out = 7'd37;
      9'd81: lead_rom_out = 7'd66;
      9'd82: lead_rom_out = 7'd0;
      9'd83: lead_rom_out = 7'd21;
      9'd84: lead_rom_out = 7'd37;
      9'd85: lead_rom_out = 7'd57;
      9'd86: lead_rom_out = 7'd101;
      9'd87: lead_rom_out = 7'd37;
      9'd88: lead_rom_out = 7'd57;
      9'd89: lead_rom_out = 7'd37;
      9'd90: lead_rom_out = 7'd21;
      9'd91: lead_rom_out = 7'd38;
      9'd92: lead_rom_out = 7'd0;
      9'd93: lead_rom_out = 7'd22;
      9'd94: lead_rom_out = 7'd0;
      9'd95: lead_rom_out = 7'd39;
      9'd96: lead_rom_out = 7'd102;
      9'd97: lead_rom_out = 7'd0;
      9'd98: lead_rom_out = 7'd118;
      9'd99: lead_rom_out = 7'd0;
      9'd100: lead_rom_out = 7'd56;
      9'd101: lead_rom_out = 7'd0;
      9'd102: lead_rom_out = 7'd57;
      9'd103: lead_rom_out = 7'd1;
      9'd104: lead_rom_out = 7'd21;
      9'd105: lead_rom_out = 7'd65;
      9'd106: lead_rom_out = 7'd37;
      9'd107: lead_rom_out = 7'd21;
      9'd108: lead_rom_out = 7'd1;
      9'd109: lead_rom_out = 7'd21;
      9'd110: lead_rom_out = 7'd1;
      9'd111: lead_rom_out = 7'd37;
      9'd112: lead_rom_out = 7'd1;
      9'd113: lead_rom_out = 7'd66;
      9'd114: lead_rom_out = 7'd0;
      9'd115: lead_rom_out = 7'd65;
      9'd116: lead_rom_out = 7'd37;
      9'd117: lead_rom_out = 7'd21;
      9'd118: lead_rom_out = 7'd37;
      9'd119: lead_rom_out = 7'd57;
      9'd120: lead_rom_out = 7'd101;
      9'd121: lead_rom_out = 7'd117;
      9'd122: lead_rom_out = 7'd57;
      9'd123: lead_rom_out = 7'd101;
      9'd124: lead_rom_out = 7'd37;
      9'd125: lead_rom_out = 7'd57;
      9'd126: lead_rom_out = 7'd21;
      9'd127: lead_rom_out = 7'd37;
      9'd128: lead_rom_out = 7'd21;
      9'd129: lead_rom_out = 7'd57;
      9'd130: lead_rom_out = 7'd1;
      9'd131: lead_rom_out = 7'd101;
      9'd132: lead_rom_out = 7'd1;
      9'd133: lead_rom_out = 7'd117;
      9'd134: lead_rom_out = 7'd57;
      9'd135: lead_rom_out = 7'd101;
      9'd136: lead_rom_out = 7'd37;
      9'd137: lead_rom_out = 7'd57;
      9'd138: lead_rom_out = 7'd21;
      9'd139: lead_rom_out = 7'd65;
      9'd140: lead_rom_out = 7'd57;
      9'd141: lead_rom_out = 7'd65;
      9'd142: lead_rom_out = 7'd37;
      9'd143: lead_rom_out = 7'd21;
      9'd144: lead_rom_out = 7'd37;
      9'd145: lead_rom_out = 7'd66;
      9'd146: lead_rom_out = 7'd0;
      9'd147: lead_rom_out = 7'd21;
      9'd148: lead_rom_out = 7'd37;
      9'd149: lead_rom_out = 7'd57;
      9'd150: lead_rom_out = 7'd101;
      9'd151: lead_rom_out = 7'd37;
      9'd152: lead_rom_out = 7'd57;
      9'd153: lead_rom_out = 7'd37;
      9'd154: lead_rom_out = 7'd21;
      9'd155: lead_rom_out = 7'd38;
      9'd156: lead_rom_out = 7'd0;
      9'd157: lead_rom_out = 7'd22;
      9'd158: lead_rom_out = 7'd0;
      9'd159: lead_rom_out = 7'd39;
      9'd160: lead_rom_out = 7'd22;
      9'd161: lead_rom_out = 7'd0;
      9'd162: lead_rom_out = 7'd97;
      9'd163: lead_rom_out = 7'd113;
      9'd164: lead_rom_out = 7'd22;
      9'd165: lead_rom_out = 7'd0;
      9'd166: lead_rom_out = 7'd97;
      9'd167: lead_rom_out = 7'd113;
      9'd168: lead_rom_out = 7'd21;
      9'd169: lead_rom_out = 7'd37;
      9'd170: lead_rom_out = 7'd57;
      9'd171: lead_rom_out = 7'd21;
      9'd172: lead_rom_out = 7'd81;
      9'd173: lead_rom_out = 7'd57;
      9'd174: lead_rom_out = 7'd81;
      9'd175: lead_rom_out = 7'd101;
      9'd176: lead_rom_out = 7'd22;
      9'd177: lead_rom_out = 7'd0;
      9'd178: lead_rom_out = 7'd22;
      9'd179: lead_rom_out = 7'd0;
      9'd180: lead_rom_out = 7'd97;
      9'd181: lead_rom_out = 7'd113;
      9'd182: lead_rom_out = 7'd21;
      9'd183: lead_rom_out = 7'd97;
      9'd184: lead_rom_out = 7'd81;
      9'd185: lead_rom_out = 7'd57;
      9'd186: lead_rom_out = 7'd37;
      9'd187: lead_rom_out = 7'd21;
      9'd188: lead_rom_out = 7'd97;
      9'd189: lead_rom_out = 7'd53;
      9'd190: lead_rom_out = 7'd77;
      9'd191: lead_rom_out = 7'd97;
      9'd192: lead_rom_out = 7'd22;
      9'd193: lead_rom_out = 7'd0;
      9'd194: lead_rom_out = 7'd97;
      9'd195: lead_rom_out = 7'd113;
      9'd196: lead_rom_out = 7'd22;
      9'd197: lead_rom_out = 7'd0;
      9'd198: lead_rom_out = 7'd97;
      9'd199: lead_rom_out = 7'd113;
      9'd200: lead_rom_out = 7'd20;
      9'd201: lead_rom_out = 7'd0;
      9'd202: lead_rom_out = 7'd21;
      9'd203: lead_rom_out = 7'd37;
      9'd204: lead_rom_out = 7'd57;
      9'd205: lead_rom_out = 7'd21;
      9'd206: lead_rom_out = 7'd97;
      9'd207: lead_rom_out = 7'd113;
      9'd208: lead_rom_out = 7'd97;
      9'd209: lead_rom_out = 7'd22;
      9'd210: lead_rom_out = 7'd0;
      9'd211: lead_rom_out = 7'd21;
      9'd212: lead_rom_out = 7'd5;
      9'd213: lead_rom_out = 7'd21;
      9'd214: lead_rom_out = 7'd97;
      9'd215: lead_rom_out = 7'd113;
      9'd216: lead_rom_out = 7'd21;
      9'd217: lead_rom_out = 7'd81;
      9'd218: lead_rom_out = 7'd57;
      9'd219: lead_rom_out = 7'd81;
      9'd220: lead_rom_out = 7'd101;
      9'd221: lead_rom_out = 7'd22;
      9'd222: lead_rom_out = 7'd0;
      9'd223: lead_rom_out = 7'd38;
      9'd224: lead_rom_out = 7'd0;
      9'd225: lead_rom_out = 7'd22;
      9'd226: lead_rom_out = 7'd0;
      9'd227: lead_rom_out = 7'd97;
      9'd228: lead_rom_out = 7'd113;
      9'd229: lead_rom_out = 7'd22;
      9'd230: lead_rom_out = 7'd0;
      9'd231: lead_rom_out = 7'd97;
      9'd232: lead_rom_out = 7'd113;
      9'd233: lead_rom_out = 7'd21;
      9'd234: lead_rom_out = 7'd37;
      9'd235: lead_rom_out = 7'd57;
      9'd236: lead_rom_out = 7'd21;
      9'd237: lead_rom_out = 7'd81;
      9'd238: lead_rom_out = 7'd57;
      9'd239: lead_rom_out = 7'd81;
      9'd240: lead_rom_out = 7'd101;
      9'd241: lead_rom_out = 7'd22;
      9'd242: lead_rom_out = 7'd0;
      9'd243: lead_rom_out = 7'd22;
      9'd244: lead_rom_out = 7'd0;
      9'd245: lead_rom_out = 7'd97;
      9'd246: lead_rom_out = 7'd113;
      9'd247: lead_rom_out = 7'd21;
      9'd248: lead_rom_out = 7'd97;
      9'd249: lead_rom_out = 7'd81;
      9'd250: lead_rom_out = 7'd57;
      9'd251: lead_rom_out = 7'd37;
      9'd252: lead_rom_out = 7'd21;
      9'd253: lead_rom_out = 7'd97;
      9'd254: lead_rom_out = 7'd53;
      9'd255: lead_rom_out = 7'd77;
      9'd256: lead_rom_out = 7'd97;
      9'd257: lead_rom_out = 7'd22;
      9'd258: lead_rom_out = 7'd0;
      9'd259: lead_rom_out = 7'd97;
      9'd260: lead_rom_out = 7'd113;
      9'd261: lead_rom_out = 7'd22;
      9'd262: lead_rom_out = 7'd0;
      9'd263: lead_rom_out = 7'd97;
      9'd264: lead_rom_out = 7'd113;
      9'd265: lead_rom_out = 7'd20;
      9'd266: lead_rom_out = 7'd0;
      9'd267: lead_rom_out = 7'd21;
      9'd268: lead_rom_out = 7'd37;
      9'd269: lead_rom_out = 7'd57;
      9'd270: lead_rom_out = 7'd21;
      9'd271: lead_rom_out = 7'd97;
      9'd272: lead_rom_out = 7'd113;
      9'd273: lead_rom_out = 7'd97;
      9'd274: lead_rom_out = 7'd22;
      9'd275: lead_rom_out = 7'd0;
      9'd276: lead_rom_out = 7'd21;
      9'd277: lead_rom_out = 7'd5;
      9'd278: lead_rom_out = 7'd21;
      9'd279: lead_rom_out = 7'd97;
      9'd280: lead_rom_out = 7'd113;
      9'd281: lead_rom_out = 7'd21;
      9'd282: lead_rom_out = 7'd81;
      9'd283: lead_rom_out = 7'd57;
      9'd284: lead_rom_out = 7'd81;
      9'd285: lead_rom_out = 7'd101;
      9'd286: lead_rom_out = 7'd22;
      9'd287: lead_rom_out = 7'd0;
      9'd288: lead_rom_out = 7'd38;
      9'd289: lead_rom_out = 7'd0;
      default: lead_rom_out = 7'd0;
    endcase
  end

  // === Harmony ROM ===
  reg [7:0] harm_ptr;
  reg [6:0] harm_rom_out;

  always @(*) begin
    case (harm_ptr)
      8'd0: harm_rom_out = 7'd3;
      8'd1: harm_rom_out = 7'd3;
      8'd2: harm_rom_out = 7'd3;
      8'd3: harm_rom_out = 7'd3;
      8'd4: harm_rom_out = 7'd3;
      8'd5: harm_rom_out = 7'd3;
      8'd6: harm_rom_out = 7'd3;
      8'd7: harm_rom_out = 7'd3;
      8'd8: harm_rom_out = 7'd3;
      8'd9: harm_rom_out = 7'd3;
      8'd10: harm_rom_out = 7'd3;
      8'd11: harm_rom_out = 7'd3;
      8'd12: harm_rom_out = 7'd3;
      8'd13: harm_rom_out = 7'd3;
      8'd14: harm_rom_out = 7'd3;
      8'd15: harm_rom_out = 7'd3;
      8'd16: harm_rom_out = 7'd71;
      8'd17: harm_rom_out = 7'd75;
      8'd18: harm_rom_out = 7'd91;
      8'd19: harm_rom_out = 7'd95;
      8'd20: harm_rom_out = 7'd47;
      8'd21: harm_rom_out = 7'd51;
      8'd22: harm_rom_out = 7'd107;
      8'd23: harm_rom_out = 7'd111;
      8'd24: harm_rom_out = 7'd31;
      8'd25: harm_rom_out = 7'd35;
      8'd26: harm_rom_out = 7'd91;
      8'd27: harm_rom_out = 7'd95;
      8'd28: harm_rom_out = 7'd15;
      8'd29: harm_rom_out = 7'd19;
      8'd30: harm_rom_out = 7'd15;
      8'd31: harm_rom_out = 7'd19;
      8'd32: harm_rom_out = 7'd71;
      8'd33: harm_rom_out = 7'd75;
      8'd34: harm_rom_out = 7'd91;
      8'd35: harm_rom_out = 7'd95;
      8'd36: harm_rom_out = 7'd47;
      8'd37: harm_rom_out = 7'd51;
      8'd38: harm_rom_out = 7'd107;
      8'd39: harm_rom_out = 7'd111;
      8'd40: harm_rom_out = 7'd31;
      8'd41: harm_rom_out = 7'd35;
      8'd42: harm_rom_out = 7'd91;
      8'd43: harm_rom_out = 7'd95;
      8'd44: harm_rom_out = 7'd15;
      8'd45: harm_rom_out = 7'd19;
      8'd46: harm_rom_out = 7'd15;
      8'd47: harm_rom_out = 7'd19;
      8'd48: harm_rom_out = 7'd71;
      8'd49: harm_rom_out = 7'd75;
      8'd50: harm_rom_out = 7'd91;
      8'd51: harm_rom_out = 7'd95;
      8'd52: harm_rom_out = 7'd47;
      8'd53: harm_rom_out = 7'd51;
      8'd54: harm_rom_out = 7'd107;
      8'd55: harm_rom_out = 7'd111;
      8'd56: harm_rom_out = 7'd31;
      8'd57: harm_rom_out = 7'd35;
      8'd58: harm_rom_out = 7'd91;
      8'd59: harm_rom_out = 7'd95;
      8'd60: harm_rom_out = 7'd15;
      8'd61: harm_rom_out = 7'd19;
      8'd62: harm_rom_out = 7'd15;
      8'd63: harm_rom_out = 7'd19;
      8'd64: harm_rom_out = 7'd71;
      8'd65: harm_rom_out = 7'd75;
      8'd66: harm_rom_out = 7'd91;
      8'd67: harm_rom_out = 7'd95;
      8'd68: harm_rom_out = 7'd47;
      8'd69: harm_rom_out = 7'd51;
      8'd70: harm_rom_out = 7'd107;
      8'd71: harm_rom_out = 7'd111;
      8'd72: harm_rom_out = 7'd31;
      8'd73: harm_rom_out = 7'd35;
      8'd74: harm_rom_out = 7'd91;
      8'd75: harm_rom_out = 7'd95;
      8'd76: harm_rom_out = 7'd15;
      8'd77: harm_rom_out = 7'd19;
      8'd78: harm_rom_out = 7'd15;
      8'd79: harm_rom_out = 7'd19;
      8'd80: harm_rom_out = 7'd75;
      8'd81: harm_rom_out = 7'd111;
      8'd82: harm_rom_out = 7'd123;
      8'd83: harm_rom_out = 7'd79;
      8'd84: harm_rom_out = 7'd51;
      8'd85: harm_rom_out = 7'd95;
      8'd86: harm_rom_out = 7'd123;
      8'd87: harm_rom_out = 7'd55;
      8'd88: harm_rom_out = 7'd35;
      8'd89: harm_rom_out = 7'd75;
      8'd90: harm_rom_out = 7'd111;
      8'd91: harm_rom_out = 7'd123;
      8'd92: harm_rom_out = 7'd19;
      8'd93: harm_rom_out = 7'd51;
      8'd94: harm_rom_out = 7'd95;
      8'd95: harm_rom_out = 7'd123;
      8'd96: harm_rom_out = 7'd75;
      8'd97: harm_rom_out = 7'd111;
      8'd98: harm_rom_out = 7'd123;
      8'd99: harm_rom_out = 7'd79;
      8'd100: harm_rom_out = 7'd51;
      8'd101: harm_rom_out = 7'd95;
      8'd102: harm_rom_out = 7'd123;
      8'd103: harm_rom_out = 7'd55;
      8'd104: harm_rom_out = 7'd35;
      8'd105: harm_rom_out = 7'd75;
      8'd106: harm_rom_out = 7'd111;
      8'd107: harm_rom_out = 7'd123;
      8'd108: harm_rom_out = 7'd19;
      8'd109: harm_rom_out = 7'd51;
      8'd110: harm_rom_out = 7'd95;
      8'd111: harm_rom_out = 7'd123;
      8'd112: harm_rom_out = 7'd75;
      8'd113: harm_rom_out = 7'd111;
      8'd114: harm_rom_out = 7'd123;
      8'd115: harm_rom_out = 7'd79;
      8'd116: harm_rom_out = 7'd51;
      8'd117: harm_rom_out = 7'd95;
      8'd118: harm_rom_out = 7'd123;
      8'd119: harm_rom_out = 7'd55;
      8'd120: harm_rom_out = 7'd35;
      8'd121: harm_rom_out = 7'd75;
      8'd122: harm_rom_out = 7'd111;
      8'd123: harm_rom_out = 7'd123;
      8'd124: harm_rom_out = 7'd19;
      8'd125: harm_rom_out = 7'd51;
      8'd126: harm_rom_out = 7'd95;
      8'd127: harm_rom_out = 7'd123;
      8'd128: harm_rom_out = 7'd75;
      8'd129: harm_rom_out = 7'd111;
      8'd130: harm_rom_out = 7'd123;
      8'd131: harm_rom_out = 7'd79;
      8'd132: harm_rom_out = 7'd51;
      8'd133: harm_rom_out = 7'd95;
      8'd134: harm_rom_out = 7'd123;
      8'd135: harm_rom_out = 7'd55;
      8'd136: harm_rom_out = 7'd35;
      8'd137: harm_rom_out = 7'd75;
      8'd138: harm_rom_out = 7'd111;
      8'd139: harm_rom_out = 7'd123;
      8'd140: harm_rom_out = 7'd19;
      8'd141: harm_rom_out = 7'd51;
      8'd142: harm_rom_out = 7'd95;
      8'd143: harm_rom_out = 7'd123;
      default: harm_rom_out = 7'd0;
    endcase
  end

  // === Lead sequencer ===
  reg [4:0] lead_note;
  reg [1:0] lead_dur_cnt;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      lead_ptr     <= 9'd0;
      lead_note    <= 5'd0;
      lead_dur_cnt <= 2'd0;
    end else if (unit_tick) begin
      if (lead_dur_cnt == 2'd0) begin
        lead_note    <= lead_rom_out[6:2];
        lead_dur_cnt <= lead_rom_out[1:0];
        lead_ptr     <= (lead_ptr == LEAD_ROM_SIZE - 1) ? 9'd0 : lead_ptr + 9'd1;
      end else begin
        lead_dur_cnt <= lead_dur_cnt - 2'd1;
      end
    end
  end

  // === Harmony sequencer ===
  reg [4:0] harm_note;
  reg [1:0] harm_dur_cnt;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      harm_ptr     <= 8'd0;
      harm_note    <= 5'd0;
      harm_dur_cnt <= 2'd0;
    end else if (unit_tick) begin
      if (harm_dur_cnt == 2'd0) begin
        harm_note    <= harm_rom_out[6:2];
        harm_dur_cnt <= harm_rom_out[1:0];
        harm_ptr     <= (harm_ptr == HARM_ROM_SIZE - 1) ? 8'd0 : harm_ptr + 8'd1;
      end else begin
        harm_dur_cnt <= harm_dur_cnt - 2'd1;
      end
    end
  end

  // === Lead tone generator ===
  reg [15:0] lead_hp;
  always @(*) begin
    case (lead_note)
      5'd0: lead_hp = 16'd0;
      5'd1: lead_hp = 16'd5363;
      5'd2: lead_hp = 16'd2681;
      5'd3: lead_hp = 16'd40495;
      5'd4: lead_hp = 16'd20248;
      5'd5: lead_hp = 16'd5062;
      5'd6: lead_hp = 16'd2531;
      5'd7: lead_hp = 16'd36077;
      5'd8: lead_hp = 16'd18039;
      5'd9: lead_hp = 16'd4510;
      5'd10: lead_hp = 16'd2255;
      5'd11: lead_hp = 16'd32141;
      5'd12: lead_hp = 16'd16071;
      5'd13: lead_hp = 16'd8035;
      5'd14: lead_hp = 16'd4018;
      5'd15: lead_hp = 16'd2009;
      5'd16: lead_hp = 16'd4257;
      5'd17: lead_hp = 16'd30337;
      5'd18: lead_hp = 16'd15169;
      5'd19: lead_hp = 16'd7584;
      5'd20: lead_hp = 16'd3792;
      5'd21: lead_hp = 16'd1896;
      5'd22: lead_hp = 16'd27027;
      5'd23: lead_hp = 16'd13514;
      5'd24: lead_hp = 16'd6757;
      5'd25: lead_hp = 16'd3378;
      5'd26: lead_hp = 16'd24079;
      5'd27: lead_hp = 16'd12039;
      5'd28: lead_hp = 16'd6020;
      5'd29: lead_hp = 16'd3010;
      5'd30: lead_hp = 16'd10125;
      default: lead_hp = 16'd0;
    endcase
  end

  reg [15:0] lead_tone_cnt;
  reg        lead_tone_out;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      lead_tone_cnt <= 16'd0;
      lead_tone_out <= 1'b0;
    end else if (lead_note == 5'd0) begin
      lead_tone_cnt <= 16'd0;
      lead_tone_out <= 1'b0;
    end else if (lead_tone_cnt == 16'd0) begin
      lead_tone_cnt <= lead_hp - 16'd1;
      lead_tone_out <= ~lead_tone_out;
    end else begin
      lead_tone_cnt <= lead_tone_cnt - 16'd1;
    end
  end

  // === Harmony tone generator ===
  reg [15:0] harm_hp;
  always @(*) begin
    case (harm_note)
      5'd0: harm_hp = 16'd0;
      5'd1: harm_hp = 16'd5363;
      5'd2: harm_hp = 16'd2681;
      5'd3: harm_hp = 16'd40495;
      5'd4: harm_hp = 16'd20248;
      5'd5: harm_hp = 16'd5062;
      5'd6: harm_hp = 16'd2531;
      5'd7: harm_hp = 16'd36077;
      5'd8: harm_hp = 16'd18039;
      5'd9: harm_hp = 16'd4510;
      5'd10: harm_hp = 16'd2255;
      5'd11: harm_hp = 16'd32141;
      5'd12: harm_hp = 16'd16071;
      5'd13: harm_hp = 16'd8035;
      5'd14: harm_hp = 16'd4018;
      5'd15: harm_hp = 16'd2009;
      5'd16: harm_hp = 16'd4257;
      5'd17: harm_hp = 16'd30337;
      5'd18: harm_hp = 16'd15169;
      5'd19: harm_hp = 16'd7584;
      5'd20: harm_hp = 16'd3792;
      5'd21: harm_hp = 16'd1896;
      5'd22: harm_hp = 16'd27027;
      5'd23: harm_hp = 16'd13514;
      5'd24: harm_hp = 16'd6757;
      5'd25: harm_hp = 16'd3378;
      5'd26: harm_hp = 16'd24079;
      5'd27: harm_hp = 16'd12039;
      5'd28: harm_hp = 16'd6020;
      5'd29: harm_hp = 16'd3010;
      5'd30: harm_hp = 16'd10125;
      default: harm_hp = 16'd0;
    endcase
  end

  reg [15:0] harm_tone_cnt;
  reg        harm_tone_out;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      harm_tone_cnt <= 16'd0;
      harm_tone_out <= 1'b0;
    end else if (harm_note == 5'd0) begin
      harm_tone_cnt <= 16'd0;
      harm_tone_out <= 1'b0;
    end else if (harm_tone_cnt == 16'd0) begin
      harm_tone_cnt <= harm_hp - 16'd1;
      harm_tone_out <= ~harm_tone_out;
    end else begin
      harm_tone_cnt <= harm_tone_cnt - 16'd1;
    end
  end

  assign uo_out  = {6'b0, harm_tone_out, lead_tone_out};
  assign uio_out = 8'b0;
  assign uio_oe  = 8'hFF;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, ui_in, uio_in, 1'b0};

endmodule
