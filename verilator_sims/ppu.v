`timescale 1ns / 1ps

module ppu(
	input wire clk,
	input wire rst,
	
	input wire sync,
	
	input wire [2:0] mode,

	input wire [7:0] data_i,
	input wire stb_i,
	output reg ack_i,
	
	output reg [7:0] data_o,
	output reg stb_o,
	input wire ack_o
);

parameter buffer_num = 32;
parameter buffer_index_bits = 4;
parameter buffer_index_bits_both = (buffer_index_bits + 1) * 2 - 1;
parameter buffer_size = buffer_num * 8 - 1;

reg [(buffer_num * 8) - 1:0] ring_line;
reg [buffer_index_bits:0] ring_index;

reg output_available;

parameter LINE = 799;
parameter SCREEN = 524;
reg [9:0] sx;
reg [9:0] sy;
reg frame_alternate;

// calculate horizontal and vertical screen position
always @(posedge clk or negedge rst) begin
	if ( (rst==1'b0) || (sync==1) ) begin
		sx <= 0;
		sy <= 0;
		frame_alternate <= 0;
	end else begin
		if (sx == LINE) begin  // last pixel on line?
			sx <= 0;
			if (sy == SCREEN) begin  // last pixel on line?
				sy <= 0;
				frame_alternate <= ~frame_alternate;
			end else begin
				sy <= sy + 1;
			end
		end else begin
			sx <= sx + 1;
		end
	end
end

reg [7:0] frame_counter;
reg [9:0] pattern_counter; // pattern shift counter
always @(posedge frame_alternate or negedge rst) begin
	if (!rst) begin
		frame_counter <= 0;
	end else begin
		if (frame_alternate) begin
			frame_counter <= frame_counter + 1;
			if (frame_counter == 1) begin
				frame_counter <= 0;
				// now we can update the pattern_counter, thus the pattern moves
				pattern_counter <= pattern_counter + 1;
			end
		end
	end	
end


//input handshake, read in
always @(posedge clk or negedge rst) begin
	if (!rst) begin
		ring_line[255:0] <= {256{1'b0}};
		ring_index <= 0;
		ack_i <= 1'b0;
	end else if(stb_i == 1) begin
		ring_index <= ring_index + 1;
		ring_line <= {ring_line[buffer_size - 8 : 0], data_i};
		ack_i <= 1'b1;
		// $display("ring_line[7:0]: %d\n", ring_line[7:0]);
	end else begin
		ack_i <= 1'b0;
	end	
end

logic [9:0] random_pattern;
logic [9:0] pixel_pattern_r;
logic [9:0] pixel_pattern_g;
logic [9:0] pixel_pattern_b;
//output handshake
always @(posedge clk) begin
	
	if (!rst) begin
		data_o <= 0;
		stb_o <= 0;
		output_available <= 1;
	end 
	
	if (ack_o==1) begin
	
		stb_o <= 0;
		output_available <= 1'b1;
	end 
	
	if (output_available) begin
		//processing goes here
		
		//create output data
		case (mode)
			3'd0: begin
				data_o <= data_i; // ppu passthrough the input data
			end
			3'd1: begin
				// same pattern as the one we show case in the hackthon
				if (((((sy+pattern_counter) ^ (sx+pattern_counter))%7) | (((sy+pattern_counter) ^ (sx+pattern_counter))%9))>1)  begin
					data_o[7:6] <= 2'b00;
					data_o[5:4] <= 2'b11;
				end else begin
					data_o[7:6] <= 2'b11;
					data_o[5:4] <= 2'b00;
				end

				if (((((sy+pattern_counter+1) ^ (sx+pattern_counter+1))%7) | (((sy+pattern_counter+1) ^ (sx+pattern_counter+1))%9))>1)  begin
					data_o[3:2] <= 2'b00;
				end else begin
					data_o[3:2] <= 2'b11;
				end 
				
			end
			3'd2: begin
				// vertical color stripes
				data_o [7:6] <= {2{sx[5]}};
				data_o [5:4] <= {2{sx[6]}};
				data_o [3:2] <= {2{sx[7]}};
				data_o [1] <= 0;

			end
			3'd3: begin
				random_pattern <= ring_line[9:0];
				pixel_pattern_r <=  (((((sx>>1)+pattern_counter) ^ ((sy>>1)+pattern_counter)) %7) | ((((sx>>1)+pattern_counter) ^ ((sy>>1)+pattern_counter)) %11)) ^ random_pattern;
				pixel_pattern_g <=  (((((sx>>1)+pattern_counter) ^ ((sy>>1)+pattern_counter)) %7) | ((((sx>>1)+pattern_counter) ^ ((sy>>1)+pattern_counter)) %11)) ^ (random_pattern>>2);
				pixel_pattern_b <=  (((((sx>>1)+pattern_counter+3) ^ ((sy>>1)+pattern_counter+3)) %7) | ((((sx>>1)+pattern_counter+3) ^ ((sy>>1)+pattern_counter+3)) %11))  ^ (random_pattern>>4);

				data_o [7:6] <= {2{pixel_pattern_r[0]}};
				data_o [5:4] <= {2{pixel_pattern_g[0]}};
				data_o [3:2] <= {2{pixel_pattern_b[0]}};
				data_o [1:0] <= 0;

			end
			3'd4: begin
				data_o [7] <= (((sy>>2) + pattern_counter) ^ (sx>>2) ) % 7 < 1; 
				data_o [6] <= (((sy>>2) + pattern_counter) ^ (sx>>2)) % 7 < 1; 
				data_o [5] <= (((sy) + pattern_counter + pattern_counter) ^ (sx)) % 7 < 1;
				data_o [4] <= (((sy) + pattern_counter + pattern_counter) ^ (sx)) % 7 < 1;
				data_o [3] <= ((sy>>2) ^ (sx>>2)) % 7 < 1;
				data_o [2] <= ((sy>>2) ^ (sx>>2)) % 7 < 1;
				data_o [1:0] <= 0;
				
			end	
			3'd5: begin

				data_o[7:6] <= (((sy >> 3) + (pattern_counter >> 2)) ^ (sx >> 3)) % 9 < 1 ? 2'b11 : 2'b00; // Red
				data_o[5:4] <= (((sy >> 3) + (pattern_counter >> 2)) ^ (sx >> 3)) % 9 < 1 ? 2'b10 : 2'b00; // Green
				data_o[3:2] <= (((sy >> 3) + (pattern_counter >> 2)) ^ (sx >> 3)) % 9 < 1 ? 2'b01 : 2'b00; // Blue
				data_o[1:0] <= 2'b00; 

				// Adding shadow
				if ((((sy >> 3) + (pattern_counter >> 2) + 1) ^ (sx >> 3)) % 9 < 1) begin
					data_o[7:6] <= 2'b01; // Darker Red
					data_o[5:4] <= 2'b01; // Darker Green
					data_o[3:2] <= 2'b01; // Darker Blue
				end
			end
			3'd6: begin
				// empty
			end
			3'd7: begin
				// empty
			end
			

		endcase
		
		//strobe to confirm processing
		stb_o <= 1;
		output_available <= 1'b0;
	end
end

endmodule