`include "config.svh"

module lab_top
# (
    parameter  clk_mhz       = 50,
               w_key         = 4,
               w_sw          = 8,
               w_led         = 8,
               w_digit       = 8,
               w_gpio        = 100,

               screen_width  = 640,
               screen_height = 480,

               w_red         = 4,
               w_green       = 4,
               w_blue        = 4,

               w_x           = $clog2 ( screen_width  ),
               w_y           = $clog2 ( screen_height )
)
(
    input                        clk,
    input                        slow_clk,
    input                        rst,

    // Keys, switches, LEDs

    input        [w_key   - 1:0] key,
    input        [w_sw    - 1:0] sw,
    output logic [w_led   - 1:0] led,

    // A dynamic seven-segment display

    output logic [          7:0] abcdefgh,
    output logic [w_digit - 1:0] digit,

    // Graphics

    input        [w_x     - 1:0] x,
    input        [w_y     - 1:0] y,

    output logic [w_red   - 1:0] red,
    output logic [w_green - 1:0] green,
    output logic [w_blue  - 1:0] blue,

    // Microphone, sound output and UART

    input        [         23:0] mic,
    output       [         15:0] sound,

    input                        uart_rx,
    output                       uart_tx,

    // General-purpose Input/Output

    inout        [w_gpio  - 1:0] gpio
);

    //------------------------------------------------------------------------

    // assign led        = '0;
    // assign abcdefgh   = '0;
    // assign digit      = '0;
       assign red        = '0;
       assign green      = '0;
       assign blue       = '0;
       assign sound      = '0;
       assign uart_tx    = '1;

    //------------------------------------------------------------------------

    // выделяем изменение сигнала с кнопки key [0]
    reg q_key, q_key_d;
    logic bounch;
    reg q_bounch;

    always_ff @ (posedge clk or posedge rst)
        if (rst) begin
            q_key <= 1'b0;
            q_key_d <= 1'b0;
        end else // задержанный на 1 такт clk сигнал key [0]
        begin
            q_key <= key [0];
            q_key_d <= q_key;
        end

    assign bounch = (q_key ^ q_key_d); // если сигналы не равны - нажимали кнопку
    always_ff @ (posedge clk)
        q_bounch <= bounch; // задерживаем на 1 период clk (надо для timer)
    //------------------------------------------------------------------------

    // счётчик изменений состояний key [0]
    logic [10:0] cnt_bounch; // если сделать разрядность 14 бит,
                             // то в обратку считает до 15 и останавливается
    wire n_500ms_i;
    always_ff @ (posedge clk or posedge rst)
        if (rst)
            cnt_bounch <= '0;
        else if (key [1]) // сброс по кнопке key [1]
            cnt_bounch <= '0;
        else if (n_500ms_i) // возвращение (уменьшаем счётчик на 1 каждые 0,5 с
            cnt_bounch <= cnt_bounch - 1'd1;
        else if (bounch)  // считаем число изменении сигнала
            cnt_bounch <= cnt_bounch + 1'd1;

    //------------------------------------------------------------------------

    // таймер
    timer # ( .CLKMHZ(clk_mhz) ) tmr (
        .clk(clk),
        .rst(reset_tmr),
        .start(q_bounch),
        .out_500ms_i(n_500ms_i)
    );

    // сигнал сброса таймера
    wire reset_tmr; // по rst, или по нажатию кнопки, или когда счётчик днажатий кнопки пуст
    assign reset_tmr = (rst || key [1] || (cnt_bounch == '0));

    //------------------------------------------------------------------------

    // поморгаем светодтодом
    // задерживаем импульс n_500ms_i на 100 ms
    logic [31:0] cnt_100ms;
    wire cnt_is_zero;
    wire n_100ms_i;
    reg q_100ms;
    reg q_100ms_d;

    assign cnt_is_zero = (cnt_100ms == '0); // счётчик = 0
    always_ff @ (posedge clk or posedge rst)
        if (rst)
            q_100ms <= '1; // по rst cnt_100ms == 0
        else if (key [1])
            q_100ms <= '1; // по rst cnt_100ms == 0
        else
            q_100ms <= cnt_is_zero; // задержали на 1 такт clk
    // формируем импульс
    assign n_100ms_i = cnt_is_zero & ~q_100ms;

    always_ff @ (posedge clk or posedge rst)
        if (rst)  // сброс по rst
            cnt_100ms <= '0;
        else if (key [1]) // сброс по нажатию кнопки
            cnt_100ms <= '0;
        else if (n_500ms_i) // взводим таймер на 100 мс
            cnt_100ms <= (clk_mhz*100*1000) -  1'd1;
        else if (~cnt_is_zero) // уменьшаем на 1 пока не будет = 0
            cnt_100ms <= cnt_100ms - 1'd1;

    //------------------------------------------------------------------------

    // T-тригер
    reg q_led;
    always_ff @ (posedge clk or posedge rst)
        if (rst) // сброс по rst
            q_led <= 1'b0;
        else if (key [1]) // сброс по нажатию кнопки
            q_led <= 1'b0;
        else if (n_500ms_i || n_100ms_i)
            // инвертируем значение q_led каждый импульс n_500ms_i
            q_led <= ~q_led;

    assign led[0] = q_led; // выводим на светодиод

    //------------------------------------------------------------------------

    // преобразуем двоичный код в двоично-десятичный (BCD)
    wire [15:0] cnt_bcd;
    binary_coded_decimal #(
        .BWIDTH(14),
        .DWIDTH(16) //must be multiple of 4
    ) i_bdc
    (
       .clk(clk),
       .res_n(~rst),
       .bin_in({3'b000, cnt_bounch}),
       .dec_out(cnt_bcd)
    );

    //------------------------------------------------------------------------

    /// выводи число на 4 7-ми сегментных индикатора
    localparam w_display_number = w_digit * 4;

    seven_segment_display # (w_digit) i_7segment
    (
        .clk      ( clk                       ),
        .rst      ( rst                       ),
        .number   ( w_display_number' (cnt_bcd) ),
        .dots     ( w_digit' (0)              ),
        .abcdefgh ( abcdefgh                  ),
        .digit    ( digit                     )
    );

    //------------------------------------------------------------------------

endmodule
