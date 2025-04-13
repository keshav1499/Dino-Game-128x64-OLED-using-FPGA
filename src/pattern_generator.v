module pattern_generator (
  input  wire [9:0] pixelIndex, //from screen_driver
  input  wire [7:0] frameNumber,  //from screen_driver
  input       jumpOffset,   //    from jump_controller Controls vertical position of cat
  output reg  [7:0] patternByte
);

  wire [6:0] col = pixelIndex % 128;
  wire [2:0] row = pixelIndex / 128;

  reg [7:0] catSprite [0:31];
  initial $readmemh("cat_sprite.hex", catSprite);

  localparam CAT_X = 40;
  localparam CAT_WIDTH = 16;
  localparam OBS_WIDTH = 12;
  localparam SCREEN_WIDTH = 128;
  localparam WHITE_FRAMES = 30;  // ~1 second at 60fps

  // Obstacle position
  wire [6:0] obsX = SCREEN_WIDTH - ((frameNumber * 1) % (SCREEN_WIDTH + OBS_WIDTH));
  wire [6:0] obsXEnd = obsX + OBS_WIDTH;

  wire horizontalOverlap = (obsX < (CAT_X + CAT_WIDTH)) && (obsXEnd > CAT_X);
  wire catOnGround = !jumpOffset;

  // Internal state for white flash
  reg [7:0] whiteCounter = 0;
  reg [7:0] prevFrame = 0;

  // Synchronous logic to update whiteCounter based on frame changes
  always @(posedge frameNumber[0]) begin  // Any change in frameNumber triggers
    if (frameNumber != prevFrame) begin
      prevFrame <= frameNumber;

      if (horizontalOverlap && catOnGround) begin
        whiteCounter <= WHITE_FRAMES;
      end else if (whiteCounter > 0) begin
        whiteCounter <= whiteCounter - 1;
      end
    end
  end

  wire showWhite = (whiteCounter > 0);

  // Display logic
  always @(*) begin
    if (showWhite) begin
      patternByte = 8'hFF;
    end else if (row == 6) begin
      patternByte = 8'hF0;  // ground line
    end
    else if ((row == (jumpOffset ? 1 : 4) || row == (jumpOffset ? 2 : 5)) &&
             (col >= CAT_X && col < CAT_X + CAT_WIDTH)) begin
      patternByte = catSprite[(row - (jumpOffset ? 1 : 4)) * 16 + (col - CAT_X)];
    end
    else if (row == 5 && (col >= obsX && col < obsXEnd)) begin
      patternByte = 8'hFF;  // Obstacle
    end else begin
      patternByte = 8'h00;
    end
  end

endmodule