`include "swap_bits.svh"

module top #(
    parameter clk_mhz = 27
) (
    input        clk,
    input        key,
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
wire       rst;

assign rst = ~key;

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

logic [31:0] cnt;

always_ff @ (posedge clk or posedge rst)
    if (rst)
        cnt <= '0;
    else
        cnt <= cnt + 1'd1;

wire enable = (cnt [22:0] == '0);

wire button_on = | tm_key;

logic [w_tm_digit - 1:0] shift_reg;

always_ff @ (posedge clk or posedge rst)
    if (rst)
      shift_reg <= w_tm_digit' (1);
    else if (enable)
      shift_reg <= { shift_reg [0], shift_reg [w_tm_digit - 1:1] };

assign tm_led = w_tm_led' (shift_reg);

typedef enum bit [7:0]
    {
        F     = 8'b1000_1110,
        P     = 8'b1100_1110,
        G     = 8'b1011_1100,
        A     = 8'b1110_1110,
        space = 8'b0000_0000
    }
    seven_seg_encoding_e;

seven_seg_encoding_e letter;

always_comb
    case (4' (shift_reg))
    4'b1000: letter = F;
    4'b0100: letter = P;
    4'b0010: letter = G;
    4'b0001: letter = A;
    default: letter = space;
    endcase

assign abcdefgh = letter;
assign tm_digit = shift_reg;

endmodule
