module score_logic (
  input wire clk,       // 27 mhz
  input wire gameon,    // High when STATE_PLAY is active (UNUSED for ticking)
  output score_tick,    // 9 Hz signal to increment score
  output obstacle_tick  // Currently assigned to 0
);

  // --- Clock Division Constants ---
  // Input F_clk = 27,000,000 Hz
  // Desired F_out = 9 Hz
  // Counter Max (T) = 1,499,999
  localparam COUNT_MAX = 21'd1499999; 

  // Counter needs 21 bits
  reg [20:0] counter = 21'd0;

  // score_clock is the register that holds the tick state (50% duty cycle)
  reg score_clock = 1'b0;
  assign score_tick = score_clock;

  // obstacle_tick is temporarily assigned to 0
  assign obstacle_tick = 1'b0;

  // Clock division logic: Runs continuously, ignoring the 'gameon' signal
  always @(posedge clk) begin
    // Game is conceptually "always on" for this clock division
    if (counter == COUNT_MAX) begin
      // Toggle the score_clock signal
      score_clock <= ~score_clock;
      // Reset the counter
      counter <= 21'd0;
    end else begin
      // Increment the counter
      counter <= counter + 1'b1;
    end
  end

endmodule