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

reg [buffer_index_bits_both

reg [(buffer_num * 8) - 1:0] ring_line;
reg [buffer_index_bits:0] ring_index;

reg output_available;



//input handshake, read in
always @(posedge clk or posedge rst) begin
	if (rst) begin
		ring_line[255:0] <= {256{1'b0}};
		ring_index <= 0;
		h_count <= 0;
		v_count <= 0;
		stb_o <= 0;
		data_o <= 0;
		ack_i <= 0;
	end else if(stb_i == 1) begin
		ring_index <= ring_index + 1;
		ring_line <= {ring_line[buffer_size - 8 : 0], data_i};
		ack_i <= 1;
		//if (ring_index == 0) begin
		//	ring_line[buffer_size : buffer_size - 8] <= data_i;
		//end else begin
		//	ring_line[(ring_index + 1) * 8 : ring_index * 8 ] <= data_i;
		//end
		//	ack_i <= 1;
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
	if (ack_o) begin
		stb_o <= 0;
		output_available <= 1'b1;
	end else if(output_available) begin
		//processing goes here
		
		if (v_count == buffer_num - 1) begin
			h_count <= 0;
			v_count <= 0;
		end else begin
			if (h_count == buffer_num - 1) begin
				h_count <= 0;
			end else begin
				h_count <= h_count + 1;
			end
		end
		
		
		
		//create output data
		data_o <= data_i;
		
		//strobe to confirm processing
		stb_o <= 1;
	end
end

endmodule
