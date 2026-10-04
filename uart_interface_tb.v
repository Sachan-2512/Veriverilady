`timescale 1ns / 1ps

module uart_interface_tb;

  parameter NB_DATA   = 8;
  parameter NB_OPCODE = 6;

  reg clk;
  reg reset;

  // Simulan las salidas del RX
  reg rx_done;
  reg [NB_DATA-1:0] rx_data;

  // Simula señal proveniente del TX
  reg tx_done;

  // Simula resultado de la ALU
  reg [NB_DATA-1:0] alu_result;

  // Salidas de la interface hacia ALU
  wire [NB_DATA-1:0] alu_A;
  wire [NB_DATA-1:0] alu_B;
  wire [NB_OPCODE-1:0] alu_OP;

  // Salidas de la interface hacia TX
  wire [NB_DATA-1:0] tx_data;
  wire tx_start;

  integer errors;

  // Flag del testbench:
  // recuerda si tx_start alguna vez se activó
  reg tx_start_seen;


  // ==========================================
  // DUT
  // ==========================================

  uart_interface #(
    .NB_DATA(NB_DATA),
    .NB_OPCODE(NB_OPCODE)
  ) DUT (
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


  // ==========================================
  // Clock
  // ==========================================

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end


  // ==========================================
  // Detectar tx_start
  // ==========================================

  always @(posedge clk) begin

    if (reset)
      tx_start_seen <= 1'b0;

    else if (tx_start)
      tx_start_seen <= 1'b1;

  end


  // ==========================================
  // Simular byte recibido por UART RX
  // ==========================================

  task send_rx_byte;

    input [7:0] value;

    begin

      rx_data = value;
      rx_done = 1'b1;

      #10;

      rx_done = 1'b0;

      #10;

    end

  endtask


  // ==========================================
  // Test principal
  // ==========================================

  initial begin

    errors = 0;

    reset         = 1;
    rx_done       = 0;
    rx_data       = 0;
    tx_done       = 0;
    alu_result    = 0;
    tx_start_seen = 0;

    #20;

    reset = 0;

    #20;


    // ========================================
    // 1) Cargar OP = ADD
    // ========================================

    $display("\nCargando OP = ADD");

    // Comando: el próximo byte será OP
    send_rx_byte(8'h03);

    // ADD = 100000 = 0x20
    send_rx_byte(8'h20);

    #10;

    if (alu_OP === 6'b100000)
      $display("OK OP: %b", alu_OP);

    else begin

      $display(
        "ERROR OP: esperado 100000, obtenido %b",
        alu_OP
      );

      errors = errors + 1;

    end


    // ========================================
    // 2) Cargar A = 5
    // ========================================

    $display("\nCargando A = 5");

    // Comando A
    send_rx_byte(8'h00);

    // Valor A
    send_rx_byte(8'd5);

    #10;

    if (alu_A === 8'd5)
      $display("OK A: %d", alu_A);

    else begin

      $display(
        "ERROR A: esperado 5, obtenido %d",
        alu_A
      );

      errors = errors + 1;

    end


    // ========================================
    // 3) Cargar B = 3
    // ========================================

    $display("\nCargando B = 3");

    // Comando B
    send_rx_byte(8'h01);

    // Valor B
    send_rx_byte(8'd3);

    #10;

    if (alu_B === 8'd3)
      $display("OK B: %d", alu_B);

    else begin

      $display(
        "ERROR B: esperado 3, obtenido %d",
        alu_B
      );

      errors = errors + 1;

    end


    // ========================================
    // 4) Simular resultado de la ALU
    // ========================================

    alu_result = 8'd8;

    #10;


    // ========================================
    // 5) Solicitar resultado
    // ========================================

    $display("\nSolicitando resultado");

    send_rx_byte(8'h02);


    // ========================================
    // 6) Verificar dato hacia TX
    // ========================================

    #1;

    if (tx_data === 8'd8)
      $display("OK tx_data: %d", tx_data);

    else begin

      $display(
        "ERROR tx_data: esperado 8, obtenido %d",
        tx_data
      );

      errors = errors + 1;

    end


    // ========================================
    // 7) Verificar que tx_start ocurrió
    // ========================================

    if (tx_start_seen === 1'b1)
      $display("OK tx_start generado");

    else begin

      $display("ERROR: tx_start nunca fue generado");

      errors = errors + 1;

    end


    // ========================================
    // 8) Simular finalización del TX
    // ========================================

    tx_done = 1'b1;

    #10;

    tx_done = 1'b0;

    #10;


    // ========================================
    // Resultado general
    // ========================================

    $display("\n==========================");

    if (errors == 0)
      $display("TEST OK: uart_interface correcta");

    else
      $display(
        "TEST ERROR: %0d errores",
        errors
      );

    $display("==========================\n");


    $finish;

  end

endmodule
