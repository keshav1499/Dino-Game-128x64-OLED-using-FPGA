module jump_controller (
  input wire clk,
  input wire btn1,         // Active-low button
  output reg jumpOffset
);

  parameter JUMP_DURATION = 32'd19_500_000; // 13_500_000=~0.5s at 27MHz
  reg [31:0] jumpCounter = 0;
  reg jumping = 0;

  always @(posedge clk) begin
    if (!jumping && !btn1) begin
      jumping <= 1;
      jumpCounter <= 0;
      jumpOffset <= 1;
    end

    else if (jumping) begin
      if (jumpCounter < JUMP_DURATION) begin
        jumpCounter <= jumpCounter + 1;
        jumpOffset <= 1;
      end else begin
        jumping <= 0;
        jumpOffset <= 0;
      end
    end else begin
      jumpOffset <= 0;
    end
  end

endmodule
