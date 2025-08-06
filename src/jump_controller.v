module jump_controller (
  input wire clk,       // Clock signal (typically 27 MHz)
  input wire btn1,      // Active-low button input (pressed when 0)
  output reg jumpOffset // Output signal to indicate "jump" state
);

  // Parameter defining how long the jump lasts, in clock cycles.
  // At 27 MHz, 19_500_000 cycles ≈ 0.72 seconds
  parameter JUMP_DURATION = 32'd19_500_000;

  // Register to count how long the jump is active
  reg [31:0] jumpCounter = 0;

  // Register indicating whether the Dino is currently jumping
  reg jumping = 0;

  // Main control logic triggered on every rising edge of the clock
  always @(posedge clk) begin
    // Start of a new jump when not already jumping and button is pressed
    if (!jumping && !btn1) begin
      jumping <= 1;           // Set jumping state to true
      jumpCounter <= 0;       // Reset the jump duration counter
      jumpOffset <= 1;        // Activate jump output (Dino goes up)
    end

    // If already jumping, increment counter and maintain jump
    else if (jumping) begin
      if (jumpCounter < JUMP_DURATION) begin
        jumpCounter <= jumpCounter + 1; // Count the duration of the jump
        jumpOffset <= 1;                // Keep jump signal high
      end else begin
        jumping <= 0;       // Jump duration complete, end jump
        jumpOffset <= 0;    // Deactivate jump signal (Dino comes down)
      end
    end

    // Default case when not jumping or button not pressed
    else begin
      jumpOffset <= 0; // Ensure jump signal is low
    end
  end

endmodule
