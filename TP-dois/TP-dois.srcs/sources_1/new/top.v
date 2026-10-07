`timescale 1ns / 1ps

module top #(
    parameter NB_DATA      = 8,
    parameter NB_ALU_OP    = 6,
    parameter CLK_FREQ     = 50_000_000,
    parameter BAUD_RATE    = 19_200,
    parameter OVERSAMPLING = 16
)(
    input  wire clk,
    input  wire reset,
    input  wire rx,
    output wire tx
);

  wire baud_tick;

  wire [NB_DATA-1:0] rx_data;
  wire rx_done;

  wire [NB_DATA-1:0] alu_data_A;
  wire [NB_DATA-1:0] alu_data_B;
  wire [NB_ALU_OP-1:0] alu_op;
  wire [NB_DATA-1:0] alu_result;

  wire [NB_DATA-1:0] tx_data;
  wire tx_start;
  wire tx_done;

  wire clk_50MHz;
  wire clock_locked;
  wire reset_request;
  wire reset_50MHz;

  (* ASYNC_REG = "TRUE" *) reg [1:0] reset_sync;

  clk_wiz_0 CLK_WIZ_50MHz (
      .clk_100MHz(clk),
      .clk_50MHz (clk_50MHz),
      .locked    (clock_locked)
  );

  assign reset_request = reset | ~clock_locked;

  always @(posedge clk_50MHz or posedge reset_request) begin
    if (reset_request) reset_sync <= 2'b11;
    else reset_sync <= {reset_sync[0], 1'b0};
  end

  assign reset_50MHz = reset_sync[1];

  baud_rate_gen #(
      .CLK_FREQ    (CLK_FREQ),
      .OVERSAMPLING(OVERSAMPLING),
      .BAUD_RATE   (BAUD_RATE)
  ) BAUD_RATE_GEN (
      .clk  (clk_50MHz),
      .reset(reset_50MHz),
      .tick (baud_tick)
  );

  uart_rx #(
      .NB_DATA(NB_DATA)
  ) UART_RX (
      .clk     (clk_50MHz),
      .reset   (reset_50MHz),
      .rx      (rx),
      .tick    (baud_tick),
      .data_out(rx_data),
      .rx_done (rx_done)
  );

  uart_interface #(
      .NB_DATA  (NB_DATA),
      .NB_ALU_OP(NB_ALU_OP)
  ) UART_INTERFACE (
      .i_clk         (clk_50MHz),
      .i_reset       (reset_50MHz),
      .i_rx_done     (rx_done),
      .i_tx_done     (tx_done),
      .i_rx_data     (rx_data),
      .i_alu_data_out(alu_result),
      .o_tx_data     (tx_data),
      .o_alu_op      (alu_op),
      .o_alu_data_A  (alu_data_A),
      .o_alu_data_B  (alu_data_B),
      .o_tx_start    (tx_start)
  );

  alu #(
      .NB_DATA  (NB_DATA),
      .NB_OPCODE(NB_ALU_OP)
  ) ALU (
      .A_data (alu_data_A),
      .B_data (alu_data_B),
      .OP_data(alu_op),
      .result (alu_result)
  );

  uart_tx #(
      .NB_DATA(NB_DATA)
  ) UART_TX (
      .clk     (clk_50MHz),
      .reset   (reset_50MHz),
      .tx_start(tx_start),
      .tx_data (tx_data),
      .tick    (baud_tick),
      .tx      (tx),
      .tx_done (tx_done)
  );

endmodule
