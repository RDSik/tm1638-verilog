`include "swap_bits.svh"

module top #(
    parameter clk_mhz = 27
) (
    input        clk,
    input        rst,
    output       sio_clk,
    output logic sio_stb,
    inout        sio_data
);

localparam w_tm_key   = 8,
           w_tm_led   = 8,
           w_tm_digit = 8;

wire [w_tm_digit - 1:0] tm_digit;
wire [w_tm_key   - 1:0] tm_key;
wire [w_tm_led   - 1:0] tm_led;

wire [7:0] abcdefgh;

wire [$left (abcdefgh):0] hgfedcba;
`SWAP_BITS (hgfedcba, abcdefgh);

tm1638_board_controller
# (
    .clk_mhz   ( clk_mhz     ),
    .w_digit   ( w_tm_digit  )
)
i_tm1638
(
    .clk       ( clk         ),
    .rst       ( rst         ),
    .hgfedcba  ( hgfedcba    ),
    .digit     ( tm_digit    ),
    .ledr      ( tm_led      ),
    .keys      ( tm_key      ),
    .sio_clk   ( sio_clk     ),
    .sio_stb   ( sio_stb     ),
    .sio_data  ( sio_data    )
);

assign abcdefgh = '0;
assign tm_digit = '0;

logic [31:0] cnt;

always_ff @ (posedge clk or posedge rst)
    if (rst)
        cnt <= '0;
    else
        cnt <= cnt + 1'd1;

wire enable = (cnt [22:0] == '0);

wire button_on = | tm_key;

logic [w_tm_led - 1:0] shift_reg;

always_ff @ (posedge clk or posedge rst)
    if (rst)
        shift_reg <= '1;
    else if (enable)
        shift_reg <= { button_on, shift_reg [w_tm_led - 1:1] };

assign tm_led = shift_reg;

endmodule
