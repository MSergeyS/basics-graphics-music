module lab_top
(
    input        clk,
    input        rst,

    // Keys, switches, LEDs

    input        [3:0] key,
    input        [3:0] sw,
    output logic [3:0] led,

    // A dynamic seven-segment display

    output logic [7:0] abcdefgh,
    output logic [3:0] digit
);

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
    assign restart = (cnt [SPEEDRUNLINE+3:SPEEDRUNLINE] == 'd10);

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

    // assign led = 4'(shift_reg);

    //------------------------------------------------------------------------

    // делаем свой тип данных, называем его seven_seg_encoding_e
    // он представляет собой 8 битный массив
    // далее, используя его, можем не писать  код из 8 бит типа "8'b0001_1100",
    // а можем написать просто "L" (графика символа L на ССИ)
    //   --a--
    //  |     |
    //  f     b
    //  |     |
    //   --g--
    //  |     |
    //  e     c
    //  |     |
    //   --d--  h
    typedef enum bit [7:0]
    {
        L     = 8'b0001_1100,
        zero  = 8'b1111_1100,
        one   = 8'b0110_0000,
        two   = 8'b1101_1010,
        space = 8'b0000_0000
    }
    seven_seg_encoding_e;

    //--------------------------------------------------------------------------

    // задаём массив из 10 элементов типа seven_seg_encoding_e
    // это наше слово, которое будет бегать в бегуще строке
    seven_seg_encoding_e word[10];
    // "    22L102" - будет бегать это слово (здесь мы его задаём)
    assign word[0] = space;
    assign word[1] = space;
    assign word[2] = space;
    assign word[3] = space;
    assign word[4] = two;
    assign word[5] = two;
    assign word[6] = L;
    assign word[7] = one;
    assign word[8] = zero;
    assign word[9] = two;

    //--------------------------------------------------------------------------

    // индексы элементов в массиве word
    wire [3:0] inx_digit [4];
    assign inx_digit[0] = cnt[SPEEDRUNLINE+3:SPEEDRUNLINE];
    assign inx_digit[1] = cnt[SPEEDRUNLINE+3:SPEEDRUNLINE] + 4'd1;
    assign inx_digit[2] = cnt[SPEEDRUNLINE+3:SPEEDRUNLINE] + 4'd2;
    assign inx_digit[3] = cnt[SPEEDRUNLINE+3:SPEEDRUNLINE] + 4'd3;

    seven_seg_encoding_e letter;
    always_comb
      case (4' (shift_reg)) // в зависимости от того, какой из четырёх СИИ светится
          // мы будем менять графику (выбираем нужный симол из массива word)
          4'b1000: letter = seven_seg_encoding_e'(word[inx_digit[0]]);
          4'b0100: letter = seven_seg_encoding_e'(word[inx_digit[1]]);
          4'b0010: letter = seven_seg_encoding_e'(word[inx_digit[2]]);
          4'b0001: letter = seven_seg_encoding_e'(word[inx_digit[3]]);
          default: letter = space;
      endcase

    assign abcdefgh = letter;
    assign digit    = shift_reg;

endmodule
