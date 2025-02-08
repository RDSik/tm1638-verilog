module driver #(
    parameter clk_mhz = 27,
    parameter w_digit = 8,
    parameter w_led   = 8,
    parameter w_key   = 8
) (
    input  logic               clk,
    input  logic               rst,
    output logic [w_digit-1:0] digit,
    input  logic [w_key-1:0]   key,
    output logic [w_led-1:0]   led,
    output logic [7:0]         abcdefgh
);

localparam min_period = clk_mhz * 1000 * 1000 / 50,
           max_period = clk_mhz * 1000 * 1000 *  3;

logic [31:0] period;
logic [31:0] cnt_1;
logic [31:0] cnt_2;

always_ff @ (posedge clk or posedge rst)
    if (rst)
        period <= 32' ((min_period + max_period) / 2);
    else if (key [0] & period != max_period)
        period <= period + 32'h1;
    else if (key [1] & period != min_period)
        period <= period - 32'h1;

always_ff @ (posedge clk or posedge rst)
    if (rst)
        cnt_1 <= '0;
    else if (cnt_1 == '0)
        cnt_1 <= period - 1'b1;
    else
        cnt_1 <= cnt_1 - 1'd1;

always_ff @ (posedge clk or posedge rst)
    if (rst)
        cnt_2 <= '0;
    else if (cnt_1 == '0)
        cnt_2 <= cnt_2 + 1'd1;

assign led = cnt_2;

// 4 bits per hexadecimal digit
localparam w_display_number = w_digit * 4;

seven_segment_display #(
    .w_digit (w_digit),
    .clk_mhz (clk_mhz)
) i_7segment (
    .clk      (clk                     ),
    .rst      (rst                     ),
    .number   (w_display_number'(cnt_2)),
    .dots     (w_digit'(0)             ),
    .abcdefgh (abcdefgh                ),
    .digit    (digit                   )
);

endmodule
