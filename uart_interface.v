// Code your design here
`timescale 1ns / 1ps
module uart_interface #(
  parameter NB_DATA = 8,
  parameter NB_OPCODE = 6
) (
  input wire clk,
  input wire reset,
  
  // Entra desde UART RX
  input wire rx_done,
  input wire [NB_DATA-1:0] rx_data,
  
  // Entra desde UART TX
  input wire tx_done,
  
  // Entra desde ALU
  input wire [NB_DATA-1:0] alu_result,
  
  // Salidas del Modulo
  // Hacia la ALU
  output wire [NB_DATA-1:0] alu_A,
  output wire [NB_DATA-1:0] alu_B,
  output wire [NB_OPCODE-1:0] alu_OP,
  // Hacia UART TX
  output wire [NB_DATA-1:0] tx_data,
  output reg tx_start 
);
  
  // Comandos del protocolo
  localparam [7:0] CMD_DATA_A = 8'h00;
  localparam [7:0] CMD_DATA_B = 8'h01;
  localparam [7:0] CMD_GET_RESULT = 8'h02;
  localparam [7:0] CMD_OPERATOR = 8'h03;
  
  // Estado de mi Uart Interface
  localparam [1:0] IDLE = 2'b00;
  localparam [1:0] LOAD = 2'b01;
  localparam [1:0] SEND = 2'b10;
  localparam [1:0] WAIT_TX = 2'b11;
  
  // Estado actual y estado siguiente
  wire [1:0] state;
  reg [1:0] next_state;
   
  // Registros para recordar resultados del datapath
  reg [7:0] command_reg;
  reg [NB_DATA-1:0] A_reg;
  reg [NB_DATA-1:0] B_reg;
  reg [NB_OPCODE-1:0] OP_code_reg;
  reg [NB_DATA-1:0] tx_data_reg;
  
  // Señales de control
  reg save_command;
  reg load_A;
  reg load_B;
  reg load_OP;
  reg load_result;
  reg load_error;
  
  // Instancio la FSM
    fsm_generic #(
    .STATE_WIDTH(2),
    .RESET_STATE(IDLE)
    ) FSM_STATE_REG (
    .clk(clk),
    .reset(reset),
    .state(state),
    .next_state(next_state)
  );
  
  
  
  // Logica Combinacional
  always @(*) begin
    // Valores por defecto
    next_state = state;
    
    save_command = 1'b0;
    load_A = 1'b0;
    load_B = 1'b0;
    load_OP = 1'b0;
   
    load_result = 1'b0;
    load_error = 1'b0;
    
    tx_start = 1'b0;
    
    case(state) 
      // IDLE
      IDLE: begin
        if(rx_done) begin
          
          case(rx_data) 
            CMD_DATA_A: begin
              save_command = 1'b1;
              next_state = LOAD;
            end
            
            CMD_DATA_B: begin
              save_command = 1'b1;
              next_state = LOAD;
            end
            
            CMD_OPERATOR: begin
              save_command = 1'b1;
              next_state = LOAD;
            end
            
            CMD_GET_RESULT: begin
              load_result = 1'b1;
              next_state = SEND;
            end
            
            default: begin
              load_error = 1'b1;
              next_state = SEND;
            end
             
          endcase
            
        end
        
      end
      
      
      // LOAD
      LOAD: begin
        if(rx_done) begin
          case(command_reg) 
            CMD_DATA_A: begin
              load_A = 1'b1;
            end
            
            CMD_DATA_B: begin
              load_B = 1'b1;
            end
            
            CMD_OPERATOR: begin
              load_OP = 1'b1;
            end
          endcase
          next_state = IDLE;
        end
        
      end
      
      
      // SEND
      SEND: begin
        tx_start = 1'b1;
        next_state = WAIT_TX;
      end
      
      
      // WAIT_TX
      WAIT_TX: begin
        if(tx_done) begin
          next_state = IDLE;
        end
      end
      
      // default
      default: begin
        next_state = IDLE;
      end
            
    endcase
    
  end
  
  // Datapath Secuencial
  always @(posedge clk) begin
    if(reset) begin
      command_reg <= 0;
      
      A_reg <= 0;
      B_reg <= 0;
      OP_code_reg <= 0;
      
      tx_data_reg <= 0;
    end
    
    else begin
      // Guardar comando
      if(save_command) begin
        command_reg <= rx_data;
      end
      
      // Cargar A
      if(load_A) begin
        A_reg <= rx_data;
      end
      
      // Cargar B
      if(load_B) begin
        B_reg <= rx_data;
      end
      
      // Cargar Opcode
      if(load_OP) begin
        OP_code_reg <= rx_data[NB_OPCODE-1:0];
      end
      
      // Cargar Resultado
      if(load_result) begin
        tx_data_reg <= alu_result;
      end
      
      // Mostrar Error por comando invalido
      if(load_error) begin
        tx_data_reg <= 8'hFF;
      end
      
    end
    
  end
  
  
  // Salidas
  assign alu_A = A_reg;
  assign alu_B = B_reg;
  assign alu_OP = OP_code_reg;
  
  assign tx_data = tx_data_reg;
   
  
endmodule













