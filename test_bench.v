`timescale 1ns / 1ps

module test_bench;

  // Parametros
  parameter NB_DATA   = 8;
  parameter NB_OPCODE = 6;
  parameter NB_BUTTON = 3;

  // Cantidad de iteraciones aleatorias por operacion
  parameter NUM_TESTS = 1;

  // Entradas del top
  reg clk;
  reg reset;

  reg [NB_DATA-1:0]   switches;
  reg [NB_BUTTON-1:0] buttons;

  // Salida del top
  wire [NB_DATA-1:0] leds;

  // Valores utilizados por el testbench
  reg [NB_DATA-1:0]   A_data;
  reg [NB_DATA-1:0]   B_data;
  reg [NB_DATA-1:0]   expected;

  integer i;

  // Instancia del top_module
  top_module #(
    .NB_DATA(NB_DATA),
    .NB_OPCODE(NB_OPCODE),
    .NB_BUTTON(NB_BUTTON)
  ) DUT (
    .clk(clk),
    .reset(reset),
    .switches(switches),
    .buttons(buttons),
    .leds(leds)
  );

  // Generacion del clock
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  task run_test(
    input [NB_OPCODE-1:0] op,
    input [NB_DATA-1:0]   op_a,
    input [NB_DATA-1:0]   op_b,
    input [NB_DATA-1:0]   exp_result
  );
    begin
      // Cargo A
      switches   = op_a;
      buttons[0] = 1;
      #10;
      buttons[0] = 0;
      #10;

      // Cargo B
      switches   = op_b;
      buttons[1] = 1;
      #10;
      buttons[1] = 0;
      #10;

      // Cargo OP
      switches   = op;
      buttons[2] = 1;
      #10;
      buttons[2] = 0;
      #10;

      // Espero propagacion del resultado
      #10;

      // Verificacion
      if (leds === exp_result)
        $display(
          "OK: A=%d (%b) B=%d (%b) result=%d (%b)",
          op_a, op_a, op_b, op_b, leds, leds
        );
      else
        $display(
          "ERROR: A=%d (%b) B=%d (%b) expected=%d (%b) result=%d (%b)",
          op_a, op_a, op_b, op_b, exp_result, exp_result, leds, leds
        );
    end
  endtask

  // Pruebas
  initial begin

    switches = 0;
    buttons  = 0;
    reset    = 0;

    // Testeamos reset
    reset = 1;
    #10;

    reset = 0;
    #10;

    // 1) ADD
    $display("\nTesting Operation: 'ADD'");
    for (i = 0; i < NUM_TESTS; i = i + 1) begin
      A_data = $random;
      B_data = $random;
      expected = A_data + B_data;
      run_test(6'b100000, A_data, B_data, expected);
    end

    // 2) SUB
    $display("\nTesting Operation: 'SUB'");
    for (i = 0; i < NUM_TESTS; i = i + 1) begin
      A_data = $random;
      B_data = $random;
      expected = A_data - B_data;
      run_test(6'b100010, A_data, B_data, expected);
    end

    // 3) AND
    $display("\nTesting Operation: 'AND'");
    for (i = 0; i < NUM_TESTS; i = i + 1) begin
      A_data = $random;
      B_data = $random;
      expected = A_data & B_data;
      run_test(6'b100100, A_data, B_data, expected);
    end

    // 4) OR
    $display("\nTesting Operation: 'OR'");
    for (i = 0; i < NUM_TESTS; i = i + 1) begin
      A_data = $random;
      B_data = $random;
      expected = A_data | B_data;
      run_test(6'b100101, A_data, B_data, expected);
    end

    // 5) XOR
    $display("\nTesting Operation: 'XOR'");
    for (i = 0; i < NUM_TESTS; i = i + 1) begin
      A_data = $random;
      B_data = $random;
      expected = A_data ^ B_data;
      run_test(6'b100110, A_data, B_data, expected);
    end

    // 6) SRA
    $display("\nTesting Operation: 'SRA'");
    for (i = 0; i < NUM_TESTS; i = i + 1) begin
      A_data = $random;
      B_data = $random % NB_DATA;   // <-- acoto el shift a 0-7
      expected = $signed(A_data) >>> B_data;
      run_test(6'b000011, A_data, B_data, expected);
    end
    
    // 7) SRL
    $display("\nTesting Operation: 'SRL'");
    for (i = 0; i < NUM_TESTS; i = i + 1) begin
      A_data = $random;
      B_data = $random % NB_DATA;   // <-- acoto el shift a 0-7
      expected = A_data >> B_data;
      run_test(6'b000010, A_data, B_data, expected);
    end

    // 8) NOR
    $display("\nTesting Operation: 'NOR'");
    for (i = 0; i < NUM_TESTS; i = i + 1) begin
      A_data = $random;
      B_data = $random;
      expected = ~(A_data | B_data);
      run_test(6'b100111, A_data, B_data, expected);
    end

    $finish;

  end

endmodule
