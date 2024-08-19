`default_nettype none
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

reg [buffer_index_bits:0] h_count; 
reg [buffer_index_bits:0] v_count;

reg [10:0] counter;

reg [(buffer_num * 8) - 1:0] ring_line;
reg [buffer_index_bits:0] ring_index;

reg output_available;

parameter LINE = 799;
parameter SCREEN = 524;
reg [9:0] sx;
reg [9:0] sy;

// calculate horizontal and vertical screen position
always @(posedge clk or posedge rst) begin
	if ( (rst==1'b1) || (sync==1) ) begin
		sx <= 0;
		sy <= 0;
		h_count <= 0;
		v_count <= 0;
	end else begin
		if (sx == LINE) begin  // last pixel on line?
			sx <= 0;
			if (sy == SCREEN) begin  // last pixel on line?
				sy <= 0;
				h_count <= 0;
				v_count <= 0;
			end else begin
				sy <= sy + 1;
			end
		end else begin
			sx <= sx + 1;
		end

		if (output_available) begin
			if (v_count == 5'(buffer_num - 1)) begin
				if (h_count == 5'(buffer_num - 1)) begin
					h_count <= 0;
				end else begin
					h_count <= h_count + 1;
				end
				v_count <= 0;
			end else begin
				if (h_count == 5'(buffer_num - 1)) begin
					h_count <= 0;
				end else begin
					h_count <= h_count + 1;
				end
				v_count <= v_count + 1;
			end
		end
	end
end

reg [24:0] counter_div_cnt;
always @(posedge clk or posedge rst) begin
	if (rst) begin
		counter_div_cnt <= 0;
		counter <= 0;
	end else begin
		if (counter_div_cnt == 25000000) begin
			counter_div_cnt <= 0;
			counter <= counter + 1;
		end else begin
			counter_div_cnt <= counter_div_cnt + 1;
		end
	end	
end


//input handshake, read in
always @(posedge clk or posedge rst) begin
	if (rst) begin
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

//output handshake
always @(posedge clk) begin
	
	if (rst) begin
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
				data_o <= data_i;
			end
			3'd1: begin
				// same pattern as the one we show case in the hackthon
				if (((((sy+counter) ^ (sx+counter))%7) | (((sy+counter) ^ (sx+counter))%9))>1)  begin
					data_o[7:6] <= 2'b00;
					data_o[5:4] <= 2'b11;
				end else begin
					data_o[7:6] <= 2'b11;
					data_o[5:4] <= 2'b00;
				end

				if (((((sy+counter+1) ^ (sx+counter+1))%7) | (((sy+counter+1) ^ (sx+counter+1))%9))>1)  begin
					data_o[3:2] <= 2'b00;
				end else begin
					data_o[3:2] <= 2'b11;
				end 
				
			end
			3'd2: begin
				// data_o [7] <= (v_count ^ h_count + 1) < 1;
				// data_o [6] <= (v_count ^ h_count + 1) < 2;
				// data_o [5] <= (v_count ^ h_count) < 1;
				// data_o [4] <= (v_count ^ h_count) < 1;
				// data_o [3] <= (v_count ^ h_count - 1) < 1;
				// data_o [2] <= (v_count ^ h_count - 1) < 1;
				// data_o [1:0] <= 0;

			end
			3'd3: begin
				// data_o [7] <= (v_count ^ h_count) % 7 < 1; 
				// data_o [6] <= (v_count ^ h_count) % 7 < 1; 
				// data_o [5] <= (v_count ^ h_count) % 7 < 1;
				// data_o [4] <= (v_count ^ h_count) % 7 < 1;
				// data_o [3] <= (v_count ^ h_count) % 7 < 1;
				// data_o [2] <= (v_count ^ h_count) % 7 < 1;
				// data_o [1:0] <= 0;

			end
			3'd4: begin
				// data_o [7] <= ((v_count + counter) ^ h_count) % 7 < 1; 
				// data_o [6] <= ((v_count + counter) ^ h_count) % 7 < 1; 
				// data_o [5] <= ((v_count + counter + counter) ^ h_count) % 7 < 1;
				// data_o [4] <= ((v_count + counter + counter) ^ h_count) % 7 < 1;
				// data_o [3] <= (v_count ^ h_count) % 7 < 1;
				// data_o [2] <= (v_count ^ h_count) % 7 < 1;
				// data_o [1:0] <= 0;
				
			end	
			3'd5: begin
				// data_o [7:6] <= 0'b01; 
				// data_o [5:4] <= 0'b11;;
				// data_o [3:2] <= 0'b01;;
				// data_o [1:0] <= 0;
			end
			3'd6: begin
			end
			3'd7: begin
			end
			

		endcase
		
		//strobe to confirm processing
		stb_o <= 1;
		output_available <= 1'b0;
	end
end

endmodule
