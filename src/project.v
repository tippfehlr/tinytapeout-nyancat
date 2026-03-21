/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

// Outputs Morse code "HELLO WORLD" on all output pins.
// Clock: 10 MHz. Speed: 20 WPM (1 unit = 60 ms = 600,000 clock cycles).
// Morse timing: dot=1u, dash=3u, element_gap=1u, char_gap=3u, word_gap=7u.
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

  // 10 MHz clock, 20 WPM: 1 dot unit = 60 ms = 600,000 cycles.
  // In simulation (SIM defined) use 1 cycle per unit for fast testing.
`ifdef SIM
  localparam CLKS_PER_UNIT = 1;
`else
  localparam CLKS_PER_UNIT = 600_000;
`endif

  // ROM: {on_off[3], duration[2:0]}
  // "HELLO WORLD" sequence, 64 entries (indices 0-63).
  // All duration values are 1, 3, or 7 (never 0); zero duration is not supported.
  reg [3:0] rom_data;
  always @(*) begin
    case (step)
      // H: ....
      6'd0:  rom_data = {1'b1, 3'd1}; // ON  dot
      6'd1:  rom_data = {1'b0, 3'd1}; // OFF element gap
      6'd2:  rom_data = {1'b1, 3'd1}; // ON  dot
      6'd3:  rom_data = {1'b0, 3'd1}; // OFF element gap
      6'd4:  rom_data = {1'b1, 3'd1}; // ON  dot
      6'd5:  rom_data = {1'b0, 3'd1}; // OFF element gap
      6'd6:  rom_data = {1'b1, 3'd1}; // ON  dot
      6'd7:  rom_data = {1'b0, 3'd3}; // OFF char gap
      // E: .
      6'd8:  rom_data = {1'b1, 3'd1}; // ON  dot
      6'd9:  rom_data = {1'b0, 3'd3}; // OFF char gap
      // L: .-..
      6'd10: rom_data = {1'b1, 3'd1}; // ON  dot
      6'd11: rom_data = {1'b0, 3'd1}; // OFF element gap
      6'd12: rom_data = {1'b1, 3'd3}; // ON  dash
      6'd13: rom_data = {1'b0, 3'd1}; // OFF element gap
      6'd14: rom_data = {1'b1, 3'd1}; // ON  dot
      6'd15: rom_data = {1'b0, 3'd1}; // OFF element gap
      6'd16: rom_data = {1'b1, 3'd1}; // ON  dot
      6'd17: rom_data = {1'b0, 3'd3}; // OFF char gap
      // L: .-..
      6'd18: rom_data = {1'b1, 3'd1}; // ON  dot
      6'd19: rom_data = {1'b0, 3'd1}; // OFF element gap
      6'd20: rom_data = {1'b1, 3'd3}; // ON  dash
      6'd21: rom_data = {1'b0, 3'd1}; // OFF element gap
      6'd22: rom_data = {1'b1, 3'd1}; // ON  dot
      6'd23: rom_data = {1'b0, 3'd1}; // OFF element gap
      6'd24: rom_data = {1'b1, 3'd1}; // ON  dot
      6'd25: rom_data = {1'b0, 3'd3}; // OFF char gap
      // O: ---
      6'd26: rom_data = {1'b1, 3'd3}; // ON  dash
      6'd27: rom_data = {1'b0, 3'd1}; // OFF element gap
      6'd28: rom_data = {1'b1, 3'd3}; // ON  dash
      6'd29: rom_data = {1'b0, 3'd1}; // OFF element gap
      6'd30: rom_data = {1'b1, 3'd3}; // ON  dash
      6'd31: rom_data = {1'b0, 3'd7}; // OFF word gap
      // W: .--
      6'd32: rom_data = {1'b1, 3'd1}; // ON  dot
      6'd33: rom_data = {1'b0, 3'd1}; // OFF element gap
      6'd34: rom_data = {1'b1, 3'd3}; // ON  dash
      6'd35: rom_data = {1'b0, 3'd1}; // OFF element gap
      6'd36: rom_data = {1'b1, 3'd3}; // ON  dash
      6'd37: rom_data = {1'b0, 3'd3}; // OFF char gap
      // O: ---
      6'd38: rom_data = {1'b1, 3'd3}; // ON  dash
      6'd39: rom_data = {1'b0, 3'd1}; // OFF element gap
      6'd40: rom_data = {1'b1, 3'd3}; // ON  dash
      6'd41: rom_data = {1'b0, 3'd1}; // OFF element gap
      6'd42: rom_data = {1'b1, 3'd3}; // ON  dash
      6'd43: rom_data = {1'b0, 3'd3}; // OFF char gap
      // R: .-.
      6'd44: rom_data = {1'b1, 3'd1}; // ON  dot
      6'd45: rom_data = {1'b0, 3'd1}; // OFF element gap
      6'd46: rom_data = {1'b1, 3'd3}; // ON  dash
      6'd47: rom_data = {1'b0, 3'd1}; // OFF element gap
      6'd48: rom_data = {1'b1, 3'd1}; // ON  dot
      6'd49: rom_data = {1'b0, 3'd3}; // OFF char gap
      // L: .-..
      6'd50: rom_data = {1'b1, 3'd1}; // ON  dot
      6'd51: rom_data = {1'b0, 3'd1}; // OFF element gap
      6'd52: rom_data = {1'b1, 3'd3}; // ON  dash
      6'd53: rom_data = {1'b0, 3'd1}; // OFF element gap
      6'd54: rom_data = {1'b1, 3'd1}; // ON  dot
      6'd55: rom_data = {1'b0, 3'd1}; // OFF element gap
      6'd56: rom_data = {1'b1, 3'd1}; // ON  dot
      6'd57: rom_data = {1'b0, 3'd3}; // OFF char gap
      // D: -..
      6'd58: rom_data = {1'b1, 3'd3}; // ON  dash
      6'd59: rom_data = {1'b0, 3'd1}; // OFF element gap
      6'd60: rom_data = {1'b1, 3'd1}; // ON  dot
      6'd61: rom_data = {1'b0, 3'd1}; // OFF element gap
      6'd62: rom_data = {1'b1, 3'd1}; // ON  dot
      6'd63: rom_data = {1'b0, 3'd7}; // OFF word gap (then repeat)
      default: rom_data = {1'b0, 3'd1};
    endcase
  end

  reg [19:0] clk_div;     // clock divider counter
  reg [5:0]  step;        // current ROM step (0-63)
  reg [2:0]  unit_count;  // unit count within current step
  reg        morse_out;   // current output bit

  wire unit_done = (clk_div == CLKS_PER_UNIT - 1);

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      clk_div    <= 0;
      step       <= 0;
      unit_count <= 0;
      morse_out  <= 0;
    end else begin
      morse_out <= rom_data[3];
      if (unit_done) begin
        clk_div <= 0;
        if (unit_count == rom_data[2:0] - 1) begin
          unit_count <= 0;
          step <= (step == 6'd63) ? 6'd0 : step + 6'd1;
        end else begin
          unit_count <= unit_count + 3'd1;
        end
      end else begin
        clk_div <= clk_div + 20'd1;
      end
    end
  end

  assign uo_out  = {8{morse_out}};
  assign uio_out = {8{morse_out}};
  assign uio_oe  = 8'hFF;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, ui_in, uio_in, 1'b0};

endmodule
