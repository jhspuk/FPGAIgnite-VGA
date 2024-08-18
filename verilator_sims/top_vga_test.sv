// Project F: FPGA Graphics - Square (Verilator SDL)
// (C)2023 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io/posts/fpga-graphics/

`default_nettype none
`timescale 1ns / 1ps

module top_vga_test #(parameter CORDW=10) (  // coordinate width
    input  wire logic clk_pix,             // pixel clock
    input  wire logic sim_rst,             // sim reset
    output      logic [CORDW-1:0] sdl_sx,  // horizontal SDL position
    output      logic [CORDW-1:0] sdl_sy,  // vertical SDL position
    output      logic sdl_de,              // data enable (low in blanking interval)
    output      logic [7:0] sdl_r,         // 8-bit red
    output      logic [7:0] sdl_g,         // 8-bit green
    output      logic [7:0] sdl_b          // 8-bit blue
    );

    // Declare an array of 10 elements, each 8 bits wide
    logic [7:0] test_data [0:9];
    initial begin
        // Initialize the array with the given values
        test_data[0] = 8'd42;
        test_data[1] = 8'd123;
        test_data[2] = 8'd87;
        test_data[3] = 8'd255;
        test_data[4] = 8'd0;
        test_data[5] = 8'd198;
        test_data[6] = 8'd76;
        test_data[7] = 8'd34;
        test_data[8] = 8'd210;
        test_data[9] = 8'd99;
    end

    // display sync signals and coordinates
    logic [CORDW-1:0] sx, sy;
    logic [1:0] vga_r;
    logic [1:0] vga_g;
    logic [1:0] vga_b;
    logic de;
    logic [7:0] wb_data;
    vga_driver vga_signal_generator (
        .clk_pix,
        .rst_pix(sim_rst),
        .wb_data(wb_data),
        .vga_r,
        .vga_g,
        .vga_b,
        .sx,
        .sy,
        /* verilator lint_off PINCONNECTEMPTY */
        .hsync(),
        .vsync(),
        /* verilator lint_on PINCONNECTEMPTY */
        .de
    );

    logic ppu_sync;
    logic [2:0] ppu_mode;
    logic [7:0] ppu_data_i;
    logic ppu_stb_i;
    logic ppu_ack_i;
    logic [7:0] ppu_data_o;
    logic ppu_stb_o;
    logic ppu_ack_o;

    ppu ppu (
        .clk(clk_pix),
        .rst(sim_rst),
        .sync(ppu_sync),
        .mode(ppu_mode),
        .data_i(ppu_data_i),
        .stb_i(ppu_stb_i),
	    .ack_i(ppu_ack_i),

        .data_o(ppu_data_o),
        .stb_o(ppu_stb_o),
	    .ack_o(ppu_ack_o)
    );

    // Define states
    typedef enum logic [2:0] {
        IDLE,
        SEND_DATA,
        RUN,
        DONE
    } state_t;

    state_t state;
    logic [3:0] ppu_counter;
    // State machine
    always_ff @(posedge clk_pix or posedge sim_rst) begin
        if (sim_rst) begin
            state = IDLE;
            ppu_counter <= 0;
            ppu_mode <= 3'(1); //4 is the mode has interesting pattern
            $display("reseting");
        end else begin
           
            if (state==IDLE) begin
                $display("idle");
                ppu_data_i = 8'b0;
                ppu_stb_i = 1'b0;
                state = SEND_DATA;
                ppu_sync <= 1;
            end else if (state == SEND_DATA) begin
                $display("sends data");
                ppu_data_i = test_data[ppu_counter];
                ppu_stb_i = 1'b1;

                if (ppu_ack_i == 1'b1) begin
                    if (ppu_counter == 9) begin
                        ppu_counter <= 0;
                        state = RUN;
                        ppu_sync <= 0;
                    end else begin
                        ppu_counter <= ppu_counter + 1;
                    end
                end

                $display("ppu_counter: %0d", ppu_counter);
            end else if (state==RUN) begin
                wb_data[7:2] = ppu_data_o[7:2];
                ppu_sync <= 0;
                ppu_ack_o = 1'b1;
                ppu_stb_i = 1'b0;
            end
        end
    end
    

    // define a square with screen coordinates
    // logic square;
    // logic [CORDW-1:0] square_x, square_y;
    // logic [32:0] counter;
    // always @(posedge clk_pix) begin
    //     if (sim_rst) begin
    //         square_x <= 100;
    //         square_y <= 100;
    //         counter <= 0;
    //     end
    //     counter <= (counter == 250000) ? 0 : counter + 1;
    //     if (counter == 0) begin
    //         square_x <= (square_x == 200) ? 100 : square_x + 1;
    //         square_y <= (square_y == 200) ? 100 : square_y + 1;
    //     end
    //     square = (sx > square_x && sx < square_x+200) && (sy > square_y && sy < square_y+200);
    // end

    // paint colour: white inside square, blue outside
    // logic [1:0] paint_r, paint_g, paint_b;
    // always_comb begin
    //     paint_r = (square) ? 2'b11 : 2'b01;
    //     paint_g = (square) ? 2'b11 : 2'b10;
    //     paint_b = (square) ? 2'b11 : 2'b10;
    //     // wb_data[7:2] = {paint_r, paint_g, paint_b};
    //     // wb_data[1:0] = 2'b00;
    // end

    // display colour: paint colour but black in blanking interval
    logic [3:0] display_r, display_g, display_b;
    always_comb begin
        display_r = (de) ? {{vga_r},{2'b00}} : 4'h0;
        display_g = (de) ? {{vga_g},{2'b00}} : 4'h0;
        display_b = (de) ? {{vga_b},{2'b00}} : 4'h0;
    end

    // SDL output (8 bits per colour channel)
    always_ff @(posedge clk_pix) begin
        sdl_sx <= sx;
        sdl_sy <= sy;
        sdl_de <= de;
        sdl_r <= {{display_r},{4'b0000}};  // double signal width from 4 to 8 bits
        sdl_g <= {{display_g},{4'b0000}};
        sdl_b <= {{display_b},{4'b0000}};
        // $display("sdl_r: %0d,%0d,%0d", sdl_r, sdl_g, sdl_b);
    end
endmodule
