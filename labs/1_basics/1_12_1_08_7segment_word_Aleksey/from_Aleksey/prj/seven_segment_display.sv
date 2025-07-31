// модуль управления 7-сегментым индикатором

module seven_segment_display
# (
    parameter w_digit   = 2,
    parameter clk_mhz   = 50,
    parameter update_hz = 400
)
(
    input  clk,
    input  rst,

    input  [w_digit * 4 - 1:0] number,
    input  [w_digit     - 1:0] dots,

    output [              7:0] abcdefgh,
    output [w_digit     - 1:0] digit
);

    function [7:0] dig_to_seg (input [3:0] dig);

        case (dig)

        'h0: dig_to_seg = 'b11111100;  // a b c d e f g h
        'h1: dig_to_seg = 'b01100000;
        'h2: dig_to_seg = 'b11011010;  //   --a--
        'h3: dig_to_seg = 'b11110010;  //  |   |
        'h4: dig_to_seg = 'b01100110;  //  f   b
        'h5: dig_to_seg = 'b10110110;  //  |   |
        'h6: dig_to_seg = 'b10111110;  //   --g--
        'h7: dig_to_seg = 'b11100000;  //  |   |
        'h8: dig_to_seg = 'b11111110;  //  e   c
        'h9: dig_to_seg = 'b11100110;  //  |   |
        'ha: dig_to_seg = 'b11101110;  //   --d--  h
        'hb: dig_to_seg = 'b00111110;
        'hc: dig_to_seg = 'b10011100;
        'hd: dig_to_seg = 'b01111010;
        'he: dig_to_seg = 'b10011110;
        'hf: dig_to_seg = 'b10001110;

        endcase

    endfunction

    wire [7:0] space = 8'b0000_0000; // space

    // Calculate display update freq divider

    localparam integer BLINKPERIOD = 17;
    localparam integer SPEEDRUNLINE = 25;

    //------------------------------------------------------------------------

    logic [31:0] cnt;  // счётчик (делитель частоты)
    wire restart;      // управление сдвиговым регистром (переключаем индикатор - один из 4)
    wire enable;       // управляем символом (сегментами ССИ)

    always_ff @ (posedge clk)
        if (rst || restart) // сбрасываем счётчик по rst
		      // ИЛИ сбрасываем счётчик, когда вывели последовательно 10 символов в "слове"
            cnt <= '0;
        else
            cnt <= cnt + 1'd1;

    assign enable = (cnt [BLINKPERIOD-1:0] == '0);
    assign restart = (cnt [SPEEDRUNLINE+3:SPEEDRUNLINE] == 'd8); // 4 пробела + 4 цифры

    //--------------------------------------------------------------------------

    // задаём массив из 10 элементов типа seven_seg_encoding_e
    // это наше слово, которое будет бегать в бегуще строке
    wire [7:0] word[8];
    // "    22L102" - будет бегать это слово (здесь мы его задаём)
    assign word[0] = space;
    assign word[1] = space;
    assign word[2] = space;
    assign word[3] = space;
    assign word[4] = dig_to_seg(number[15:12]);
    assign word[5] = dig_to_seg(number[11: 8]);
    assign word[6] = dig_to_seg(number[ 7: 4]);
    assign word[7] = dig_to_seg(number[ 3: 0]);

    //--------------------------------------------------------------------------

    // индексы элементов в массиве word
    wire [3:0] inx_digit [4];
    assign inx_digit[0] = cnt[SPEEDRUNLINE+3:SPEEDRUNLINE];
    assign inx_digit[1] = cnt[SPEEDRUNLINE+3:SPEEDRUNLINE] + 4'd1;
    assign inx_digit[2] = cnt[SPEEDRUNLINE+3:SPEEDRUNLINE] + 4'd2;
    assign inx_digit[3] = cnt[SPEEDRUNLINE+3:SPEEDRUNLINE] + 4'd3;

    logic [7:0] letter;
    always_comb
      case (4' (digit)) // в зависимости от того, какой из четырёх СИИ светится
          // мы будем менять графику (выбираем нужный симол из массива word)
          4'b1000: letter = word[inx_digit[0]];
          4'b0100: letter = word[inx_digit[1]];
          4'b0010: letter = word[inx_digit[2]];
          4'b0001: letter = word[inx_digit[3]];
          default: letter = space;
      endcase


    //------------------------------------------------------------------------

    // сдвиговый регистр (гоняем единичку по кольцу)
    // 0001 -> 0010 -> 0100 -> 1000 -> 0001 -> ...
    // определяет какой из четырёх СИИ светится
    logic [3:0] shift_reg;

    always_ff @ (posedge clk or posedge rst)
      if (rst)
        shift_reg <= 4'(1);
      else if (enable)
        shift_reg <= { shift_reg [0], shift_reg [3:1] };

    //------------------------------------------------------------------------

    // Outputs are combinational like before
    assign abcdefgh = letter;
    assign digit    = shift_reg;

endmodule
