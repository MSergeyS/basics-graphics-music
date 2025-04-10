module binary_coded_decimal
    #(parameter integer BWIDTH = 14, //must avoid overflow
      parameter integer DWIDTH  = 16 //must be multiple of 4
     )
    (
    input        clk,
    input        res_n,
    input        [BWIDTH-1:0] bin_in,
    output logic [DWIDTH-1:0] dec_out
    );

logic [BWIDTH-1:0] bin;
logic [DWIDTH-1:0] bcd;
logic [3:0] i; //correct if BWIDTH>16

//----------------------------------------------------------------------------
// реализован в виде конечного автомата
//----------------------------------------------------------------------------
// States
typedef enum logic [1:0] {
    st_start = 2'b00, //
    st_shift = 2'b01, //
    st_add   = 2'b10, //
    st_done  = 2'b11  //
} statetype_t;
statetype_t state, next_state;

//----------------------------------------------------------------------------
// Next state

always_comb begin
    next_state = state;

    case (state)
        st_start : next_state = st_shift;
        st_shift : if (i == (BWIDTH-1)) next_state = st_done;
                   else next_state = st_add;
        st_add   : next_state = st_shift;
        st_done  : next_state = st_start;
        default  : next_state = st_start;
    endcase
end

// Output logic -------------------------------------------------------------

always_ff @(posedge clk) begin
    if (~res_n) begin
        dec_out <= 'd0;
    end
    else begin
        case (state)
            st_start: begin
                bin <= bin_in;
                bcd <= 'd0;
                i <= 4'd0;
            end
            st_shift: begin
                bin <= {bin [BWIDTH-2:0], 1'd0};
                bcd <= {bcd [DWIDTH-2:0], bin[BWIDTH-1]};
                i <= i + 4'd1;
            end
            st_add: begin
                //comment or uncomment if needed
                //ones
                if (bcd[3:0] > 'd4)  bcd[3:0] <= bcd[3:0] + 4'd3;
                //decs
                if (bcd[ 7:4] > 'd4) bcd[7:4] <= bcd[7:4] + 4'd3;
                //hundreds
                if (bcd[11:8] > 'd4) bcd[11:8] <= bcd[11:8] + 4'd3;
                //thousands
                if (bcd[DWIDTH-1:12] > 'd4) bcd[DWIDTH-1:12] <= bcd[DWIDTH-1:12] + 4'd3;
            end
            st_done: begin
                dec_out <= bcd;
            end
        endcase
    end
end

//----------------------------------------------------------------------------
// Assigning next state

always_ff @(posedge clk)
    if (~res_n) state <= st_start;
    else        state <= next_state;

endmodule
