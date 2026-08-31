`timescale 1ns / 1ps

module top_module #(
  parameter NB_DATA = 8,
  parameter NB_OPCODE = 6,
  parameter NB_BUTTON = 3
)(
  input wire clk,
  input wire reset,

  input wire [NB_DATA - 1:0] switches,
  input wire [NB_BUTTON - 1:0] buttons,
  output wire [NB_DATA - 1:0] leds
);

  // Mantengo registros internos
  reg [NB_DATA - 1:0] A_reg;
  reg [NB_DATA - 1:0] B_reg;
  reg [NB_OPCODE - 1:0] OP_reg;

  // Logica secuencial
  always @(posedge clk) begin

    if (reset) begin

      A_reg  <= 0;
      B_reg  <= 0;
      OP_reg <= 0;

    end
    else begin

      if (buttons[0])
        A_reg <= switches;

      if (buttons[1])
        B_reg <= switches;

      if (buttons[2])
        OP_reg <= switches[NB_OPCODE - 1:0];

    end

  end


  // Instancio mi bloque de ALU
  tp1_alu #(
    .NB_DATA(NB_DATA),
    .NB_OPCODE(NB_OPCODE)
  ) ALU (
    .A_data(A_reg),
    .B_data(B_reg),
    .OP_data(OP_reg),
    .result(leds)
  );

endmodule