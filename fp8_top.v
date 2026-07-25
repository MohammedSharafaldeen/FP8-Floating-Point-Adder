module fp8_top (fr_SW, fr_KEY, to_LEDR, to_HEX0, to_HEX1, to_HEX2, to_HEX3, to_HEX4, to_HEX5);
input  [9:0] fr_SW;
input  [1:0] fr_KEY;
output [9:0] to_LEDR;
output [7:0] to_HEX0, to_HEX1, to_HEX2, to_HEX3, to_HEX4, to_HEX5;

reg [7:0] A;
reg [7:0] B;

wire [7:0] SUM;
reg  [7:0] display_value;

assign to_LEDR = fr_SW;


always @(negedge fr_KEY[0]) begin
    A <= fr_SW[7:0];
end

always @(negedge fr_KEY[1]) begin
    B <= fr_SW[7:0];
end

fp8_adder u1 (A,B,SUM);

always @(*) begin
    case (fr_SW[9:8])
        2'b00: display_value = fr_SW[7:0]; 
        2'b01: display_value = A;
        2'b10: display_value = B;
        2'b11: display_value = SUM;
        default: display_value = fr_SW[7:0];
    endcase
end

fp8_value_display d1 (display_value, to_HEX5, to_HEX4, to_HEX3, to_HEX2, to_HEX1, to_HEX0);

endmodule