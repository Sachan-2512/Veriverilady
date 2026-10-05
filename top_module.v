`timescale 1ns / 1ps

module top_module #(
  parameter NB_DATA = 8,
  parameter NB_OPCODE = 6,
  parameter CLK_FREQ = 50000000,
  parameter BAUD_RATE = 19200,
  parameter OVERSAMPLING = 16
)(
  input wire clk,
  input wire reset,
  // Entrada rx
  input wire rx,
  // Salida tx
  output wire tx
);
  // BAUD_RATE_GENERATOR
  wire tick;
  
  // UART_RX-> INTERFACE
  wire [NB_DATA-1:0] rx_data;
  wire rx_done;
  
  // INTERFACE -> UART_TX
  wire [NB_DATA-1:0] tx_data;
  wire tx_start;
  wire tx_done;
  
  // INTERFACE -> ALU
  wire [NB_DATA-1:0] alu_A;
  wire [NB_DATA-1:0] alu_B;
  wire [NB_OPCODE-1:0] alu_OP;

  // ALU -> INTERFACE
  wire [NB_DATA-1:0] alu_result;
  
  
  // 1) Instancio baud_rate_generator
  baud_rate_gen #(
    .CLK_FREQ(CLK_FREQ),
    .OVERSAMPLING(OVERSAMPLING),
    .BAUD_RATE(BAUD_RATE)
  ) BAUD_RATE_GEN (
    .clk(clk),
    .reset(reset),
    .tick(tick)
  );
  
  
  // 2) Instancio uart_rx
  uart_rx #(
    .NB_DATA(NB_DATA)
  ) UART_RX (
    .clk(clk),
    .reset(reset),
    .rx(rx),
    .tick(tick),
    .data_out(rx_data),
    .rx_done(rx_done)
  );
  
  // 3) Instancio uart_interface
  uart_interface #(
    .NB_DATA(NB_DATA),
    .NB_OPCODE(NB_OPCODE)
  ) UART_INTERFACE (
    .clk(clk),
    .reset(reset),
    .rx_done(rx_done),
    .rx_data(rx_data),
    .tx_done(tx_done),
    .alu_result(alu_result),
    .alu_A(alu_A),
    .alu_B(alu_B),
    .alu_OP(alu_OP),
    .tx_data(tx_data),
    .tx_start(tx_start)
  );
    
  // 4) Instancio ALU
  tp1_alu #(
    .NB_DATA(NB_DATA),
    .NB_OPCODE(NB_OPCODE)
  ) ALU (
   .A_data(alu_A),
   .B_data(alu_B),
   .OP_data(alu_OP),
   .result(alu_result)
  );
  

  // 5) Instancio uart_tx
  uart_tx #(
    .NB_DATA(NB_DATA)
  ) UART_TX (
    .clk(clk),
    .reset(reset),
    .tx_start(tx_start),
    .tx_data(tx_data),
    .tick(tick),
    .tx(tx),
    .tx_done(tx_done)
  );

endmodule
