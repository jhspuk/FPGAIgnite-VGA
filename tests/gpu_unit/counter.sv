
module counter (
    input wire reset,     // Reset signal
    input wire count,     // Count enable signal
    output wire out // 15-bit output (to count up to 19200)
);

    parameter MAX_COUNT = 307200; // counting (640*480) since
    reg [19:0] count_value;

    always @(posedge count or posedge reset) begin
        if (reset) begin
            // Reset the counter to 0
            out <= 1'b0;
            count_value <= 15'b0;
        end else begin

            if (count  && out < MAX_COUNT) begin
                if (count_value < MAX_COUNT) begin
                    count_value <= count_value + 1;
                    out <= 1'b0; 

                end else begin
                    
                    out <= 1'b1;
                end
            end
        end
    end
endmodule

