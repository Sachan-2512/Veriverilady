`timescale 1ns / 1ps

module baud_rate_gen_tb;

    localparam CLK_FREQ     = 160;
    localparam BAUD_RATE    = 10;
    localparam OVERSAMPLING = 4;

    reg clk;
    reg reset;

    wire tick;

    integer cycle_count;
    integer tick_count;


    baud_rate_gen #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .OVERSAMPLING(OVERSAMPLING)
    ) DUT (
        .clk(clk),
        .reset(reset),
        .tick(tick)
    );


    // Clock: período de 10 ns
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end


    initial begin

        reset       = 1;
        cycle_count = 0;
        tick_count  = 0;

        #20;
        reset = 0;


        // Miramos 20 ciclos
        repeat (20) begin

            @(posedge clk);

            cycle_count = cycle_count + 1;

            if (tick) begin
                tick_count = tick_count + 1;

                $display(
                    "Tick %0d en ciclo %0d",
                    tick_count,
                    cycle_count
                );
            end

        end


        if (tick_count == 5)
            $display("TEST OK: se generaron 5 ticks");
        else
            $display(
                "TEST ERROR: esperaba 5 ticks y obtuve %0d",
                tick_count
            );


        $finish;

    end

endmodule
