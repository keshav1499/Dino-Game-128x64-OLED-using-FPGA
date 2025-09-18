//`default_nettype none

module screen_driver
#(
  parameter STARTUP_WAIT = 32'd10000000,    //10000000 for 27mhz
  parameter FRAME_WAIT = 32'd450000 // ~16.6ms at 27MHz
)
(
  input clk,
  input wire [7:0] patternByte,
  output io_sclk,
  output io_sdin,
  output io_cs,
  output io_dc,
  output io_reset,
  output  wire [9:0] pixelIndex, 
  output  reg [7:0] frameNumber

);

  localparam STATE_INIT_POWER = 3'd0;
  localparam STATE_LOAD_INIT_CMD = 3'd1;
  localparam STATE_SEND = 3'd2;
  localparam STATE_CHECK_FINISHED_INIT = 3'd3;
  localparam STATE_LOAD_DATA = 3'd4;
  localparam STATE_WAIT_FRAME = 3'd5;

  reg [2:0] state = STATE_INIT_POWER;
  reg [31:0] counter = 0;
  reg [31:0] frameWaitCounter = 0;
  reg spiBitPhase = 0;
  reg dc = 1;
  reg sclk = 1;
  reg sdin = 0;
  reg reset = 1;
  reg cs = 0;

  reg [7:0] dataToSend = 0;
  reg [3:0] bitNumber = 0;
  reg [9:0] pixelCounter = 0;
  reg [7:0] frameNumber = 0;

  localparam SETUP_INSTRUCTIONS = 23;
  reg [(SETUP_INSTRUCTIONS*8)-1:0]
//The below startup commands are needed for display initialisation...
 startupCommands = {
    8'hAE, 8'h81, 8'h7F, 8'hA6, 8'h20, 8'h00, 8'hC8, 8'h40,
    8'hA1, 8'hA8, 8'h3F, 8'hD3, 8'h00, 8'hD5, 8'h80, 8'hD9,
    8'h22, 8'hDB, 8'h20, 8'h8D, 8'h14, 8'hA4, 8'hAF
  };
  reg [7:0] commandIndex = SETUP_INSTRUCTIONS * 8;


//reg [31:0] startupCounter = 0;


  assign io_sclk = sclk;
  assign io_sdin = sdin;
  assign io_dc = dc;
  assign io_reset = reset;
  assign io_cs = cs;
  assign pixelIndex = pixelCounter;  //The pixelcounter variable here is too entangled, maybe run find and replace to declutter in future

  // Generate 1 byte of display pattern dynamically





  
always @(posedge clk) begin
  //------------------------------------------------------
      // STATE 0: INIT_POWER
      // Apply reset signal for a fixed period of time to ensure
      // the display is properly reset before initialization.
      //------------------------------------------------------
    case (state)
      STATE_INIT_POWER: begin
        counter <= counter + 1;
        if (counter < STARTUP_WAIT)
          reset <= 1;
        else if (counter < STARTUP_WAIT * 2)
          reset <= 0;
        else if (counter < STARTUP_WAIT * 3)
          reset <= 1;
        else begin
          state <= STATE_LOAD_INIT_CMD;
          counter <= 0;
        end
      end
//------------------------------------------------------
      // STATE 1: LOAD_INIT_CMD
      // Load the next initialization command from the sequence.
      // Set DC low (command mode), select the chip, and prepare
      // the byte for SPI transfer.
      //------------------------------------------------------
      STATE_LOAD_INIT_CMD: begin
        dc <= 0;
        dataToSend <= startupCommands[(commandIndex-1)-:8];
        bitNumber <= 7;
        cs <= 0;
        commandIndex <= commandIndex - 8;
        state <= STATE_SEND;
      end
//------------------------------------------------------
      // STATE 2: SEND
      // Shift out one byte of data (command or pixel data)
      // using SPI protocol (bit-banging).
      //------------------------------------------------------
      STATE_SEND: begin
    
if (spiBitPhase == 0) begin
  sclk <= 0;
  sdin <= dataToSend[bitNumber];
  spiBitPhase <= 1;
end else begin
  sclk <= 1;
  spiBitPhase <= 0;
  if (bitNumber == 0)
    state <= STATE_CHECK_FINISHED_INIT;
  else
    bitNumber <= bitNumber - 1;
end

      end
//------------------------------------------------------
      // STATE 3: CHECK_FINISHED_INIT
      // After sending a byte, check if initialization is complete
      // or if we need to send more data/commands.
      //------------------------------------------------------
      STATE_CHECK_FINISHED_INIT: begin
  cs <= 1;
  if (dc == 0) begin // Command phase
    if (commandIndex == 0) begin
      frameNumber <= frameNumber + 1;
      pixelCounter <= 0;
      state <= STATE_LOAD_DATA;
    end else begin
      state <= STATE_LOAD_INIT_CMD;
    end
  end else begin // Data phase
    pixelCounter <= pixelCounter + 1;
    if (pixelCounter < 1023) begin // < 1023 because we're incrementing here
      state <= STATE_LOAD_DATA;
    end else begin
      state <= STATE_WAIT_FRAME;
    end
  end
end
//------------------------------------------------------
      // STATE 4: LOAD_DATA
      // Load the next pixel data byte (patternByte) and prepare
      // to send it over SPI.
      //------------------------------------------------------
     STATE_LOAD_DATA: begin
  if (pixelCounter < 1024) begin
    cs <= 0;
    dc <= 1;
    bitNumber <= 3'd7;
    dataToSend <= patternByte;
    state <= STATE_SEND;
  end else begin
    state <= STATE_WAIT_FRAME;
  end
end
 //------------------------------------------------------
      // STATE 5: WAIT_FRAME
      // Wait for the required frame interval before starting the
      // next frame of pixel updates.
      //------------------------------------------------------

STATE_WAIT_FRAME: begin
  frameWaitCounter <= frameWaitCounter + 1;

  if (frameWaitCounter >= FRAME_WAIT) begin
    frameWaitCounter <= 0;
    frameNumber <= frameNumber + 1;
    pixelCounter <= 0;
    state <= STATE_LOAD_DATA;
  end
end






    endcase
  end


endmodule
