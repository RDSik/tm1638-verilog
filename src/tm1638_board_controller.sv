/*============================================================================
LED&KEY TM1638 board controller
SPDX-License-Identifier: Apache-2.0

Copyright 2023 Alexander Kirichenko
Copyright 2023 Ruslan Zalata (HCW-132 variation support)

Based on https://github.com/alangarf/tm1638-verilog
Copyright 2017 Alan Garfield
Copyright Contributors to the basics-graphics-music project.
==============================================================================*/

///////////////////////////////////////////////////////////////////////////////////
//                              Top module
///////////////////////////////////////////////////////////////////////////////////

module tm1638_board_controller
# (
    parameter clk_mhz = 50,
              w_digit = 8,
              w_seg   = 8
)
(
    input                         clk,
    input                         rst,
    input        [           7:0] hgfedcba,
    input        [ w_digit - 1:0] digit,
    input        [           7:0] ledr,
    output logic [           7:0] keys,
    output                        sio_clk,
    output logic                  sio_stb,
    // input                         sio_data_in,
    // output                        sio_data_out,
    // output                        sio_data_out_en
    inout                         sio_data
);

    localparam
        HIGH    = 1'b1,
        LOW     = 1'b0;

    localparam [7:0]
        C_READ_KEYS   = 8'b01000010,
        C_WRITE_DISP  = 8'b01000000,
        C_SET_ADDR_0  = 8'b11000000,
        C_DISPLAY_ON  = 8'b10001111;

    localparam CLK_DIV = 19; // speed of FSM scanner

    logic  [CLK_DIV:0] counter;

    localparam [CLK_DIV:0] COUNTER_0 = '0;

    // TM1632 requires at least 1us strobe duration
    // we can generate this by adding delay at the end of
    // each transfer. For that we define a flag indicating
    // completion of 1us delay loop.
    wire               stb_delay_complete = (counter > clk_mhz ? 1 : 0);

    logic  [5:0] instruction_step;
    logic  [7:0] led_on;

    logic        tm_rw;
    wire         dio_in, dio_out;

    // setup tm1638 module with it's tristate IO
    //   tm_in      is written to module
    //   tm_out     is read from module
    //   tm_latch   triggers the module to read/write display
    //   tm_rw      selects read or write mode to display
    //   busy       indicates when module is busy
    //                (another latch will interrupt)
    //   tm_clk     is the data clk
    //   dio_in     for reading from display
    //   dio_out    for sending to display
    //
    logic        tm_latch;
    wire         busy;
    logic  [7:0] tm_in;
    wire   [7:0] tm_out;

    ///////////// RESET synhronizer ////////////
    logic             reset_syn1;
    logic             reset_syn2 = 0;
    always @(posedge clk) begin
        reset_syn1 <= rst;
        reset_syn2 <= reset_syn1;
    end

    ////////////// TM1563 dio //////////////////

    // assign dio_in          = sio_data_in;
    // assign sio_data_out    = dio_out;
    // assign sio_data_out_en = tm_rw;
    assign sio_data = tm_rw ? dio_out : 'z;
    assign dio_in   = sio_data;

    tm1638_sio
    # (
        .clk_mhz ( clk_mhz )
    )
    tm1638_sio
    (
        .clk        ( clk        ),
        .rst        ( reset_syn2 ),

        .data_latch ( tm_latch   ),
        .data_in    ( tm_in      ),
        .data_out   ( tm_out     ),
        .rw         ( tm_rw      ),

        .busy       ( busy       ),

        .sclk       ( sio_clk    ),
        .dio_in     ( dio_in     ),
        .dio_out    ( dio_out    )
    );

    ////////////// TM1563 data /////////////////
    wire [w_digit -1:0][w_seg - 1:0] hex;

    tm1638_registers
    # (
        .w_digit  ( w_digit ),
        .w_seg    ( w_seg   )
    )
    i_tm1638_regs
    (
        .clk      ( clk      ),
        .rst      ( rst      ),
        .hgfedcba ( hgfedcba ),
        .digit    ( digit    ),
        .hex      ( hex      )
    );

    // handles displaying 1-8 on a hex display
    task display_digit
    (
        input [7:0] segs
    );

        tm_latch <= HIGH;
        tm_in    <= segs;

    endtask

    // handles the LEDs 1-8
    task display_led
    (
        input [2:0] led
    );
        tm_latch <= HIGH;
        tm_in <= {7'b0, led_on[led]};

    endtask

    // controller FSM

    always @(posedge clk or posedge reset_syn2)
    begin
        if (reset_syn2) begin
            instruction_step <= 'b0;
            sio_stb          <= HIGH;
            tm_rw            <= HIGH;

            counter          <= 'd0;
            keys             <= 'b0;
            led_on           <= 'b0;

        end else begin

            counter <= counter + 1;

            if (counter[0] && ~busy) begin

                instruction_step <= instruction_step + 1;

                case (instruction_step)
                    // *** KEYS ***
                    1:  {sio_stb, tm_rw}   <= {LOW, HIGH};
                    2:  {tm_latch, tm_in}  <= {HIGH, C_READ_KEYS}; // read mode
                    3:  {tm_latch, tm_rw}  <= {HIGH, LOW};

                    //  read back keys S1 - S8
                    4:  {keys[7], keys[3]} <= {tm_out[0], tm_out[4]};
                    5:  tm_latch           <= HIGH;
                    6:  {keys[6], keys[2]} <= {tm_out[0], tm_out[4]};
                    7:  tm_latch           <= HIGH;
                    8:  {keys[5], keys[1]} <= {tm_out[0], tm_out[4]};
                    9:  tm_latch           <= HIGH;
                    10: {keys[4], keys[0]} <= {tm_out[0], tm_out[4]};
                    11: {counter, sio_stb} <= {COUNTER_0, HIGH}; // initiate 1us delay
                    12: {instruction_step} <= (stb_delay_complete ? 6'd13 : 6'd12); // loop till delay complete

                    // *** DISPLAY ***
                    13: {sio_stb, tm_rw}   <= {LOW, HIGH};
                    14: {tm_latch, tm_in}  <= {HIGH, C_WRITE_DISP}; // write mode
                    15: {counter, sio_stb} <= {COUNTER_0, HIGH}; // initiate 1us delay
                    16: {instruction_step} <= (stb_delay_complete ? 6'd17 : 6'd16); // loop till delay complete

                    17: {sio_stb, tm_rw}   <= {LOW, HIGH};
                    18: {tm_latch, tm_in}  <= {HIGH, C_SET_ADDR_0}; // set addr 0 pos

                    19: display_digit(hex[7]); // Digit 1
                    20: display_led(3'd7);        // LED 8

                    21: display_digit(hex[6]); // Digit 2
                    22: display_led(3'd6);        // LED 7

                    23: display_digit(hex[5]); // Digit 3
                    24: display_led(3'd5);        // LED 6

                    25: display_digit(hex[4]); // Digit 4
                    26: display_led(3'd4);        // LED 5

                    27: display_digit(hex[3]); // Digit 5
                    28: display_led(3'd3);        // LED 4

                    29: display_digit(hex[2]); // Digit 6
                    30: display_led(3'd2);        // LED 3

                    31: display_digit(hex[1]); // Digit 7
                    32: display_led(3'd1);        // LED 2

                    33: display_digit(hex[0]); // Digit 8
                    34: display_led(3'd0);        // LED 1

                    35: {counter, sio_stb} <= {COUNTER_0, HIGH}; // initiate 1us delay
                    36: {instruction_step} <= (stb_delay_complete ? 6'd37 : 6'd36); // loop till delay complete

                    37: {sio_stb, tm_rw}   <= {LOW, HIGH};
                    38: {tm_latch, tm_in}  <= {HIGH, C_DISPLAY_ON}; // display on, full bright

                    39: {counter, sio_stb} <= {COUNTER_0, HIGH}; // initiate 1us delay
                    40: {instruction_step} <= (stb_delay_complete ? 6'd0 : 6'd40); // loop till delay complete

                endcase

                led_on           <= ledr;

            end else if (busy) begin
                // pull latch low next clock cycle after module has been
                // latched
                tm_latch <= LOW;
            end
        end
    end

endmodule
