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
  // Game paramaters
  localparam SNAKE_GRID_WIDTH = 18;
  localparam SNAKE_GRID_HEIGHT = 18;

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

  localparam SNAKE_BITS = SNAKE_GRID_WIDTH * SNAKE_GRID_HEIGHT * 4;
  wire [SNAKE_BITS - 1:0] snake_board;
  snake_logic #(
    .ROWS(SNAKE_GRID_WIDTH),
    .COLUMNS(SNAKE_GRID_HEIGHT)
  ) game_logic (
    .up(inp_up), .down(inp_down), .left(inp_left), .right(inp_right),
    .clk(clk),
    .vsync(vsync),
    .reset(~rst_n),
    .board_state(snake_board)
  );

    vga_display #(
    .ROWS(SNAKE_GRID_WIDTH),
    .COLUMNS(SNAKE_GRID_HEIGHT)
  ) vga_out (
    .pix_x(pix_x), .pix_y(pix_y),
    .board_state(snake_board),
    .video_active(video_active),
    .reset(~rst_n),
    .r(vga_r), .g(vga_g), .b(vga_b)
  );
endmodule

// Gets a new position from a distance and direction
// 2'b00: up
// 2'b01: down
// 2'b10: left
// 2'b11: right
module snake_movement_calculator (
  input [4:0] head_x, head_y,
  input [1:0] direction,
  input [4:0] distance,
  output reg [4:0] new_x, new_y
);
  always @(*) begin
    new_x = head_x;
    new_y = head_y;

    case (direction)
      2'b00: new_y = head_y - distance;
      2'b01: new_y = head_y + distance;
      2'b10: new_x = head_x - distance;
      2'b11: new_x = head_x + distance;
    endcase
  end
endmodule

module vga_display #(
  parameter ROWS,
	parameter COLUMNS,
  parameter SCALE_FACTOR = 5'd25
) (
  input [9:0] pix_x, pix_y,
  input [GRID_BITS - 1:0] board_state,
  input video_active,
  input reset,
  output reg [1:0] r, g, b
);
  localparam GRID_COL = 4;
  localparam GRID_ROW = COLUMNS * GRID_COL;
  localparam GRID_BITS = GRID_ROW * ROWS;

  wire [4:0] cell_x = pix_x[4:0] / SCALE_FACTOR;
  wire [4:0] cell_y = pix_y[4:0] / SCALE_FACTOR;

  wire [3:0] cell_state = board_state[cell_x * GRID_COL + cell_y * GRID_ROW +: 4];

  always @(*) begin
    r = 0;
    g = 0;
    b = 0;

    if (video_active & ~reset) begin
      if (pix_x < SCALE_FACTOR * COLUMNS && pix_y < SCALE_FACTOR * ROWS) begin
        r = 1;
        g = 1;
        b = 1;
      end

      if (cell_state[0])
        r = 3;
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

module snake_logic #(
  parameter ROWS,
	parameter COLUMNS
) (
  input up, down, left, right,
  input clk,
  input vsync,
  input reset,
  output reg [GRID_BITS - 1:0] board_state
);
  localparam GRID_COL = 4;
  localparam GRID_ROW = COLUMNS * GRID_COL;
  localparam GRID_BITS = GRID_ROW * ROWS;

  wire update_tick;
  reg [3:0] movement_counter;

  reg [4:0] tail_x, tail_y;
  reg [4:0] head_x, head_y;

  reg [1:0] movement_direction;
  wire [4:0] new_head_x, new_head_y;

  game_tick tick (
    .clk(clk),
    .vsync(vsync),
    .reset(reset),
    .tick_pulse(update_tick)
  );

  snake_movement_calculator movement (
    .head_x(head_x), .head_y(head_y), 
    .direction(movement_direction),
    .distance(1),
    .new_x(new_head_x), .new_y(new_head_y)
  );

  always @(posedge clk) begin
    if (up)
      movement_direction <= 2'b00;
    
    if (down)
      movement_direction <= 2'b01;

    if (left)
      movement_direction <= 2'b10;
    
    if (right)
      movement_direction <= 2'b11;

    if (reset) begin
      board_state <= {GRID_BITS{1'0}};
      head_x <= COLUMNS / 2;
      head_y <= ROWS / 2;
      tail_x <= COLUMNS / 2;
      tail_y <= ROWS / 2;
      movement_direction <= 2'b11;
    end else if (update_tick) begin
      if (movement_counter < 4)
        movement_counter <= movement_counter + 1;
      else begin
        movement_counter <= 0;

        
      end
    end
  end
endmodule