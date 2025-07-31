module lab_top
# (
    parameter  clk_mhz       = 50,
               w_key         = 4,
               w_sw          = 4,
               w_led         = 4,
               w_digit       = 4
)
(
    input                        clk,
    input                        rst,

    // Keys, switches, LEDs

    input        [w_key   - 1:0] key,
    input        [w_sw    - 1:0] sw,
    output logic [w_led   - 1:0] led,

    // A dynamic seven-segment display

    output logic [          7:0] abcdefgh,
    output logic [w_digit - 1:0] digit
);

    assign led[w_led - 1:1] = '0;

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
        else if (n_500ms_i) // возвращение (уменьшаем счётчик на 1 каждые 0,5 с
            cnt_bounch <= cnt_bounch - 1'd1;
        else if (bounch)  // считаем число изменении сигнала
            cnt_bounch <= cnt_bounch + 1'd1;

    //------------------------------------------------------------------------

    // сигнал сброса таймера
    wire reset_tmr; // по rst, или по нажатию кнопки, или когда счётчик днажатий кнопки пуст
    assign reset_tmr = (rst || (cnt_bounch == '0));
    // таймер
    timer #( .CLKMHZ(clk_mhz) ) tmr (
        .clk(clk),
        .rst(reset_tmr),
        .start(q_bounch),
        .out_500ms_i(n_500ms_i)
    );

    //------------------------------------------------------------------------

    // поморгаем светодиодом
    led_driver #( .CLKMHZ(clk_mhz) ) i_led_drv (
        .clk(clk),
        .rst(rst),
        .start(n_500ms_i),
        .out(led[0])
    );

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
        .clk      (clk),
        .rst      (rst),
        .number   (w_display_number'(cnt_bcd) ),
        .dots     (w_digit' (0)),
        .abcdefgh (abcdefgh),
        .digit    (digit)
    );

    //------------------------------------------------------------------------

endmodule
