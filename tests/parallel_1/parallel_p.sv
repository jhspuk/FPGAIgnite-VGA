module parallel_p(
	input wire clk,
	input wire rst,
    
	input wire [7:0] data,
	input wire stb,
    
	output reg ack,
	output reg rdy,
    
	output reg [7:0] reg_out
);

	// State definitions
	typedef enum logic [1:0] {
		WAITING = 2'b00,
		BUSY = 2'b01,
		DONE = 2'b10
	} state_t;
    
	state_t state, next_state;
	
	logic rdy_internal;

	always_ff @(posedge clk or posedge rst){
		if (rst) begin
			reg_out <= 8'b00000000;
		end else if(stb && rdy_internal && state==WAITING) begin
			state <= BUSY;
		end
	}

	always_ff @(posedge clk){
		case (state)
			WAITING: begin
				
			end
			BUSY: begin
					
			end
			DONE: begin
			
			end
	}


    // State machine logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            reg_out <= 8'd0;
            ack <= 1'b0;
            rdy <= 1'b1;
        end else begin
            state <= next_state;
        end
    end

    always_ff @(posedge clk) begin
        case (state)
            IDLE: begin
                ack <= 1'b0;
                rdy <= 1'b1;
                if (stb) begin
                    reg_out <= data;
                    ack <= 1'b1;
                    rdy <= 1'b0;
                    next_state <= BUSY;
                end else begin
                    next_state <= IDLE;
                end
            end

            BUSY: begin
                ack <= 1'b0;
                rdy <= 1'b1;
                next_state <= IDLE;
            end

            default: begin
                next_state <= IDLE;
            end
        endcase
    end

endmodule

