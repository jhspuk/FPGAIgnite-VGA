`timescale 1ns / 1ps

module vga_driver (
    input  wire clk_pix,   // pixel clock
    input  wire rst_pix,   // reset in pixel clock domain
    input  wire [7:0] wb_data, // write data
    output reg  [1:0] vga_r,  // red
    output reg  [1:0] vga_g,  // green
    output reg  [1:0] vga_b,  // blue
    output reg  [9:0] sx,  // horizontal screen position
    output reg  [9:0] sy,  // vertical screen position
    output reg  hsync,     // horizontal sync
    output reg  vsync,     // vertical sync
    output reg  de         // data enable (low in blanking interval)
    );

    // horizontal timings
    parameter HA_END = 639;           // end of active pixels
    parameter HS_STA = HA_END + 16;   // sync starts after front porch
    parameter HS_END = HS_STA + 96;   // sync ends
    parameter LINE   = 799;           // last pixel on line (after back porch)

    // vertical timings
    parameter VA_END = 479;           // end of active pixels
    parameter VS_STA = VA_END + 10;   // sync starts after front porch
    parameter VS_END = VS_STA + 2;    // sync ends
    parameter SCREEN = 524;           // last line on screen (after back porch)

    always @(*) begin
        hsync = ~(sx >= HS_STA && sx < HS_END);  // invert: negative polarity
        vsync = ~(sy >= VS_STA && sy < VS_END);  // invert: negative polarity
        de = (sx <= HA_END && sy <= VA_END);
    end

    // calculate horizontal and vertical screen position
    always @(posedge clk_pix or negedge rst_pix) begin
        if (!rst_pix) begin
            sx <= 0;
            sy <= 0;
            vga_r <= 0;
            vga_g <= 0;
            vga_b <= 0;
        end else begin
            if (wb_data[1:0] == 2'b11) begin
                sx <= 0;
                sy <= 0;
            end else begin
              if (sx == LINE) begin  // last pixel on line?
                  sx <= 0;
                  sy <= (sy == SCREEN) ? 0 : sy + 1;  // last line on screen?
              end else begin
                  sx <= sx + 1;
              end
            end
            vga_r <= wb_data[7:6];
            vga_g <= wb_data[5:4];
            vga_b <= wb_data[3:2];
        end
    end
endmodule
