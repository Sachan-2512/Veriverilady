// Code your design here
`timescale 1ns / 1ps

module uart_rx #(
  parameter NB_DATA = 8
) (
  input wire clk,
  input wire reset,
  input wire rx,
  input wire tick,
  
  output wire [NB_DATA-1:0] data_out,
  output reg rx_done
);
  
  // Estados de mi rx
  localparam [1:0] IDLE = 2'b00;
  localparam [1:0] START = 2'b01;
  localparam [1:0] DATA = 2'b10;
  localparam [1:0] STOP = 2'b11;

  // Estado Actual y el proximo
  wire [1:0] state;
  reg [1:0] next_state;
  
  // Registros
  reg [3:0] tick_count;
  reg [2:0] bit_count;
  reg [NB_DATA-1:0] data_reg;
  
  // Condicionales
  wire mid_tick = (tick_count == 4'd7);
  wire bit_tick = (tick_count == 4'd15);
  wire last_bit = (bit_count == NB_DATA - 1);
  
  // Señales de Control
  reg tick_clear; // Flag para limpiar el contador de ticks
  reg tick_inc;   // Flag para incrementar el contador de ticks
  reg bit_clear;  // Flag para limpiar el contador de bits
  reg bit_inc;    // Flag para incrementar el contador de bits
  reg shift_data;  // Flag para mover el dato
  
  // Instancia mi bloque de maquina de estados generica
  fsm_generic #(
    .STATE_WIDTH(2),
    .RESET_STATE(IDLE)
  ) FSM_STATE_REG(
    .clk(clk),
    .reset(reset),
    .next_state(next_state),
    .state(state)
  );
  
  // Logica de Estados Combinacional
  always @(*) begin
    // Valores por defecto
    next_state = state;
    
    tick_clear= 1'b0; 
    tick_inc = 1'b0;   
    bit_clear = 1'b0;  
    bit_inc = 1'b0;     
    shift_data = 1'b0;
    
    rx_done = 0;
    
    case (state) 
      
      // IDLE
      IDLE: begin
        if(!rx) begin
          next_state = START;
          tick_clear = 1'b1;
        end
      end
      
      // START
      START: begin
        if(tick) begin
          if (mid_tick) begin
            next_state = DATA;
            tick_clear = 1'b1;
            bit_clear = 1'b1;
          end
          else begin
            tick_inc = 1'b1;
          end
        end
      end
      
      // DATA
      DATA: begin
        if(tick) begin
          if(bit_tick) begin
            tick_clear = 1'b1;
            shift_data = 1'b1;
            if(last_bit) begin
              next_state = STOP;
            end
            else begin
              bit_inc = 1'b1;
            end
          end
          else begin
            tick_inc = 1'b1;
          end
        end
      end
      
      // STOP
      STOP: begin
        if(tick) begin
          if(bit_tick) begin
            next_state = IDLE;
            tick_clear = 1'b1;
            rx_done = 1'b1;
          end
          else begin
            tick_inc = 1'b1;
          end
        end
      end
      
      // default
      default: begin
        next_state = IDLE;
      end
      
    endcase
      
  end
  
  
  
  // Datapath
  always @(posedge clk) begin
    if(reset) begin
      tick_count <= 0;
      bit_count <= 0;
      data_reg <= 0;
    end
    
    else begin
      if (tick_clear) begin
        tick_count <= 0;
      end
      else if(tick_inc) begin
        tick_count <= tick_count + 1'b1;
      end
      
      if(bit_clear) begin
        bit_count <= 0;
      end
      else if (bit_inc) begin
        bit_count <= bit_count + 1'b1;
      end
      
      if(shift_data) begin
        data_reg <= {rx,data_reg[NB_DATA-1:1]};
      end
    end
  end
  
  // Salida
  assign data_out = data_reg;
  
endmodule


