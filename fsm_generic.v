// Code your design here
`timescale 1ns / 1ps
module fsm_generic #(
  parameter STATE_WIDTH = 2,
  parameter RESET_STATE = 0
) (
  input wire clk,
  input wire reset,
  input wire [STATE_WIDTH-1:0] next_state,
  output reg [STATE_WIDTH-1:0] state
);
  always @(posedge clk) begin
    if(reset) begin
      state <= RESET_STATE;
    end
    
    else begin
      state <= next_state;
    end
  end
    
endmodule
