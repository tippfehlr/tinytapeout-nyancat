/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

// Outputs Morse code "HELLO WORLD" on all output pins.
// Clock: ~16 Hz. Speed: ~20 WPM (1 clock cycle = 1 Morse unit ≈ 62.5 ms).
// Morse timing: dot=1u, dash=3u, element_gap=1u, char_gap=3u, word_gap=7u.
// No clock divider needed - each rising edge advances one Morse unit.
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

  // ROM: {on_off[3], duration[2:0]}
  // "HELLO WORLD" sequence, 67 entries (indices 0-66).
  // All duration values are 1, 3, or 7 (never 0); zero duration is not supported.
  reg [3:0] rom_data;
  always @(*) begin
    case (step)
      // H: ....
      7'd0:  rom_data = {1'b1, 3'd1}; // ON  dot
      7'd1:  rom_data = {1'b0, 3'd1}; // OFF element gap
      7'd2:  rom_data = {1'b1, 3'd1}; // ON  dot
      7'd3:  rom_data = {1'b0, 3'd1}; // OFF element gap
      7'd4:  rom_data = {1'b1, 3'd1}; // ON  dot
      7'd5:  rom_data = {1'b0, 3'd1}; // OFF element gap
      7'd6:  rom_data = {1'b1, 3'd1}; // ON  dot
      7'd7:  rom_data = {1'b0, 3'd3}; // OFF char gap
      // E: .
      7'd8:  rom_data = {1'b1, 3'd1}; // ON  dot
      7'd9:  rom_data = {1'b0, 3'd3}; // OFF char gap
      // L: .-..
      7'd10: rom_data = {1'b1, 3'd1}; // ON  dot
      7'd11: rom_data = {1'b0, 3'd1}; // OFF element gap
      7'd12: rom_data = {1'b1, 3'd3}; // ON  dash
      7'd13: rom_data = {1'b0, 3'd1}; // OFF element gap
      7'd14: rom_data = {1'b1, 3'd1}; // ON  dot
      7'd15: rom_data = {1'b0, 3'd1}; // OFF element gap
      7'd16: rom_data = {1'b1, 3'd1}; // ON  dot
      7'd17: rom_data = {1'b0, 3'd3}; // OFF char gap
      // L: .-..
      7'd18: rom_data = {1'b1, 3'd1}; // ON  dot
      7'd19: rom_data = {1'b0, 3'd1}; // OFF element gap
      7'd20: rom_data = {1'b1, 3'd3}; // ON  dash
      7'd21: rom_data = {1'b0, 3'd1}; // OFF element gap
      7'd22: rom_data = {1'b1, 3'd1}; // ON  dot
      7'd23: rom_data = {1'b0, 3'd1}; // OFF element gap
      7'd24: rom_data = {1'b1, 3'd1}; // ON  dot
      7'd25: rom_data = {1'b0, 3'd3}; // OFF char gap
      // O: ---
      7'd26: rom_data = {1'b1, 3'd3}; // ON  dash
      7'd27: rom_data = {1'b0, 3'd1}; // OFF element gap
      7'd28: rom_data = {1'b1, 3'd3}; // ON  dash
      7'd29: rom_data = {1'b0, 3'd1}; // OFF element gap
      7'd30: rom_data = {1'b1, 3'd3}; // ON  dash
      7'd31: rom_data = {1'b0, 3'd7}; // OFF word gap
      // W: .--
      7'd32: rom_data = {1'b1, 3'd1}; // ON  dot
      7'd33: rom_data = {1'b0, 3'd1}; // OFF element gap
      7'd34: rom_data = {1'b1, 3'd3}; // ON  dash
      7'd35: rom_data = {1'b0, 3'd1}; // OFF element gap
      7'd36: rom_data = {1'b1, 3'd3}; // ON  dash
      7'd37: rom_data = {1'b0, 3'd3}; // OFF char gap
      // O: ---
      7'd38: rom_data = {1'b1, 3'd3}; // ON  dash
      7'd39: rom_data = {1'b0, 3'd1}; // OFF element gap
      7'd40: rom_data = {1'b1, 3'd3}; // ON  dash
      7'd41: rom_data = {1'b0, 3'd1}; // OFF element gap
      7'd42: rom_data = {1'b1, 3'd3}; // ON  dash
      7'd43: rom_data = {1'b0, 3'd3}; // OFF char gap
      // R: .-.
      7'd44: rom_data = {1'b1, 3'd1}; // ON  dot
      7'd45: rom_data = {1'b0, 3'd1}; // OFF element gap
      7'd46: rom_data = {1'b1, 3'd3}; // ON  dash
      7'd47: rom_data = {1'b0, 3'd1}; // OFF element gap
      7'd48: rom_data = {1'b1, 3'd1}; // ON  dot
      7'd49: rom_data = {1'b0, 3'd3}; // OFF char gap
      // L: .-..
      7'd50: rom_data = {1'b1, 3'd1}; // ON  dot
      7'd51: rom_data = {1'b0, 3'd1}; // OFF element gap
      7'd52: rom_data = {1'b1, 3'd3}; // ON  dash
      7'd53: rom_data = {1'b0, 3'd1}; // OFF element gap
      7'd54: rom_data = {1'b1, 3'd1}; // ON  dot
      7'd55: rom_data = {1'b0, 3'd1}; // OFF element gap
      7'd56: rom_data = {1'b1, 3'd1}; // ON  dot
      7'd57: rom_data = {1'b0, 3'd3}; // OFF char gap
      // D: -..
      7'd58: rom_data = {1'b1, 3'd3}; // ON  dash
      7'd59: rom_data = {1'b0, 3'd1}; // OFF element gap
      7'd60: rom_data = {1'b1, 3'd1}; // ON  dot
      7'd61: rom_data = {1'b0, 3'd1}; // OFF element gap
      7'd62: rom_data = {1'b1, 3'd1}; // ON  dot
      // 4-space word gap (4 x 7 units = 28 units) before repeating
      7'd63: rom_data = {1'b0, 3'd7}; // OFF word gap 1/4
      7'd64: rom_data = {1'b0, 3'd7}; // OFF word gap 2/4
      7'd65: rom_data = {1'b0, 3'd7}; // OFF word gap 3/4
      7'd66: rom_data = {1'b0, 3'd7}; // OFF word gap 4/4 (then repeat)
      default: rom_data = {1'b0, 3'd1};
    endcase
  end

  reg [6:0] step;        // current ROM step (0-66)
  reg [2:0] unit_count;  // unit count within current step
  reg       morse_out;   // current output bit

  // Each rising clock edge advances one Morse unit (no clock divider needed).
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      step       <= 0;
      unit_count <= 0;
      morse_out  <= 0;
    end else begin
      morse_out <= rom_data[3];
      if (unit_count == rom_data[2:0] - 1) begin
        unit_count <= 0;
        step <= (step == 7'd66) ? 7'd0 : step + 7'd1;
      end else begin
        unit_count <= unit_count + 3'd1;
      end
    end
  end

  assign uo_out  = {8{morse_out}};
  assign uio_out = {8{morse_out}};
  assign uio_oe  = 8'hFF;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, ui_in, uio_in, 1'b0};

endmodule
