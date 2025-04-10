`include "config.svh"

module timer
# (
    parameter integer  CLKMHZ = 50 // частота clk [МГц]
)
(
    // сигналы глобальной синхронизации сброса
    input  clk,    // тактовая частота CLKMHZ [МГц] <=125 [МГц]
    input  rst,    // асинхронный сигнал начального сброса (АУ=1)

    // сигналы управления
    input  start,

    // выходные сигналы
    output out_500ms_i
);

    //------------------------------------------------------------------------

    reg work; // работа таймера
    always_ff @ (posedge clk or posedge rst)
    if (rst) // сброс
        work <= '0;
    else if (start)
        work <= 1'b1;

    // 1 ms
    logic [31:0] cnt_1ms;
    wire n_1ms_i;
    assign n_1ms_i = (cnt_1ms == '0);
    always_ff @ (posedge clk or posedge rst)
        if (rst)
            cnt_1ms <= '0;
        else if (n_1ms_i)
            cnt_1ms <= (CLKMHZ*1000) - 1'b1;
        else
            cnt_1ms <= cnt_1ms - 1'd1;

    // 500 ms
    logic [31:0] cnt_500ms;
    wire n_500ms_i;
    assign n_500ms_i = (cnt_500ms == '0);
    always_ff @ (posedge clk or posedge rst)
        if (rst)
            cnt_500ms <= '0;
        else if (n_500ms_i | start)
            cnt_500ms <= 500 - 1'b1;
        else if (work & n_1ms_i)
            cnt_500ms <= cnt_500ms - 1'd1;

    // 5 s
    logic [31:0] cnt_5000ms;
    wire n_5000ms_i;
    assign n_5000ms_i = (cnt_5000ms == '0);
    always_ff @ (posedge clk or posedge rst)
        if (rst)
            cnt_5000ms <= 10 - 1'b1;
        else if (start)
            cnt_5000ms <= 10 - 1'b1;
        else if ( ~n_5000ms_i & work & n_500ms_i)
            cnt_5000ms <= cnt_5000ms - 1'd1;

    assign out_500ms_i = n_5000ms_i & n_500ms_i;

endmodule
