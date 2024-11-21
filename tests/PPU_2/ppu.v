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

reg [buffer_index_bits:0] counter;

reg [(buffer_num * 8) - 1:0] ring_line;
reg [buffer_index_bits:0] ring_index;

reg output_available;



//input handshake, read in
always @(posedge clk or posedge rst) begin
	if (rst) begin
		ring_line[255:0] <= {256{1'b0}};
		ring_index <= 0;
		ack_i <= 0;
	end else if(stb_i == 1) begin
		ring_index <= ring_index + 1;
		ring_line <= {ring_line[buffer_size - 8 : 0], data_i};
		ack_i <= 1;
	end else begin
		ack_i <= 1'b0;
	end	
end

always @(posedge sync) begin
	h_count <= 0;
	v_count <= 0;
end

//output handshake
always @(posedge clk) begin

	if (rst) begin
		data_o <= 0;
		stb_o <= 0;
		h_count <= 0;
		v_count <= 0;
		counter <= 0;
		output_available <= 1;
	end else if (ack_o) begin
	
		stb_o <= 0;
		output_available <= 1'b1;
		
	end else if(output_available) begin
		//processing goes here
		
		if (v_count == buffer_num - 1) begin
			if (h_count == buffer_num - 1) begin
				h_count <= 0;
				counter <= counter + 1;
				data_o[1] = 1'b1;
				data_o[0] = 1'b1;
			end else begin
				h_count <= h_count + 1;
			end
			v_count <= 0;
		end else begin
			if (h_count == buffer_num - 1) begin
				h_count <= 0;
			end else begin
				h_count <= h_count + 1;
			end
			v_count <= v_count + 1;
		end
		
		//create output data
		case (mode)
			3'd0: begin
				data_o <= data_i;
			end
			3'd1: begin
				data_o [7:6] <= (v_count ^ h_count) > 0 ? ring_line[7:6] : 0;
				data_o [5:4] <= (v_count ^ h_count) > 0 ? ring_line[5:4] : 0;
				data_o [3:2] <= (v_count ^ h_count) > 0 ? ring_line[3:2] : 0;
				data_o [3:2] <= (v_count ^ h_count) > 0 ? ring_line[3:2] : 0;
				data_o [1:0] <= 0;
			end
			3'd2: begin
				data_o [7] <= (v_count ^ h_count + 1) < 1;
				data_o [6] <= (v_count ^ h_count + 1) < 2;
				data_o [5] <= (v_count ^ h_count) < 1;
				data_o [4] <= (v_count ^ h_count) < 1;
				data_o [3] <= (v_count ^ h_count - 1) < 1;
				data_o [2] <= (v_count ^ h_count - 1) < 1;
				data_o [1:0] <= 0;

			end
			3'd3: begin
				data_o [7] <= (v_count ^ h_count) % 7 < 1; 
				data_o [6] <= (v_count ^ h_count) % 7 < 1; 
				data_o [5] <= (v_count ^ h_count) % 7 < 1;
				data_o [4] <= (v_count ^ h_count) % 7 < 1;
				data_o [3] <= (v_count ^ h_count) % 7 < 1;
				data_o [2] <= (v_count ^ h_count) % 7 < 1;
				data_o [1:0] <= 0;

			end
			3'd4: begin
				data_o [7] <= ((v_count + counter) ^ h_count) % 7 < 1; 
				data_o [6] <= ((v_count + counter) ^ h_count) % 7 < 1; 
				data_o [5] <= ((v_count + counter + counter) ^ h_count) % 7 < 1;
				data_o [4] <= ((v_count + counter + counter) ^ h_count) % 7 < 1;
				data_o [3] <= (v_count ^ h_count) % 7 < 1;
				data_o [2] <= (v_count ^ h_count) % 7 < 1;
				data_o [1:0] <= 0;


			end	
			3'd5: begin
			end
			3'd6: begin
			end
			3'd7: begin
			end
			

		endcase
		
		//strobe to confirm processing
		stb_o <= 1;
	end
end

endmodule
