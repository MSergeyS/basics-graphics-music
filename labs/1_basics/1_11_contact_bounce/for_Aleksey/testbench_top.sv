`timescale 1 ns / 1 ps

module testbench_top;

    localparam clk_mhz = 100,
               w_key   = 4,
               w_sw    = 8,
               w_led   = 8,
               w_digit = 8,
               w_gpio  = 100;

    //------------------------------------------------------------------------

    logic       clk;
    logic       rst;
    logic [3:0] key;
    logic [7:0] sw;

    integer delay;

    //------------------------------------------------------------------------

    board_specific_top DUT
    (
        .CLK ( clk ),
        .RESET ( rst ),
        .KEY_SW ( key ),
        .LED (),
        .SEG (),
        .DIG ()
    );

    //------------------------------------------------------------------------

    initial
    begin
        clk = 1'b0;

        forever
            # 5 clk = ~ clk;
    end

    //------------------------------------------------------------------------

    initial
    begin
        rst <= 1'bx;
        repeat (2) @ (posedge clk);
        rst <= 1'b1;
        repeat (2) @ (posedge clk);
        rst <= 1'b0;
    end

    //------------------------------------------------------------------------

    initial
    begin
        `ifdef __ICARUS__
            $dumpfile("../out/dump.vcd");
            $dumpvars(0, testbench);
        `endif

        key <= '0;
        sw  <= '0;

        @ (negedge rst);

        repeat (50) @ (posedge clk);

        // To change only one key
        for (int n = 0; n < 10; n++) begin
           delay = $urandom_range(1, 100);
           #delay  key[0] <= ~key[0];
           delay = $urandom_range(1, 100);
           #delay  key[0] <= ~key[0];
        end
        delay = $urandom_range(1, 100);
        #delay  key[0] <= ~key[0];


        repeat (2000000)
           @ (posedge clk);

        $finish;
    end

endmodule
