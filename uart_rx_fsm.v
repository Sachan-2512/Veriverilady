// En que estado estoy, voy y que debe hacer el datapath
`timescale 1ns / 1ps
module uart_rx_fsm (
  input wire clk,
  input wire reset,
  
  input wire tick, // El tick propiamente dicho
  input wire rx, 
  input wire mid_tick, // El contador de ticks llega a 7 o mitad del bit
  input wire bit_tick, // El contador de ticks llega a 15 o todo el bit
  input wire last_bit, // El contador de bits llego al ultimo bit
  
  output reg tick_clear, // Contador de ticks en 0
  output reg tick_inc, // Incrementamos el contador de ticks
  output reg bit_clear, // Contador de bits en 0
  output reg bit_inc, // Incrementamos el contador de bits
  
  output reg shift_data, // Registro para los bits rx
  output reg rx_done // Byte completo recibido
);
  
  // Estados
  localparam [1:0] IDLE = 2'b00;
  localparam [1:0] START = 2'b01;
  localparam [1:0] DATA = 2'b10;
  localparam [1:0] STOP = 2'b11;
  
  reg [1:0] state;
  reg [1:0] next_state;
  
  // Registro de estado
  always @(posedge clk) begin
    if(reset) begin
      state <= IDLE;
    end
    else begin
      state <= next_state;
    end
  end
  
  always @(*) begin
    // Valores por defecto
    next_state = state;
    
    tick_clear = 1'b0;
    tick_inc = 1'b0;
    bit_clear = 1'b0;
    bit_inc = 1'b0;
    shift_data = 1'b0;
    rx_done = 1'b0;
    
    // Logica de estados
    
    case(state)
      
      IDLE: begin
        if(!rx) begin // Si rx = 0 -> BIT START
          next_state = START;
          tick_clear = 1'b1; // reinicio el contador
        end
      end
      
      START: begin
        if(tick) begin
          if(mid_tick) begin
            next_state = DATA;
            tick_clear = 1'b1; // Limpio el contador de ticks
            bit_clear = 1'b1; // Limpio el contador de bits
          end
          else begin
            tick_inc = 1'b1; // Incrementamos el contador de ticks si llega uno
          end
        end
      end
      
      
      DATA: begin
        if(tick) begin
          if(bit_tick) begin // Se cumplio la cantidad de ticks por bit
            tick_clear = 1'b1;
            shift_data = 1'b1;
            if(last_bit) begin // Si es el ultimo bit del byte cambiamos de estado
              next_state = STOP;
            end
            else begin
              bit_inc = 1'b1; // Sino incrementamos el contador de bits
            end
          end
          else begin
            tick_inc = 1'b1;
          end
        end
      end
      
      
      STOP: begin // Logica para contar un bit mas
        if(tick) begin
          if(bit_tick) begin
            next_state = IDLE; // Vuelvo al estado en el que estaba
            tick_clear = 1'b1;
            rx_done = 1'b1;
          end
          else begin
            tick_inc = 1'b1;
          end
        end
      end
      
      // Estado por defecto
      default: begin
        next_state = IDLE;
      end
      
    endcase
      
  end



endmodule
