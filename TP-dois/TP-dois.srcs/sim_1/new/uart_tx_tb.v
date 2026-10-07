// Code your testbench here
`timescale 1ns / 1ps

module uart_tx_tb;

    reg clk;
    reg reset;

    reg tx_start;
    reg [7:0] tx_data;
    reg tick;

    wire tx;
    wire tx_done;

    // Byte a transmitir
    localparam [7:0] TEST_BYTE = 8'hA6; // 10100110

    // Bits esperados en LSB-first: 0,1,1,0,0,1,0,1
    reg [7:0] expected_bits;
    reg [9:0] captured_frame; // START + 8 datos + STOP
    integer bit_index;
    integer errors;


    uart_tx DUT (
        .clk(clk),
        .reset(reset),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tick(tick),
        .tx(tx),
        .tx_done(tx_done)
    );


    // Clock: periodo de 10 ns
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end


    // Genera un tick durante un ciclo
    task send_tick;
    begin
        tick = 1;
        #10;

        tick = 0;
        #10;
    end
    endtask


    // Espera un bit completo (16 ticks) y captura tx en el centro (tick 8)
    task capture_bit;
        output captured_value;

        integer j;
        reg captured_value;

        begin
            captured_value = 1'bx;

            for (j = 0; j < 16; j = j + 1) begin
                if (j == 8) begin
                    captured_value = tx; // Muestreo en el centro del bit
                end
                send_tick;
            end
        end
    endtask


    initial begin

        reset    = 1;
        tx_start = 0;
        tx_data  = 0;
        tick     = 0;
        errors   = 0;

        #20;

        reset = 0;

        #20;


        // Configurar el byte a enviar y dar el pulso de inicio
        $display("=== Transmitiendo byte 0x%h ===", TEST_BYTE);

        tx_data  = TEST_BYTE;
        tx_start = 1;

        @(posedge clk);
        #1;

        tx_start = 0; // Solo un ciclo de pulso


        // Capturar START bit
        capture_bit(captured_frame[0]);
        $display("START bit: %b (esperado: 0)", captured_frame[0]);

        if (captured_frame[0] !== 1'b0) begin
            $display("  ERROR: START bit incorrecto");
            errors = errors + 1;
        end


        // Capturar 8 bits de datos
        for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1) begin
            capture_bit(captured_frame[bit_index + 1]);

            $display("D%0d: %b (esperado: %b)",
                bit_index,
                captured_frame[bit_index + 1],
                TEST_BYTE[bit_index]
            );

            if (captured_frame[bit_index + 1] !== TEST_BYTE[bit_index]) begin
                $display("  ERROR: bit D%0d incorrecto", bit_index);
                errors = errors + 1;
            end
        end


        // Capturar STOP bit
        capture_bit(captured_frame[9]);
        $display("STOP bit: %b (esperado: 1)", captured_frame[9]);

        if (captured_frame[9] !== 1'b1) begin
            $display("  ERROR: STOP bit incorrecto");
            errors = errors + 1;
        end


        // Esperar un poco y verificar tx_done
        #20;


        // Resultado final
        $display("===========================");

        if (errors == 0)
            $display("TEST OK: trama completa correcta para 0x%h", TEST_BYTE);
        else
            $display("TEST ERROR: %0d errores encontrados", errors);

        $display("Trama capturada: START=%b DATA=%b STOP=%b",
            captured_frame[0],
            captured_frame[8:1],
            captured_frame[9]
        );

        $finish;

    end

endmodule
