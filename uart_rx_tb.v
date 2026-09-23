// Code your testbench here
// or browse Examples
`timescale 1ns / 1ps

module uart_rx_tb;

    reg clk;
    reg reset;

    reg rx;
    reg tick;

    wire [7:0] data_out;
    wire rx_done;


    uart_rx DUT (
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .tick(tick),
        .data_out(data_out),
        .rx_done(rx_done)
    );


    // Clock
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


    // Mantiene un bit UART durante 16 ticks
    task send_uart_bit;

        input bit_value;

        integer j;

        begin

            rx = bit_value;

            for (j = 0; j < 16; j = j + 1)
                send_tick;

        end

    endtask


    initial begin

        reset = 1;
        rx    = 1;
        tick  = 0;

        #20;

        reset = 0;

        #20;


        $display("Enviando byte 0xA5");


        // START
        send_uart_bit(1'b0);


        // DATA = 0xA5 = 10100101
        // UART envía LSB primero

        send_uart_bit(1'b1); // D0
        send_uart_bit(1'b0); // D1
        send_uart_bit(1'b1); // D2
        send_uart_bit(1'b0); // D3
        send_uart_bit(1'b0); // D4
        send_uart_bit(1'b1); // D5
        send_uart_bit(1'b0); // D6
        send_uart_bit(1'b1); // D7


        // STOP
        send_uart_bit(1'b1);


        #20;


        if (data_out === 8'hA5)
            $display(
                "TEST OK: recibido = %h (%b)",
                data_out,
                data_out
            );
        else
            $display(
                "TEST ERROR: esperado A5, recibido = %h (%b)",
                data_out,
                data_out
            );


        $finish;

    end

endmodule
