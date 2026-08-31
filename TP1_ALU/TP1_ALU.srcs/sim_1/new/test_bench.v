`timescale 1ns / 1ps

module test_bench;

  // Parámetros
  parameter NB_DATA   = 8;
  parameter NB_OPCODE = 6;
  parameter NB_BUTTON = 3;

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
  reg [NB_OPCODE-1:0] OP;
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


  // Generación del clock

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

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

    OP = 6'b100000;

    for (i = 0; i < 10; i = i + 1) begin

      // Genero valores aleatorios
      A_data = $random;
      B_data = $random;

      // Cargo A

      switches = A_data;
      buttons[0] = 1;
      #10;
      buttons[0] = 0;
      #10;
      
      // Cargo B

      switches = B_data;
      buttons[1] = 1;
      #10;
      buttons[1] = 0;
      #10;


      switches = OP;

      buttons[2] = 1;
      #10;

      buttons[2] = 0;
      #10;

      // Resultado esperado

      expected = A_data + B_data;

      #10;

      // Verificacion

      if (leds === expected)

        $display(
          "OK: A=%d (%b) B=%d (%b) result=%d (%b)",
          A_data, A_data,
          B_data, B_data,
          leds, leds
        );

      else

        $display(
          "ERROR: A=%d (%b) B=%d (%b) expected=%d (%b) result=%d (%b)",
          A_data, A_data,
          B_data, B_data,
          expected, expected,
          leds, leds
        );

    end
 
    // 2) SUB

    $display("\nTesting Operation: 'SUB'");

    OP = 6'b100010;

    for (i = 0; i < 10; i = i + 1) begin

      // Genero valores aleatorios
      A_data = $random;
      B_data = $random;

      // Cargo A

      switches = A_data;
      buttons[0] = 1;
      #10;
      buttons[0] = 0;
      #10;
      
      // Cargo B

      switches = B_data;
      buttons[1] = 1;
      #10;
      buttons[1] = 0;
      #10;


      switches = OP;

      buttons[2] = 1;
      #10;

      buttons[2] = 0;
      #10;

      // Resultado esperado

      expected = A_data - B_data;

      #10;

      // Verificacion

      if (leds === expected)

        $display(
          "OK: A=%d (%b) B=%d (%b) result=%d (%b)",
          A_data, A_data,
          B_data, B_data,
          leds, leds
        );

      else

        $display(
          "ERROR: A=%d (%b) B=%d (%b) expected=%d (%b) result=%d (%b)",
          A_data, A_data,
          B_data, B_data,
          expected, expected,
          leds, leds
        );

    end

    
    // 3) AND

    $display("\nTesting Operation: 'AND'");

    OP = 6'b100100;

    for (i = 0; i < 10; i = i + 1) begin

      // Genero valores aleatorios
      A_data = $random;
      B_data = $random;

      // Cargo A

      switches = A_data;
      buttons[0] = 1;
      #10;
      buttons[0] = 0;
      #10;
      
      // Cargo B

      switches = B_data;
      buttons[1] = 1;
      #10;
      buttons[1] = 0;
      #10;


      switches = OP;

      buttons[2] = 1;
      #10;

      buttons[2] = 0;
      #10;

      // Resultado esperado

      expected = A_data & B_data;

      #10;

      // Verificacion

      if (leds === expected)

        $display(
          "OK: A=%d (%b) B=%d (%b) result=%d (%b)",
          A_data, A_data,
          B_data, B_data,
          leds, leds
        );

      else

        $display(
          "ERROR: A=%d (%b) B=%d (%b) expected=%d (%b) result=%d (%b)",
          A_data, A_data,
          B_data, B_data,
          expected, expected,
          leds, leds
        );

    end

    
    // 4) OR

    $display("\nTesting Operation: 'OR'");

    OP = 6'b100101;

    for (i = 0; i < 10; i = i + 1) begin

      // Genero valores aleatorios
      A_data = $random;
      B_data = $random;

      // Cargo A

      switches = A_data;
      buttons[0] = 1;
      #10;
      buttons[0] = 0;
      #10;
      
      // Cargo B

      switches = B_data;
      buttons[1] = 1;
      #10;
      buttons[1] = 0;
      #10;


      switches = OP;

      buttons[2] = 1;
      #10;

      buttons[2] = 0;
      #10;

      // Resultado esperado

      expected = A_data | B_data;

      #10;

      // Verificacion

      if (leds === expected)

        $display(
          "OK: A=%d (%b) B=%d (%b) result=%d (%b)",
          A_data, A_data,
          B_data, B_data,
          leds, leds
        );

      else

        $display(
          "ERROR: A=%d (%b) B=%d (%b) expected=%d (%b) result=%d (%b)",
          A_data, A_data,
          B_data, B_data,
          expected, expected,
          leds, leds
        );

    end

    
    // 5) XOR

    $display("\nTesting Operation: 'XOR'");

    OP = 6'b100110;

    for (i = 0; i < 10; i = i + 1) begin

      // Genero valores aleatorios
      A_data = $random;
      B_data = $random;

      // Cargo A

      switches = A_data;
      buttons[0] = 1;
      #10;
      buttons[0] = 0;
      #10;
      
      // Cargo B

      switches = B_data;
      buttons[1] = 1;
      #10;
      buttons[1] = 0;
      #10;


      switches = OP;

      buttons[2] = 1;
      #10;

      buttons[2] = 0;
      #10;

      // Resultado esperado

      expected = A_data ^ B_data;

      #10;

      // Verificacion

      if (leds === expected)

        $display(
          "OK: A=%d (%b) B=%d (%b) result=%d (%b)",
          A_data, A_data,
          B_data, B_data,
          leds, leds
        );

      else

        $display(
          "ERROR: A=%d (%b) B=%d (%b) expected=%d (%b) result=%d (%b)",
          A_data, A_data,
          B_data, B_data,
          expected, expected,
          leds, leds
        );

    end

    
    // 6) SRA

    $display("\nTesting Operation: 'SRA'");

    OP = 6'b000011;

    for (i = 0; i < 10; i = i + 1) begin

      // Genero valores aleatorios
      A_data = $random;
      B_data = $random;

      // Cargo A

      switches = A_data;
      buttons[0] = 1;
      #10;
      buttons[0] = 0;
      #10;
      
      // Cargo B

      switches = B_data;
      buttons[1] = 1;
      #10;
      buttons[1] = 0;
      #10;


      switches = OP;

      buttons[2] = 1;
      #10;

      buttons[2] = 0;
      #10;

      // Resultado esperado

      expected = $signed(A_data) >>> B_data;

      #10;

      // Verificacion

      if (leds === expected)

        $display(
          "OK: A=%d (%b) B=%d (%b) result=%d (%b)",
          A_data, A_data,
          B_data, B_data,
          leds, leds
        );

      else

        $display(
          "ERROR: A=%d (%b) B=%d (%b) expected=%d (%b) result=%d (%b)",
          A_data, A_data,
          B_data, B_data,
          expected, expected,
          leds, leds
        );

    end

    
    // 7) SRL

    $display("\nTesting Operation: 'SRL'");

    OP = 6'b000010;

    for (i = 0; i < 10; i = i + 1) begin

      // Genero valores aleatorios
      A_data = $random;
      B_data = $random;

      // Cargo A

      switches = A_data;
      buttons[0] = 1;
      #10;
      buttons[0] = 0;
      #10;
      
      // Cargo B

      switches = B_data;
      buttons[1] = 1;
      #10;
      buttons[1] = 0;
      #10;


      switches = OP;

      buttons[2] = 1;
      #10;

      buttons[2] = 0;
      #10;

      // Resultado esperado

      expected = A_data >> B_data;

      #10;

      // Verificacion

      if (leds === expected)

        $display(
          "OK: A=%d (%b) B=%d (%b) result=%d (%b)",
          A_data, A_data,
          B_data, B_data,
          leds, leds
        );

      else

        $display(
          "ERROR: A=%d (%b) B=%d (%b) expected=%d (%b) result=%d (%b)",
          A_data, A_data,
          B_data, B_data,
          expected, expected,
          leds, leds
        );

    end

    
    // 8) NOR

    $display("\nTesting Operation: 'NOR'");

    OP = 6'b100111;

    for (i = 0; i < 10; i = i + 1) begin

      // Genero valores aleatorios
      A_data = $random;
      B_data = $random;

      // Cargo A

      switches = A_data;
      buttons[0] = 1;
      #10;
      buttons[0] = 0;
      #10;
      
      // Cargo B

      switches = B_data;
      buttons[1] = 1;
      #10;
      buttons[1] = 0;
      #10;


      switches = OP;

      buttons[2] = 1;
      #10;

      buttons[2] = 0;
      #10;

      // Resultado esperado

      expected = ~(A_data | B_data);

      #10;

      // Verificacion

      if (leds === expected)

        $display(
          "OK: A=%d (%b) B=%d (%b) result=%d (%b)",
          A_data, A_data,
          B_data, B_data,
          leds, leds
        );

      else

        $display(
          "ERROR: A=%d (%b) B=%d (%b) expected=%d (%b) result=%d (%b)",
          A_data, A_data,
          B_data, B_data,
          expected, expected,
          leds, leds
        );

    end


    $finish;

  end

endmodule