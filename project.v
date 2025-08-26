/*
 * Blank VGA Project Template
 * 
 * This template provides a clean starting point for VGA projects
 * with the basic TinyTapeout structure and HSync/VSync generator included.
 */

`default_nettype none

module tt_um_vga_example(
  input  [7:0] ui_in,    // Dedicated inputs
  output [7:0] uo_out,   // Dedicated outputs
  input  [7:0] uio_in,   // IOs: Input path
  output [7:0] uio_out,  // IOs: Output path
  output [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
  input        ena,      // always 1 when the design is powered, so you can ignore it
  input        clk,      // clock
  input        rst_n     // reset_n - low to reset+
);

  // VGA signals
  wire hsync;
  wire vsync;
  wire video_active;
  wire [1:0] vga_r, vga_g, vga_b;
  wire [9:0] pix_x, pix_y;

  // TinyVGA PMOD - correct pin assignment
  assign uo_out = {hsync, vga_b[0], vga_g[0], vga_r[0], vsync, vga_b[1], vga_g[1], vga_r[1]};

  // Unused outputs assigned to 0
  assign uio_out = 0;
  assign uio_oe  = 0;

  // Suppress unused signals warning
  wire _unused_ok = &{ena, ui_in, uio_in};

  // Instantiate the HSync/VSync generator
  hvsync_generator hvsync_gen (
    .clk(clk),
    .reset(~rst_n),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(video_active),
    .hpos(pix_x),
    .vpos(pix_y)
  );

  // Gamepad Pmod
  wire inp_present, inp_b, inp_y, inp_select, inp_start, inp_up, inp_down, inp_left, inp_right, inp_a, inp_x, inp_l, inp_r;
  gamepad_pmod_single driver (
      // Inputs:
      .rst_n(rst_n),
      .clk(clk),
      .pmod_data(ui_in[6]),
      .pmod_clk(ui_in[5]),
      .pmod_latch(ui_in[4]),
      // Outputs:
      .b(inp_b),
      .y(inp_y),
      .select(inp_select),
      .start(inp_start),
      .up(inp_up),
      .down(inp_down),
      .left(inp_left),
      .right(inp_right),
      .a(inp_a),
      .x(inp_x),
      .l(inp_l),
      .r(inp_r),
      .is_present(inp_present)
  );

  wire [9:0] snake_x, snake_y;
  snake_logic game_logic (
    .up(inp_up), .down(inp_down), .left(inp_left), .right(inp_right),
    .clk(clk),
    .vsync(vsync),
    .reset(~rst_n),
    .snake_x(snake_x), .snake_y(snake_y)
  );

    vga_display vga_out (
    .pix_x(pix_x), .pix_y(pix_y),
    .snake_x(snake_x), .snake_y(snake_y),
    .video_active(video_active),
    .reset(~rst_n),
    .r(vga_r), .g(vga_g), .b(vga_b)
  );
endmodule

module vga_display(
  input [9:0] pix_x, pix_y,
  input [9:0] snake_x, snake_y,
  input video_active,
  input reset,
  output reg [1:0] r, g, b
);
    always @(*) begin
      r = 0;
      g = 0;
      b = 0;

      if (video_active & ~reset) begin
        g = (pix_x == snake_x && pix_y == snake_y) ? 3 : 0;
      end
  end
endmodule

module game_tick(
  input clk,
  input vsync,
  input reset,
  output reg tick_pulse
);
  reg ticked_this_vsync;
  
  always @(posedge clk) begin
      if(reset || vsync) begin
          ticked_this_vsync <= 1'b0;
          tick_pulse <= 1'b0;
      end else if (~ticked_this_vsync) begin
          ticked_this_vsync <= 1'b1;
          tick_pulse <= 1'b1;
      end else begin
          ticked_this_vsync <= 1'b1;
          tick_pulse <= 1'b0;
      end
  end
endmodule

module snake_logic(
  input up, down, left, right,
  input clk,
  input vsync,
  input reset,
  output reg [9:0] snake_x, snake_y
);
  wire update_tick;
  game_tick tick (
    .clk(clk),
    .vsync(vsync),
    .reset(reset),
    .tick_pulse(update_tick)
  );

  always @(posedge clk) begin
    if (reset) begin
      snake_x <= 10;
      snake_y <= 10;
    end else if (update_tick) begin
      if (up)
        snake_y <= snake_y - 10;
      
      if (down)
        snake_y <= snake_y + 10;

      if (left)
        snake_x <= snake_x - 10;
      
      if (right)
        snake_x <= snake_x + 10;
    end
  end
endmodule