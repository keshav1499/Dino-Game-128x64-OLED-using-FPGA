module pattern_generator (
  input  wire [9:0] pixelIndex,    // Pixel index from screen_driver (0 to 1023)
  input  wire [7:0] frameNumber,   // Current frame count from screen_driver
  input        jumpOffset,         // From jump_controller: 0 = ground, 1 = jump
  output reg  [7:0] patternByte    // Output pattern byte for current pixel
);

  // Calculate column and row from pixelIndex (128x8 display)
  wire [6:0] col = pixelIndex % 128;
  wire [2:0] row = pixelIndex / 128;

  // Cat sprite memory: 2 rows of 16 bytes (16x2 = 32 total bytes)
  reg [7:0] catSprite [0:31];
  initial $readmemh("cat_sprite.hex", catSprite);

  // Constants for cat and obstacle dimensions
  localparam CAT_X        = 40;
  localparam CAT_WIDTH    = 16;
  localparam OBS_WIDTH    = 8;
  localparam SCREEN_WIDTH = 128;
  localparam WHITE_FRAMES = 30;  // Flash duration after collision (~1 sec @ 60fps)

  // Compute obstacle position based on frame number
  wire [6:0] obsX     = SCREEN_WIDTH - ((frameNumber * 1) % (SCREEN_WIDTH + OBS_WIDTH));
  wire [6:0] obsXEnd  = obsX + OBS_WIDTH;

  // Check for potential collision
  wire horizontalOverlap = (obsX < (CAT_X + CAT_WIDTH)) && (obsXEnd > CAT_X);
  wire catOnGround       = !jumpOffset;

  // Registers for handling white screen flash on collision
  reg [7:0] whiteCounter = 0;
  reg [7:0] prevFrame    = 0;

  // Update whiteCounter on new frame
  always @(posedge frameNumber[0]) begin
    if (frameNumber != prevFrame) begin
      prevFrame <= frameNumber;

      if (horizontalOverlap && catOnGround) begin
        whiteCounter <= WHITE_FRAMES;  // Trigger flash
      end else if (whiteCounter > 0) begin
        whiteCounter <= whiteCounter - 1;
      end
    end
  end

  // Determine whether to show white flash
  wire showWhite = (whiteCounter > 0);

  // Pixel pattern generation logic
  always @(*) begin
    if (showWhite) begin
      patternByte = 8'hFF;  // Flash screen white
    end else if (row == 6) begin
      patternByte = 8'hF0;  // Ground line
    end
    else if ((row == (jumpOffset ? 1 : 4) || row == (jumpOffset ? 2 : 5)) &&
             (col >= CAT_X && col < CAT_X + CAT_WIDTH)) begin
      // Cat sprite display (2 rows)
      patternByte = catSprite[(row - (jumpOffset ? 1 : 4)) * 16 + (col - CAT_X)];
    end
    else if (row == 5 && (col >= obsX && col < obsXEnd)) begin
      patternByte = 8'hFF;  // Obstacle block
    end else begin
      patternByte = 8'h00;  // Background
    end
  end

endmodule
