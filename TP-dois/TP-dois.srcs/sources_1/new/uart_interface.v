`timescale 1ns / 1ps

module uart_interface #(
    parameter NB_DATA   = 8,
    parameter NB_ALU_OP = 6
) (
    input wire i_clk,
    input wire i_reset,
    input wire i_rx_done,
    input wire i_tx_done,
    input wire [NB_DATA-1:0] i_rx_data,
    input wire [NB_DATA-1:0] i_alu_data_out,
    output wire [NB_DATA-1:0] o_tx_data,
    output wire [NB_ALU_OP-1:0] o_alu_op,
    output wire [NB_DATA-1:0] o_alu_data_A,
    output wire [NB_DATA-1:0] o_alu_data_B,
    output wire o_tx_start
);

  // states
  localparam [2:0] WAIT_A      = 3'b000;
  localparam [2:0] WAIT_B      = 3'b001;
  localparam [2:0] WAIT_OPCODE = 3'b010;
  localparam [2:0] EXECUTE     = 3'b011;
  localparam [2:0] WAIT_TX     = 3'b100;

  wire [2:0] state;
  reg  [2:0] next_state;
  reg [NB_DATA-1:0] alu_data_A, next_alu_data_A;
  reg [NB_DATA-1:0] alu_data_B, next_alu_data_B;
  reg [NB_ALU_OP-1:0] alu_op, next_alu_op;
  reg [NB_DATA-1:0] tx_data, next_tx_data;
  reg tx_start, next_tx_start;

  fsm_generic #(
      .STATE_WIDTH(3),
      .RESET_STATE(WAIT_A)
  ) FSM_STATE_REG (
      .clk(i_clk),
      .reset(i_reset),
      .next_state(next_state),
      .state(state)
  );

  always @(posedge i_clk) begin
    if (i_reset) begin
      alu_data_A <= 0;
      alu_data_B <= 0;
      alu_op <= 0;
      tx_data <= 0;
      tx_start <= 0;
    end else begin
      alu_data_A <= next_alu_data_A;
      alu_data_B <= next_alu_data_B;
      alu_op <= next_alu_op;
      tx_data <= next_tx_data;
      tx_start <= next_tx_start;
    end
  end

  always @(*) begin
    next_state = state;
    next_alu_data_A = alu_data_A;
    next_alu_data_B = alu_data_B;
    next_alu_op = alu_op;
    next_tx_data = tx_data;
    next_tx_start = 1'b0;

    case (state)
      WAIT_A: begin
        if (i_rx_done) begin
          next_alu_data_A = i_rx_data;
          next_state = WAIT_B;
        end
      end

      WAIT_B: begin
        if (i_rx_done) begin
          next_alu_data_B = i_rx_data;
          next_state = WAIT_OPCODE;
        end
      end

      WAIT_OPCODE: begin
        if (i_rx_done) begin
          next_alu_op = i_rx_data[NB_ALU_OP-1:0];
          next_state  = EXECUTE;
        end
      end

      EXECUTE: begin
        next_tx_data = i_alu_data_out;
        next_tx_start = 1'b1;
        next_state = WAIT_TX;
      end

      WAIT_TX: begin
        if (i_tx_done) begin
          next_state = WAIT_A;
        end
      end

      default: begin
        next_state = WAIT_A;
      end
    endcase
  end

  assign o_tx_data = tx_data;
  assign o_alu_op = alu_op;
  assign o_alu_data_A = alu_data_A;
  assign o_alu_data_B = alu_data_B;
  assign o_tx_start = tx_start;

endmodule
