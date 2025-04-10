// модуль таймера
// используется для инкрементирования счётчика кол-во срабатываний кнопки

module led_driver
# (
    parameter integer  CLKMHZ = 50 // частота clk [МГц]
)
(
    // сигналы глобальной синхронизации сброса
    input  clk,    // тактовая частота CLKMHZ [МГц] <=125 [МГц]
    input  rst,    // асинхронный сигнал начального сброса (АУ=1)

    // сигналы управления
    input  start,
	input  rst_key,

    // выходные сигналы
    output out
);

    //------------------------------------------------------------------------

    // задерживаем импульс start на 100 ms
    logic [31:0] cnt_100ms;
    wire cnt_is_zero;
    wire n_100ms_i;
    reg q_100ms;
    reg q_100ms_d;

    assign cnt_is_zero = (cnt_100ms == '0); // счётчик = 0
    always_ff @ (posedge clk or posedge rst)
        if (rst)
            q_100ms <= '1; // по rst cnt_100ms == 0
        else if (rst_key)
            q_100ms <= '1; // по rst cnt_100ms == 0
        else
            q_100ms <= cnt_is_zero; // задержали на 1 такт clk
    // формируем импульс
    assign n_100ms_i = cnt_is_zero & ~q_100ms;

    always_ff @ (posedge clk or posedge rst)
        if (rst)  // сброс по rst
            cnt_100ms <= '0;
        else if (rst_key) // сброс по нажатию кнопки
            cnt_100ms <= '0;
        else if (start) // взводим таймер на 100 мс
            cnt_100ms <= (CLKMHZ*100*1000) -  1'd1;
        else if (~cnt_is_zero) // уменьшаем на 1 пока не будет = 0
            cnt_100ms <= cnt_100ms - 1'd1;

    //------------------------------------------------------------------------

    // T-тригер
    reg q_led;
    always_ff @ (posedge clk or posedge rst)
        if (rst) // сброс по rst
            q_led <= 1'b0;
        else if (rst_key) // сброс по нажатию кнопки
            q_led <= 1'b0;
        else if (start || n_100ms_i)
            // инвертируем значение q_led каждый импульс start
            q_led <= ~q_led;

    assign out = q_led;

endmodule
