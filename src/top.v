//`default_nettype none

module top #(
  parameter STARTUP_WAIT = 32'd10000000,
  parameter FRAME_WAIT = 32'd450000
)(
  input clk,
  input btn1,
  output io_sclk,
  output io_sdin,
  output io_cs,
  output io_dc,
  output io_reset
);


wire jumpOffset;
wire [9:0] pixelIndex;
wire [7:0] frameNumbers;
wire [7:0] patternByte;

  screen_driver #(
    .STARTUP_WAIT(STARTUP_WAIT),
    .FRAME_WAIT(FRAME_WAIT)
  ) driver (
    .clk(clk),
    .io_sclk(io_sclk),
    .io_sdin(io_sdin),
    .io_cs(io_cs),
    .io_dc(io_dc),
    .io_reset(io_reset),
    .pixelIndex(pixelIndex),
    .frameNumber(frameNumbers),
    .patternByte(patternByte)
  );




jump_controller jump_inst (
  .clk(clk),
  .btn1(btn1),
  .jumpOffset(jumpOffset)
);



  pattern_generator patternGen (
    .pixelIndex(pixelIndex),
    .frameNumber(frameNumbers),
    .patternByte(patternByte),
    .jumpOffset(jumpOffset)
  );


endmodule
