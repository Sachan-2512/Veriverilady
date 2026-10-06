`timescale 1ns / 1ps

module top_tb;

    // ==========================================
    // Parámetros
    // ==========================================

    parameter NB_DATA      = 8;
    parameter NB_OPCODE    = 6;

    parameter CLK_FREQ     = 50_000_000;
    parameter BAUD_RATE    = 19_200;
    parameter OVERSAMPLING = 16;

    // Tu baud_rate_gen actual usa 163 fijo
    localparam CYCLES_PER_TICK = 163;

    // Clock de entrada del top (entrada del clk_wiz_0): 100 MHz => 10 ns
    localparam CLK_IN_PERIOD = 10;

    // Clock interno (salida del clk_wiz_0): 50 MHz => 20 ns
    localparam CLK_PERIOD = 20;

    // Un bit UART dura 16 ticks
    localparam BIT_TIME =
        CYCLES_PER_TICK * OVERSAMPLING * CLK_PERIOD;


    // ==========================================
    // Señales externas del TOP
    // ==========================================

    reg clk;
    reg reset;

    reg rx;
    wire tx;


    // ==========================================
    // Variables del testbench
    // ==========================================

    reg [7:0] received_byte;

    integer errors;


    // ==========================================
    // DUT
    // ==========================================

    top #(
        .NB_DATA(NB_DATA),
        .NB_OPCODE(NB_OPCODE),
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .OVERSAMPLING(OVERSAMPLING)
    ) DUT (
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .tx(tx)
    );


    // ==========================================
    // Generación del clock (100 MHz hacia el wizard)
    // ==========================================

    initial begin
        clk = 0;
        forever #(CLK_IN_PERIOD/2)
            clk = ~clk;
    end


    // ==========================================
    // Tarea: enviar un byte UART por RX
    // ==========================================

    task send_uart_byte;

        input [7:0] data;

        integer bit_index;

        begin

            $display(
                "Enviando UART: 0x%02h (%b)",
                data,
                data
            );


            // ------------------------------
            // START
            // ------------------------------

            rx = 1'b0;

            #(BIT_TIME);


            // ------------------------------
            // DATA
            // LSB primero
            // ------------------------------

            for (
                bit_index = 0;
                bit_index < 8;
                bit_index = bit_index + 1
            ) begin

                rx = data[bit_index];

                #(BIT_TIME);

            end


            // ------------------------------
            // STOP
            // ------------------------------

            rx = 1'b1;

            #(BIT_TIME);

        end

    endtask


    // ==========================================
    // Tarea: recibir un byte UART desde TX
    // ==========================================

    task receive_uart_byte;

        output [7:0] data;

        integer bit_index;

        begin

            data = 0;


            // Esperamos comienzo del START
            @(negedge tx);


            // Nos movemos al centro del START
            #(BIT_TIME/2);


            // Verificación del START
            if (tx !== 1'b0) begin

                $display(
                    "ERROR: START invalido, tx=%b",
                    tx
                );

                errors = errors + 1;

            end


            // ------------------------------
            // Leer D0 ... D7
            // ------------------------------

            for (
                bit_index = 0;
                bit_index < 8;
                bit_index = bit_index + 1
            ) begin

                // Pasamos al centro del siguiente bit
                #(BIT_TIME);

                data[bit_index] = tx;

                $display(
                    "RX desde TX: D%0d = %b",
                    bit_index,
                    tx
                );

            end


            // ------------------------------
            // STOP
            // ------------------------------

            #(BIT_TIME);

            if (tx !== 1'b1) begin

                $display(
                    "ERROR: STOP invalido, tx=%b",
                    tx
                );

                errors = errors + 1;

            end

        end

    endtask


    // ==========================================
    // TEST PRINCIPAL
    // ==========================================

    initial begin

        errors = 0;

        reset = 1'b1;

        // UART en reposo
        rx = 1'b1;


        // ======================================
        // RESET
        // ======================================

        // Esperamos a que el clk_wiz_0 entregue el clock de 50 MHz
        @(posedge DUT.clk_50MHz);
        repeat (20) @(posedge DUT.clk_50MHz);

        reset = 1'b0;

        repeat (10) @(posedge DUT.clk_50MHz);


        $display("");
        $display("==============================");
        $display(" TEST COMPLETO UART + ALU");
        $display("==============================");
        $display("");


        // ======================================
        // 1) Cargar OP = ADD
        // ======================================

        $display("1) Cargando OP = ADD");

        // 0x03 = próximo byte es operador
        send_uart_byte(8'h03);

        // 0x20 = ADD = 100000
        send_uart_byte(8'h20);


        // ======================================
        // 2) Cargar A = 5
        // ======================================

        $display("");
        $display("2) Cargando A = 5");

        // 0x00 = próximo byte es A
        send_uart_byte(8'h00);

        // A = 5
        send_uart_byte(8'h05);


        // ======================================
        // 3) Cargar B = 3
        // ======================================

        $display("");
        $display("3) Cargando B = 3");

        // 0x01 = próximo byte es B
        send_uart_byte(8'h01);

        // B = 3
        send_uart_byte(8'h03);


        // ======================================
        // DEBUG antes de pedir resultado
        // ======================================

        #(BIT_TIME);

        $display("");
        $display("DEBUG INTERNO:");

        $display(
            "A=%0d B=%0d OP=%b RESULT=%0d TX_DATA=%0d",
            DUT.alu_A,
            DUT.alu_B,
            DUT.alu_OP,
            DUT.alu_result,
            DUT.tx_data
        );


        // ======================================
        // 4) Pedir resultado
        // 5) Recibir respuesta en paralelo
        // ======================================

        $display("");
        $display("4) Solicitando resultado");
        $display("5) Esperando respuesta UART...");


        fork

            // ----------------------------------
            // Proceso 1:
            // enviar GET_RESULT
            // ----------------------------------

            begin

                send_uart_byte(8'h02);

            end


            // ----------------------------------
            // Proceso 2:
            // escuchar TX desde antes
            // de que empiece START
            // ----------------------------------

            begin

                receive_uart_byte(received_byte);

            end

        join


        // ======================================
        // 6) Resultado recibido
        // ======================================

        $display("");

        $display(
            "Byte recibido desde TX = %0d (%b)",
            received_byte,
            received_byte
        );


        if (received_byte === 8'd8) begin

            $display(
                "OK: resultado recibido = %0d (%b)",
                received_byte,
                received_byte
            );

        end
        else begin

            $display(
                "ERROR: esperado 8, recibido %0d (%b)",
                received_byte,
                received_byte
            );

            errors = errors + 1;

        end


        // ======================================
        // RESULTADO FINAL
        // ======================================

        $display("");
        $display("==============================");

        if (errors == 0)
            $display(
                "TEST OK: SISTEMA COMPLETO CORRECTO"
            );

        else
            $display(
                "TEST ERROR: %0d errores",
                errors
            );

        $display("==============================");
        $display("");


        $finish;

    end

endmodule