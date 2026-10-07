`timescale 1ns / 1ps

module uart_interface_tb;

  localparam NB_DATA = 8;
  localparam NB_ALU_OP = 6;
  localparam CLK_PERIOD = 20;

  localparam [NB_DATA-1:0] TEST_A = 8'h15;
  localparam [NB_DATA-1:0] TEST_B = 8'h03;
  localparam [NB_DATA-1:0] TEST_OPCODE_BYTE = 8'hE0;
  localparam [NB_ALU_OP-1:0] TEST_OPCODE = 6'b100000;
  localparam [NB_DATA-1:0] TEST_RESULT = 8'h18;
  localparam [NB_DATA-1:0] NEXT_A = 8'h3C;

  reg i_clk;
  reg i_reset;
  reg i_rx_done;
  reg i_tx_done;
  reg [NB_DATA-1:0] i_rx_data;
  reg [NB_DATA-1:0] i_alu_data_out;

  wire [NB_DATA-1:0] o_tx_data;
  wire [NB_ALU_OP-1:0] o_alu_op;
  wire [NB_DATA-1:0] o_alu_data_A;
  wire [NB_DATA-1:0] o_alu_data_B;
  wire o_tx_start;

  integer checks;
  integer errors;

  uart_interface #(
      .NB_DATA(NB_DATA),
      .NB_ALU_OP(NB_ALU_OP)
  ) DUT (
      .i_clk(i_clk),
      .i_reset(i_reset),
      .i_rx_done(i_rx_done),
      .i_tx_done(i_tx_done),
      .i_rx_data(i_rx_data),
      .i_alu_data_out(i_alu_data_out),
      .o_tx_data(o_tx_data),
      .o_alu_op(o_alu_op),
      .o_alu_data_A(o_alu_data_A),
      .o_alu_data_B(o_alu_data_B),
      .o_tx_start(o_tx_start)
  );

  initial begin
    i_clk = 1'b0;
    forever #(CLK_PERIOD / 2) i_clk = ~i_clk;
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

  task send_rx_byte;
    input [NB_DATA-1:0] value;
    begin
      @(negedge i_clk);
      i_rx_data = value;
      i_rx_done = 1'b1;

      @(posedge i_clk);
      #1;
      i_rx_done = 1'b0;
    end
  endtask

  task pulse_tx_done;
    begin
      @(negedge i_clk);
      i_tx_done = 1'b1;

      @(posedge i_clk);
      #1;
      i_tx_done = 1'b0;
    end
  endtask

  initial begin
    i_reset = 1'b1;
    i_rx_done = 1'b0;
    i_tx_done = 1'b0;
    i_rx_data = {NB_DATA{1'b0}};
    i_alu_data_out = {NB_DATA{1'b0}};
    checks = 0;
    errors = 0;

    repeat (2) @(posedge i_clk);
    #1;

    // 1. Reset: la FSM comienza en WAIT_A y el datapath queda limpio.
    check((o_alu_data_A === {NB_DATA{1'b0}}) &&
              (o_alu_data_B === {NB_DATA{1'b0}}) &&
              (o_alu_op === {NB_ALU_OP{1'b0}}) &&
              (o_tx_data === {NB_DATA{1'b0}}) &&
              (o_tx_start === 1'b0),
          "reset inicializa las salidas de la interfaz");

    i_reset = 1'b0;
    @(posedge i_clk);
    #1;

    // 2. Sin rx_done, el valor presente en el bus RX no debe capturarse.
    i_rx_data = 8'hAA;
    @(posedge i_clk);
    #1;
    check(o_alu_data_A === {NB_DATA{1'b0}},
          "i_rx_data no se captura sin un pulso i_rx_done");

    // 3. El primer byte valido recorre RX -> registro A.
    send_rx_byte(TEST_A);
    check((o_alu_data_A === TEST_A) &&
              (o_alu_data_B === {NB_DATA{1'b0}}) &&
              (o_alu_op === {NB_ALU_OP{1'b0}}) &&
              (o_tx_start === 1'b0),
          "el primer byte se registra como A");

    // 4. El segundo byte recorre RX -> registro B y A se conserva.
    send_rx_byte(TEST_B);
    check((o_alu_data_A === TEST_A) &&
              (o_alu_data_B === TEST_B) &&
              (o_alu_op === {NB_ALU_OP{1'b0}}) &&
              (o_tx_start === 1'b0),
          "el segundo byte se registra como B y conserva A");

    // 5. El tercer byte registra el opcode y deja a la FSM en EXECUTE.
    send_rx_byte(TEST_OPCODE_BYTE);
    check((o_alu_data_A === TEST_A) &&
              (o_alu_data_B === TEST_B) &&
              (o_alu_op === TEST_OPCODE) &&
              (o_tx_start === 1'b0),
          "el tercer byte registra los bits inferiores del opcode");

    // 6. EXECUTE captura la salida combinacional de la ALU e inicia TX.
    i_alu_data_out = TEST_RESULT;
    @(posedge i_clk);
    #1;
    check((o_tx_data === TEST_RESULT) && (o_tx_start === 1'b1),
          "EXECUTE captura el resultado y activa tx_start");

    // 7. En WAIT_TX, tx_start termina y el resultado permanece estable.
    @(posedge i_clk);
    #1;
    check((o_tx_data === TEST_RESULT) && (o_tx_start === 1'b0),
          "WAIT_TX conserva el resultado y finaliza el pulso tx_start");

    // 8. tx_done cierra la operacion; el siguiente byte vuelve a ser A.
    pulse_tx_done;
    send_rx_byte(NEXT_A);
    check(o_alu_data_A === NEXT_A,
          "tx_done permite comenzar una nueva operacion desde A");

    $display("----------------------------------------");
    if (errors == 0) begin
      $display("TEST OK: %0d verificaciones superadas", checks);
    end else begin
      $display("TEST ERROR: %0d de %0d verificaciones fallaron",
               errors, checks);
    end

    $finish;
  end

endmodule
