// Code your testbench here
// or browse Examples
`timescale 1ns / 1ps

module uart_rx_fsm_tb;

    reg clk;
    reg reset;

    reg rx;
    reg tick;

    reg mid_tick;
    reg bit_tick;
    reg last_bit;

    wire tick_clear;
    wire tick_inc;

    wire bit_clear;
    wire bit_inc;

    wire shift_data;
    wire rx_done;


    uart_rx_fsm DUT (
        .clk(clk),
        .reset(reset),

        .rx(rx),
        .tick(tick),

        .mid_tick(mid_tick),
        .bit_tick(bit_tick),
        .last_bit(last_bit),

        .tick_clear(tick_clear),
        .tick_inc(tick_inc),

        .bit_clear(bit_clear),
        .bit_inc(bit_inc),

        .shift_data(shift_data),
        .rx_done(rx_done)
    );


    // Clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end


    initial begin

        reset     = 1;

        rx        = 1;
        tick      = 0;

        mid_tick  = 0;
        bit_tick  = 0;
        last_bit  = 0;


        // Reset
        #10;
        reset = 0;

        #10;


        // =============================
        // IDLE -> START
        // =============================

        $display("Detectando START");

        rx = 0;

        #10;


        // =============================
        // START -> DATA
        // =============================

        tick     = 1;
        mid_tick = 1;

        #10;

        tick     = 0;
        mid_tick = 0;


        // =============================
        // DATA: bit normal
        // =============================

        tick      = 1;
        bit_tick  = 1;
        last_bit  = 0;

        #1;

        if (shift_data && bit_inc)
            $display("OK: captura bit intermedio");
        else
            $display("ERROR: captura bit intermedio");


        #9;

        tick     = 0;
        bit_tick = 0;


        // =============================
        // DATA: último bit
        // =============================

        tick      = 1;
        bit_tick  = 1;
        last_bit  = 1;

        #1;

        if (shift_data)
            $display("OK: captura ultimo bit");
        else
            $display("ERROR: ultimo bit");


        #9;

        tick      = 0;
        bit_tick  = 0;
        last_bit  = 0;


        // =============================
        // STOP terminado
        // =============================

        tick     = 1;
        bit_tick = 1;

        #1;

        if (rx_done)
            $display("OK: recepcion terminada");
        else
            $display("ERROR: rx_done no generado");


        #9;

        $finish;

    end

endmodule
