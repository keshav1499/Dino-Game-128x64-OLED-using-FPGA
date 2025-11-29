module pattern_generator (
  input wire [9:0] pixelIndex,    // Pixel index from screen_driver (0 to 1023)
  input wire [7:0] frameNumber,   // Current frame count from screen_driver
  input wire       jumpOffset,    // From jump_controller: 0 = ground, 1 = jump
  output reg [7:0] patternByte,   // Output pattern byte for current pixel
  input            button         // Active-low button for state transitions
);

  // --- Display Dimensions & Addressing ---
  // Calculate column and row from pixelIndex (128x8 display; 128x64 pixels -> 8 pages)
  wire [6:0] col = pixelIndex % 128;
  wire [2:0] row = pixelIndex / 128;

  // --- Sprite & Image Memory ---
  // Cat sprite memory: 2 rows of 16 bytes (16x2 = 32 total bytes)
  reg [7:0] catSprite [0:31];
  initial $readmemh("cat_sprite.hex", catSprite);

  // Game Over full-screen image (128x64 -> 1024 bytes)
  reg [7:0] gameOver [0:1023];
  initial $readmemh("gameover.hex", gameOver);

  // Game Start Full screen image
  reg [7:0] startGame [0:1023];
  initial $readmemh("startgame.hex", startGame);

  parameter OBSTACLE_WARMUP = 32'd27_000_000; // 27mhz 1 sec
  reg [31:0] warmupCounter = 0; //make it count upto 1 second

  // --- Game Constants ---
  localparam CAT_X          = 40;
  localparam CAT_WIDTH      = 16;
  localparam OBS_WIDTH      = 8;
  localparam SCREEN_WIDTH   = 128;

  // --- Obstacle Position & Collision Logic (Active in PLAY state) ---
  // Compute obstacle position based on frame number
  wire [6:0] obsX     = SCREEN_WIDTH - ((frameNumber * 1) % (SCREEN_WIDTH + OBS_WIDTH));
  wire [6:0] obsXEnd  = obsX + OBS_WIDTH;

  // Check for potential collision
  wire horizontalOverlap = (obsX < (CAT_X + CAT_WIDTH)) && (obsXEnd > CAT_X);
  wire catOnGround       = !jumpOffset;
  wire collisionDetected = horizontalOverlap && catOnGround;

  // --- FSM State Definitions ---
  localparam [1:0] STATE_START_GAME = 2'b00;
  localparam [1:0] STATE_PLAY       = 2'b01;
  localparam [1:0] STATE_GAME_OVER  = 2'b10;

  reg [1:0] currentState, nextState;


  // --- Edge Detection Logic for Debouncing ---

  // Register to hold the button state from the previous frame
  reg prevButton = 1'b1;

  // Detect a transition from high (released) to low (pressed)
  wire button_press_edge = (prevButton == 1'b1) && (button == 1'b0);

  // --- FSM State Register Update (Sequential Logic) ---
  // The state only changes on the rising edge of a new frame
  // The LSB of frameNumber (frameNumber[0]) toggles every frame, which is used as a clock edge.
  reg [7:0] prevFrame = 0;
  wire newFrame = (frameNumber != prevFrame); // Detect a new frame

  always @(posedge frameNumber[0]) begin
    if (newFrame) begin
      currentState <= nextState;
      prevFrame <= frameNumber;

      // Update previous button state on a new frame
      prevButton <= button;
    end
  end

  // --- FSM Next State Logic (Combinational Logic) ---
  // Determine the next state based on the current state, collision, and button input.
  // The button is active-low (pressed when button == 0).
  always @(*) begin
    nextState = currentState; // Default is to stay in the current state

    case (currentState)
      STATE_START_GAME: begin
        // Go to PLAY state when the button is pressed (active-low)
        if (button_press_edge) begin
          nextState = STATE_PLAY;
        end
      end



      STATE_PLAY: begin
        // Go to GAME_OVER state upon collision
        if (collisionDetected) begin
          nextState = STATE_GAME_OVER;
        end
        // Note: No transition from PLAY based on the button here.
      end



      STATE_GAME_OVER: begin
        // Go to START_GAME state when the button is pressed (active-low)
        if (button_press_edge) begin
          nextState = STATE_START_GAME;
        end
      end
    endcase
  end

  // --- Pattern Generation / Rendering Logic (Combinational Logic) ---
  // The pixel output depends on the current FSM state.
  always @(*) begin
    case (currentState)
      STATE_START_GAME: begin
        // Display the START GAME image
        patternByte = startGame[pixelIndex];
      end



      STATE_GAME_OVER: begin
        // Display the GAME OVER image
        patternByte = gameOver[pixelIndex];
      end



      STATE_PLAY: begin
        // Game Play rendering logic (original logic adapted)
        if (row == 6) begin
          patternByte = 8'hF0; // Ground line
        end
        // Cat sprite rendering: The cat's vertical position depends on jumpOffset
        else if ((row == (jumpOffset ? 1 : 4) || row == (jumpOffset ? 2 : 5)) &&
                 (col >= CAT_X && col < CAT_X + CAT_WIDTH)) begin
          // Calculate address in the 2x16 catSprite array
          patternByte = catSprite[(row - (jumpOffset ? 1 : 4)) * 16 + (col - CAT_X)];
        end
        // Obstacle rendering
        else if (row == 5 && (col >= obsX && col < obsXEnd)) begin
          patternByte = 8'hFF; // Obstacle block
        end
        else begin
          patternByte = 8'h00; // Background
        end
      end

      default: begin
        // Should not happen, but safe to default to background
        patternByte = 8'h00;
      end
    endcase
  end

endmodule