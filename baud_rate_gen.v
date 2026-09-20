`timescale 1ns / 1ps

module baud_rate_gen #(
  parameter CLK_FREQ = 50000000,
  parameter OVERSAMPLING = 16,
  parameter BAUD_RATE = 19200
)(
  input wire clk,
  input wire reset,
  output wire tick
);

  // Cantidad de ciclos de clock entre ticks
  // localparam CICLOS_PER_TICK = (CLK_FREQ + (BAUD_RATE * OVERSAMPLING)/2) / (BAUD_RATE * OVERSAMPLING);
  // localparam CICLOS_PER_TICK = (CLK_FREQ) / (BAUD_RATE * OVERSAMPLING);
  localparam CICLOS_PER_TICK = 163;  
  
  // Cantidad de bits necesarios para el contador
  localparam COUNTER_WIDTH = $clog2(CICLOS_PER_TICK);

  reg [COUNTER_WIDTH-1:0] counter;

  always @(posedge clk) begin

    if (reset) begin
      counter <= 0;
    end
    else if (counter == CICLOS_PER_TICK - 1) begin
      counter <= 0;
    end
    else begin
      counter <= counter + 1'b1;
    end

  end

  // Tick de un ciclo de duración
  assign tick = (counter == CICLOS_PER_TICK - 1);

endmodule
