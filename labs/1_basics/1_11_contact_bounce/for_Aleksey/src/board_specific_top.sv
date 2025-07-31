//----------------------------------------------------------------------------

module board_specific_top
(
    input  CLK,
    input  RESET,

    input  [3:0] KEY_SW,
    output [3:0] LED,

    output [7:0] SEG,
    output [3:0] DIG
);

    //------------------------------------------------------------------------

    wire clk =   CLK;
    wire rst = ~ RESET || ~KEY_SW[1];

    //------------------------------------------------------------------------

    wire [3:0] lab_led;

    // Seven-segment display

    wire [7:0] abcdefgh;
    wire [3:0] digit;

    //------------------------------------------------------------------------

    lab_top i_lab_top
    (
        .clk           (   clk           ),
        .rst           (   rst           ),

        .key           ( ~ KEY_SW        ),
        .sw            ( ~ KEY_SW        ),

        .led           (   lab_led       ),

        .abcdefgh      (   abcdefgh      ),
        .digit         (   digit         )

    );

    //------------------------------------------------------------------------

    assign LED       = ~ lab_led;

    assign SEG       = ~ abcdefgh;
    assign DIG       = ~ digit;

    //------------------------------------------------------------------------

endmodule
