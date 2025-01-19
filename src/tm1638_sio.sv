/*============================================================================
SPDX-License-Identifier: Apache-2.0

Copyright 2023 Alexander Kirichenko
Copyright 2023 Ruslan Zalata (HCW-132 variation support)

Based on https://github.com/alangarf/tm1638-verilog
Copyright 2017 Alan Garfield
Copyright Contributors to the basics-graphics-music project.
==============================================================================*/

///////////////////////////////////////////////////////////////////////////////////
//           TM1638 SIO driver for tm1638_board_controller top module
///////////////////////////////////////////////////////////////////////////////////
module tm1638_sio
# (
    parameter clk_mhz = 27
)
(
    input          clk,
    input          rst,

    input          data_latch,
    input  [7:0]   data_in,
    output [7:0]   data_out,
    input          rw,

    output         busy,

    output         sclk,
    input          dio_in,
    output logic   dio_out
);

    localparam CLK_DIV1 = $clog2 (clk_mhz*1000/2/700) - 1; // 700 kHz is recommended SIO clock
    localparam [1:0]
        S_IDLE      = 2'h0,
        S_WAIT      = 2'h1,
        S_TRANSFER  = 2'h2;

    logic [       1:0] cur_state, next_state;
    logic [CLK_DIV1:0] sclk_d, sclk_q;
    logic [       7:0] data_d, data_q, data_out_d, data_out_q;
    logic              dio_out_d;
    logic [       2:0] ctr_d, ctr_q;

    // output read data
    assign data_out = data_out_q;

    // we're busy if we're not idle
    assign busy = cur_state != S_IDLE;

    // tick the clock if we're transfering data
    assign sclk = ~((~sclk_q[CLK_DIV1]) & (cur_state == S_TRANSFER));

    always_comb
    begin
        sclk_d = sclk_q;
        data_d = data_q;
        dio_out_d = dio_out;
        ctr_d = ctr_q;
        data_out_d = data_out_q;
        next_state = cur_state;

        case(cur_state)
            S_IDLE: begin
                sclk_d = 0;
                if (data_latch) begin
                    // if we're reading, set to zero, otherwise latch in
                    // data to send
                    data_d = data_in;
                    next_state = S_WAIT;
                end
            end

            S_WAIT: begin
                sclk_d = sclk_q + 1'd1;
                // wait till we're halfway into clock pulse
                if (sclk_q == {1'b0, {CLK_DIV1{1'b1}}}) begin
                    sclk_d = 0;
                    next_state = S_TRANSFER;
                end
            end

            S_TRANSFER: begin
                sclk_d = sclk_q + 1'd1;
                if (sclk_q == 0) begin
                    // start of clock pulse, output MSB
                    dio_out_d = data_q[0];

                end else if (sclk_q == {1'b0, {CLK_DIV1{1'b1}}}) begin
                    // halfway through pulse, read from device
                    data_d = {dio_in, data_q[7:1]};

                end else if (&sclk_q) begin
                    // end of pulse, tick the counter
                    ctr_d = ctr_q + 1'd1;

                    if (&ctr_q) begin
                        // last bit sent, switch back to idle
                        // and output any data recieved
                        next_state = S_IDLE;
                        data_out_d = data_q;

                        dio_out_d = '0;
                    end
                end
            end

            default:
                next_state = S_IDLE;
        endcase
    end

    always @(posedge clk)
    begin
        if (rst)
        begin
            cur_state <= S_IDLE;
            sclk_q <= 0;
            ctr_q <= 0;
            dio_out <= 0;
            data_q <= 0;
            data_out_q <= 0;
        end
        else
        begin
            cur_state <= next_state;
            sclk_q <= sclk_d;
            ctr_q <= ctr_d;
            dio_out <= dio_out_d;
            data_q <= data_d;
            data_out_q <= data_out_d;
        end
    end
endmodule
