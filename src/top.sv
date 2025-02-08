`include "swap_bits.svh"

module top #(
    parameter clk_mhz = 27
) (
    input  logic clk,
    input  logic key,
    output logic sio_clk,
    output logic sio_stb,
    inout        sio_data
);

localparam w_tm_key   = 8,
           w_tm_led   = 8,
           w_tm_digit = 8;

logic [w_tm_digit-1:0] tm_digit;
logic [w_tm_key-1:0]   tm_key;
logic [w_tm_led-1:0]   tm_led;

logic [7:0] abcdefgh;
logic       rst;

assign rst = ~key;

logic [$left (abcdefgh):0] hgfedcba;
`SWAP_BITS (hgfedcba, abcdefgh);

tm1638_board_controller #(
    .clk_mhz   (clk_mhz   ),
    .w_digit   (w_tm_digit)
) i_tm1638 (
    .clk       (clk     ),
    .rst       (rst     ),
    .hgfedcba  (hgfedcba),
    .digit     (tm_digit),
    .ledr      (tm_led  ),
    .keys      (tm_key  ),
    .sio_clk   (sio_clk ),
    .sio_stb   (sio_stb ),
    .sio_data  (sio_data)
);

driver #(
    .w_digit (w_tm_digit),
    .w_led   (w_tm_led  ),
    .w_key   (w_tm_key  )
) i_driver (
    .clk      (clk     ),
    .rst      (rst     ),
    .key      (tm_key  ),
    .digit    (tm_digit),
    .led      (tm_led  ),
    .abcdefgh (abcdefgh)
);

endmodule
