`timescale 1ns / 1ps

module uart_tx #(
  parameter NB_DATA = 8
)(
  input  wire               clk,
  input  wire               reset,
  input  wire               tx_start, // Pulso que ordena transmitir un dato
  input  wire [NB_DATA-1:0] tx_data,  // Byte a transmitir (desde la ALU / Top)
  input  wire               tick,     // Mismo tick de sobremuestreo (16x)
  output reg                tx,       // Línea física serie de salida
  output reg                tx_done   // Pulso de 1 ciclo cuando finaliza el envío
);

  // Estados de mi tx
  localparam [1:0] IDLE  = 2'b00;
  localparam [1:0] START = 2'b01;
  localparam [1:0] DATA  = 2'b10;
  localparam [1:0] STOP  = 2'b11;

  // Estado actual y el proximo
  wire [1:0] state;
  reg [1:0] next_state;

  // Registros
  reg [3:0] tick_count;
  reg [2:0] bit_count;
  reg [NB_DATA-1:0] data_reg;

  // Condicionales
  wire bit_tick = (tick_count == 4'd15);
  wire last_bit = (bit_count == NB_DATA - 1);

  // Señales de Control
  reg tick_clear;   // Flag para limpiar el contador de ticks
  reg tick_inc;     // Flag para incrementar el contador de ticks
  reg bit_clear;    // Flag para limpiar el contador de bits
  reg bit_inc;      // Flag para incrementar el contador de bits
  reg shift_data;   // Flag para mover el dato
  reg load_data;    // Flag para capturar tx_data

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
    
    tick_clear = 1'b0;
    tick_inc   = 1'b0;
    bit_clear  = 1'b0;
    bit_inc    = 1'b0;
    shift_data = 1'b0;
    load_data  = 1'b0;
    
    tx      = 1'b1; // Por defecto en reposo (nivel alto)
    tx_done = 1'b0;
    
    case (state)

      // IDLE
      IDLE: begin
        tx = 1'b1;
        if (tx_start) begin
          next_state = START;
          tick_clear = 1'b1;
          bit_clear  = 1'b1;
          load_data  = 1'b1; // Cargamos el byte en data_reg
        end
      end
    
      // START
      START: begin
        tx = 1'b0; // Start bit siempre es 0
        if (tick) begin
          if (bit_tick) begin
            next_state = DATA;
            tick_clear = 1'b1;
          end
          else begin
            tick_inc = 1'b1;
          end
        end
      end
    
      // DATA
      DATA: begin
        tx = data_reg[0]; // Enviamos el bit menos significativo actual
        if (tick) begin
          if (bit_tick) begin
            tick_clear = 1'b1;
            shift_data = 1'b1; // Rotamos a la derecha para poner el siguiente bit en [0]
            if (last_bit) begin
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
        tx = 1'b1; // Stop bit siempre es 1
        if (tick) begin
          if (bit_tick) begin
            next_state = IDLE;
            tick_clear = 1'b1;
            tx_done    = 1'b1; // Notificamos que la transmision finalizo
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
    if (reset) begin
      tick_count <= 0;
      bit_count  <= 0;
      data_reg   <= 0;
    end

    else begin
      // Manejo de tick_count
      if (tick_clear) begin
        tick_count <= 0;
      end
      else if (tick_inc) begin
        tick_count <= tick_count + 1'b1;
      end
    
      // Manejo de bit_count
      if (bit_clear) begin
        bit_count <= 0;
      end
      else if (bit_inc) begin
        bit_count <= bit_count + 1'b1;
      end
    
      // Manejo del registro de datos
      if (load_data) begin
        data_reg <= tx_data;
      end
      else if (shift_data) begin
        data_reg <= {1'b0, data_reg[NB_DATA-1:1]}; // Desplaza a la derecha
      end
    end
  end
endmodule
