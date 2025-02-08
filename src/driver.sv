module driver #(
    w_digit = 8,
    w_led   = 8,
    w_key   = 8
) (
    input  logic               clk,
    input  logic               rst,
    input  logic [w_key-1:0]   key,
    output logic [w_led-1:0]   led,
    output logic [w_digit-1:0] digit,
    output logic [7:0]         abcdefgh
);

typedef enum bit [7:0] {
    F     = 8'b1000_1110,
    P     = 8'b1100_1110,
    G     = 8'b1011_1100,
    A     = 8'b1110_1110,
    space = 8'b0000_0000
} seven_seg_encoding_e;

seven_seg_encoding_e letter;

logic [w_digit-1:0] shift_reg;

logic [31:0] cnt;

logic button_on;
assign button_on = | key;

logic enable;
assign enable = (cnt[22:0] == '0);

always_ff @ (posedge clk or posedge rst)
    if (rst)
        cnt <= '0;
    else
        cnt <= cnt + 1'd1;

always_ff @ (posedge clk or posedge rst)
    if (rst)
      shift_reg <= w_digit'(1);
    else if (enable)
      shift_reg <= {shift_reg[0], shift_reg[w_digit-1:1]};

always_comb
    case (4' (shift_reg))
        4'b1000: letter = F;
        4'b0100: letter = P;
        4'b0010: letter = G;
        4'b0001: letter = A;
        default: letter = space;
    endcase

assign abcdefgh = letter;
assign digit    = shift_reg;
assign led      = w_led' (shift_reg);

endmodule
