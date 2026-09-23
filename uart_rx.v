// Code your design here
`timescale 1ns / 1ps

module uart_rx #(
  parameter NB_DATA = 8
)(
  input wire clk,
  input wire reset,
  input wire rx,
  input wire tick,
  
  output wire [NB_DATA-1:0] data_out,
  output wire rx_done
);
  
  reg [3:0] tick_count;
  reg [2:0] bit_count;
  reg [NB_DATA-1:0] data_reg;
  
  // Condiciones que envio a la FSM
  wire mid_tick;
  wire bit_tick;
  wire last_bit;
  
  assign mid_tick = (tick_count == 4'd7);
  assign bit_tick = (tick_count == 4'd15);
  assign last_bit = (bit_count == 3'd7);
  
  // Señales de control a la FSM
  wire tick_clear;
  wire tick_inc;
  wire bit_clear;
  wire bit_inc;
  wire shift_data;
  wire rx_done_internal;
  
  // Instanciamos la FSM
  uart_rx_fsm FSM_RX(
    .clk(clk),
    .reset(reset),
    
    .tick(tick), 
    .rx(rx),
    .mid_tick(mid_tick),
    .bit_tick(bit_tick), 
    .last_bit(last_bit), 

    .tick_clear(tick_clear), 
    .tick_inc(tick_inc), 
    .bit_clear(bit_clear), 
    .bit_inc(bit_inc), 

    .shift_data(shift_data), 
    .rx_done(rx_done_internal) 

  );
  
  always @(posedge clk) begin
    if(reset) begin
      tick_count <= 0;
      bit_count <= 0;
      data_reg <= 0;
    end
    
    else begin
      if(tick_clear) begin
        tick_count <= 0;
      end
      else if(tick_inc) begin
        tick_count <= tick_count + 1'b1;
      end
    
      if(bit_clear) begin 
        bit_count <= 0;
      end
      else if(bit_inc) begin
        bit_count <= bit_count + 1'b1;
      end
    
      if(shift_data) begin
        data_reg <= {rx, data_reg[7:1]};
      end
      
    end
    
  end
  
   // Salidas
      assign data_out = data_reg;
      assign rx_done = rx_done_internal;
  
endmodule  

