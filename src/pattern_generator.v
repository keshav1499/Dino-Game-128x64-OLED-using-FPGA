module pattern_generator (
  input wire [9:0] pixelIndex,    // Pixel index from screen_driver (0 to 1023)
  input wire [7:0] frameNumber,   // Current frame count from screen_driver
  input wire       jumpOffset,    // From jump_controller: 0 = ground, 1 = jump
  output reg [7:0] patternByte,   // Output pattern byte for current pixel
  output wire      gameon,        // Wire that tells if STATE_PLAY is the active state
  input            button,        // Active-low button for state transitions
  input            score_tick,    // Clock/tick for score increment (e.g., 9Hz)
  input            CLK_27MHZ      // Main system clock (now unused, but kept as a port)
);

  // --- Display Dimensions & Addressing ---
  // Calculates column (0-127) and row (0-7) for the current pixel
  wire [6:0] col = pixelIndex % 128;
  wire [2:0] row = pixelIndex / 128;

  // --- Sprite & Image Memory Initialization ---
  reg [7:0] catSprite [0:31];
  initial $readmemh("hex_pngs/cat_sprite.hex", catSprite);
  reg [7:0] gameOver [0:1023];
  initial $readmemh("hex_pngs/gameover.hex", gameOver);
  reg [7:0] startGame [0:1023];
  initial $readmemh("hex_pngs/startgame.hex", startGame);
  reg [8:0] score_display [0:34];
  initial $readmemh("hex_pngs/SCORE.hex", score_display);
  reg [8:0] numerics [0:79];
  initial $readmemh("hex_pngs/nums.hex", numerics);

  // --- Game Constants ---
  localparam CAT_X           = 40;
  localparam CAT_WIDTH       = 16;
  localparam OBS_WIDTH       = 8;
  localparam SCREEN_WIDTH    = 128;
  localparam SCORE_ROW       = 0;
  localparam CHAR_WIDTH      = 8;
  localparam SCORE_LABEL_WIDTH = 34; 
  localparam SCORE_COL       = 49; 
  localparam SCORE_DIGIT_GAP = 2;

  // --- Score Positioning ---
  localparam DIGIT_1_COL = SCORE_COL + SCORE_LABEL_WIDTH + SCORE_DIGIT_GAP; 
  localparam DIGIT_2_COL = DIGIT_1_COL + CHAR_WIDTH;      
  localparam DIGIT_3_COL = DIGIT_2_COL + CHAR_WIDTH;      
  localparam DIGIT_4_COL = DIGIT_3_COL + CHAR_WIDTH;      

  // --- Score Registers and Decomposition (Max score 9999) ---
  reg [13:0] score = 0;
  wire [3:0] score_thousands = score / 1000;
  wire [3:0] score_hundreds = (score % 1000) / 100;
  wire [3:0] score_tens     = (score % 100) / 10;
  wire [3:0] score_ones     = score % 10;

  // --- Obstacle Position & Collision Logic ---
  wire [6:0] obsX     = SCREEN_WIDTH - ((frameNumber * 1) % (SCREEN_WIDTH + OBS_WIDTH));
  wire [6:0] obsXEnd  = obsX + OBS_WIDTH;
  wire horizontalOverlap = (obsX < (CAT_X + CAT_WIDTH)) && (obsXEnd > CAT_X);
  wire catOnGround       = !jumpOffset;
  wire collisionDetected = horizontalOverlap && catOnGround;

  // --- FSM State Definitions ---
  localparam [1:0] STATE_START_GAME = 2'b00;
  localparam [1:0] STATE_PLAY       = 2'b01;
  localparam [1:0] STATE_GAME_OVER  = 2'b10;
  reg [1:0] currentState, nextState;
  
  // --- Output assignment and Game Status ---
  assign gameon = (currentState == STATE_PLAY);

  // --- Edge Detection Logic for Debouncing ---
  reg prevButton = 1'b1;
  wire button_press_edge = (prevButton == 1'b1) && (button == 1'b0);
  
  // --- Score Rendering Offsets (Combinational Wires) ---
  wire [4:0] label_col_offset = col - SCORE_COL; 
  wire [2:0] char_col_offset_1 = col - DIGIT_1_COL; 
  wire [2:0] char_col_offset_2 = col - DIGIT_2_COL; 
  wire [2:0] char_col_offset_3 = col - DIGIT_3_COL; 
  wire [2:0] char_col_offset_4 = col - DIGIT_4_COL; 
  
  // --- Sequential Logic Block 1: Score Update (Clocked by score_tick) ---
  always @(posedge score_tick) begin
    if (gameon) begin
      // Increment score only during STATE_PLAY
      score <= score + 1 + score/100;
    end else if (currentState == STATE_START_GAME) begin
            score <= 0;
        end
  end
  
  // --- Sequential Logic Block 2: FSM State and Debounce (Clocked by frameNumber[0]) ---
  reg [7:0] prevFrame = 0;
  wire newFrame = (frameNumber != prevFrame); 

  always @(posedge frameNumber[0]) begin
    if (newFrame) begin : fsm_update_block // Use a named block or just begin/end
      currentState <= nextState;
      prevFrame <= frameNumber;
      prevButton <= button; // Debouncing register update
    end // FIX: Changed '}' to 'end'
  end

  // --- Combinational Logic Block 1: Next State Transitions ---
  always @(*) begin
    nextState = currentState; 

    case (currentState)
      STATE_START_GAME: begin
        // Start game on button press edge
        if (button_press_edge) begin
          nextState = STATE_PLAY;
        end
      end

      STATE_PLAY: begin
        // Go to GAME_OVER immediately upon collision
        if (collisionDetected) begin
          nextState = STATE_GAME_OVER;
        end
      end

      STATE_GAME_OVER: begin
        // Return to start screen on button press edge
        if (button_press_edge) begin
          nextState = STATE_START_GAME;
        end // FIX: Changed '}' to 'end'
      end
      
      default: nextState = STATE_START_GAME; 
    endcase
  end // FIX: Added missing 'end' for the always block

  // --- Combinational Logic Block 2: Pattern Generation / Rendering ---
  always @(*) begin
    patternByte = 8'h00; // Default: Background

    case (currentState)
      STATE_START_GAME: begin
        // Display start screen image
        patternByte = startGame[pixelIndex];
      end

      STATE_GAME_OVER: begin
        // Display game over image
        patternByte = gameOver[pixelIndex];
      end

      STATE_PLAY: begin
        // 1. Ground line (Row 6)
        if (row == 6) begin
          patternByte = 8'hF0; 
        end
        
        // 2. Score Rendering (High Priority)
        else if (row == SCORE_ROW && (col >= SCORE_COL && col < DIGIT_4_COL + CHAR_WIDTH)) begin
          
          // "SCORE:" label
          if (col < DIGIT_1_COL - SCORE_DIGIT_GAP) begin
            patternByte = score_display[label_col_offset]; 
          end
          // Thousands digit (10^3)
          else if (col >= DIGIT_1_COL && col < DIGIT_2_COL) begin
            patternByte = numerics[(score_thousands * CHAR_WIDTH) + char_col_offset_1]; 
          end
          // Hundreds digit (10^2)
          else if (col >= DIGIT_2_COL && col < DIGIT_3_COL) begin
            patternByte = numerics[(score_hundreds * CHAR_WIDTH) + char_col_offset_2];
          end
          // Tens digit (10^1)
          else if (col >= DIGIT_3_COL && col < DIGIT_4_COL) begin
            patternByte = numerics[(score_tens * CHAR_WIDTH) + char_col_offset_3];
          end
          // Ones digit (10^0)
          else if (col >= DIGIT_4_COL && col < DIGIT_4_COL + CHAR_WIDTH) begin
            patternByte = numerics[(score_ones * CHAR_WIDTH) + char_col_offset_4];
          end
          else begin
            patternByte = 8'h00; // Gap
          end

        end
        
        // 3. Cat sprite rendering (Jumping or Grounded position)
        else if ((row == (jumpOffset ? 1 : 4) || row == (jumpOffset ? 2 : 5)) &&
                 (col >= CAT_X && col < CAT_X + CAT_WIDTH)) begin
          // Calculates address based on row and column offset
          patternByte = catSprite[(row - (jumpOffset ? 1 : 4)) * 16 + (col - CAT_X)];
        end

        // 4. Obstacle rendering (Always active in STATE_PLAY)
        else if (row == 5 && (col >= obsX && col < obsXEnd)) begin
          patternByte = 8'hFF; // Obstacle block
        end

        // 5. Default background (handled by the initial assignment)
      end

      default: begin
        patternByte = 8'h00;
      end
    endcase
  end 

endmodule