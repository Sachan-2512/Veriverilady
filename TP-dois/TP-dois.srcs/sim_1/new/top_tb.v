`timescale 1ns / 1ps

module top_tb;

  localparam CLK_100MHZ_PERIOD = 10;
  localparam BAUD_RATE = 19200;
  localparam BIT_PERIOD = 1000000000 / BAUD_RATE;
  localparam SIM_TIMEOUT = 5000000;

  localparam [7:0] TEST_A = 8'h15;
  localparam [7:0] TEST_B = 8'h03;
  localparam [7:0] TEST_OPCODE = 8'h20;
  localparam [7:0] EXPECTED_RESULT = 8'h18;

  reg clk;
  reg reset;
  reg rx;

  wire tx;

  reg [7:0] received_result;
  reg received_stop_bit;
  reg test_finished;

  integer checks;
  integer errors;

  real first_edge_time;
  real second_edge_time;
  real measured_period;

  top DUT (
      .clk  (clk),
      .reset(reset),
      .rx   (rx),
      .tx   (tx)
  );

  // Clock fisico de la Basys 3: periodo de 10 ns, frecuencia de 100 MHz.
  initial begin
    clk = 1'b0;
    forever #(CLK_100MHZ_PERIOD / 2) clk = ~clk;
  end

  task check;
    input condition;
    input [8*80-1:0] message;
    begin
      checks = checks + 1;
      if (condition !== 1'b1) begin
        errors = errors + 1;
        $display("ERROR: %0s", message);
      end else begin
        $display("OK:    %0s", message);
      end
    end
  endtask

  // Emula el TX de la terminal: start, ocho bits LSB-first y stop.
  task send_uart_byte;
    input [7:0] data;
    integer bit_index;
    begin
      rx = 1'b0;
      #(BIT_PERIOD);

      for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1) begin
        rx = data[bit_index];
        #(BIT_PERIOD);
      end

      rx = 1'b1;
      #(BIT_PERIOD);
    end
  endtask

  // Emula el RX de la terminal y muestrea cada bit en el centro de su periodo.
  task receive_uart_byte;
    output [7:0] data;
    output stop_bit;
    integer bit_index;
    begin
      data = 8'h00;
      stop_bit = 1'b0;

      @(negedge tx);
      #(BIT_PERIOD + BIT_PERIOD / 2);

      for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1) begin
        data[bit_index] = tx;
        #(BIT_PERIOD);
      end

      stop_bit = tx;
    end
  endtask

  // Evita que una ausencia de locked o de respuesta deje la simulacion bloqueada.
  initial begin
    #(SIM_TIMEOUT);
    if (!test_finished) begin
      $display("----------------------------------------");
      $display("TEST ERROR: timeout sin completar la integracion UART");
      $finish;
    end
  end

  initial begin
    reset = 1'b1;
    rx = 1'b1;
    received_result = 8'h00;
    received_stop_bit = 1'b0;
    test_finished = 1'b0;
    checks = 0;
    errors = 0;

    // 1. El modelo del Clocking Wizard debe alcanzar el estado locked.
    wait (DUT.clock_locked === 1'b1);
    check(DUT.clock_locked === 1'b1, "el Clocking Wizard activa locked");

    // 2. Dos flancos consecutivos deben confirmar el clock interno de 50 MHz.
    @(posedge DUT.clk_50MHz);
    first_edge_time = $realtime;
    @(posedge DUT.clk_50MHz);
    second_edge_time = $realtime;
    measured_period  = second_edge_time - first_edge_time;

    check((measured_period >= 19.9) && (measured_period <= 20.1),
          "el clock interno tiene un periodo de 20 ns");

    // 3. El reset externo debe mantener reseteado el dominio de 50 MHz.
    check(DUT.reset_50MHz === 1'b1, "el reset interno permanece activo mientras reset vale uno");

    // 4. La liberacion atraviesa los dos registros del sincronizador.
    @(negedge DUT.clk_50MHz);
    reset = 1'b0;

    @(posedge DUT.clk_50MHz);
    #1;
    check(DUT.reset_50MHz === 1'b1, "el reset interno sigue activo durante el primer flanco");

    @(posedge DUT.clk_50MHz);
    #1;
    check(DUT.reset_50MHz === 1'b0, "el reset interno se libera en el segundo flanco");

    // 5. La notebook envia A, B y opcode mientras espera la respuesta en TX.
    fork
      begin
        send_uart_byte(TEST_A);
        send_uart_byte(TEST_B);
        send_uart_byte(TEST_OPCODE);
      end

      begin
        receive_uart_byte(received_result, received_stop_bit);
      end
    join

    // 6. La trama devuelta debe tener stop valido y el resultado de la suma.
    check(received_stop_bit === 1'b1, "la respuesta UART contiene un stop bit valido");
    check(received_result === EXPECTED_RESULT,
          "la respuesta UART contiene el resultado esperado de la ALU");

    test_finished = 1'b1;
    $display("----------------------------------------");
    if (errors == 0) begin
      $display("TEST OK: %0d verificaciones superadas", checks);
    end else begin
      $display("TEST ERROR: %0d de %0d verificaciones fallaron", errors, checks);
    end

    $finish;
  end

endmodule
