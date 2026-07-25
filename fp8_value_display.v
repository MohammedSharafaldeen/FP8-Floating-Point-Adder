module fp8_value_display (X, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0);

input [7:0] X;

output reg [7:0] HEX5, HEX4, HEX3, HEX2, HEX1, HEX0;

// split the FP8 number
wire X_s;
wire [3:0] X_e;
wire [2:0] X_m;

assign X_s = X[7];
assign X_e = X[6:3];
assign X_m = X[2:0];

// check special cases
wire X_is_nan;
wire X_is_inf;

assign X_is_nan = (X_e == 4'b1111) && (X_m != 3'b000);
assign X_is_inf = (X_e == 4'b1111) && (X_m == 3'b000);

reg [18:0] size;

reg [9:0] whole_num;
reg [6:0] decimal_part;

reg [3:0] h, t, o, d1, d2;

integer n;

always @(*) begin

    HEX5 = 8'b11111111;
    HEX4 = 8'b11111111;
    HEX3 = 8'b11111111;
    HEX2 = 8'b11111111;
    HEX1 = 8'b11111111;
    HEX0 = 8'b11111111;

    size = 19'd0;
    whole_num = 10'd0;
    decimal_part = 7'd0;

    h = 4'd0;
    t = 4'd0;
    o = 4'd0;
    d1 = 4'd0;
    d2 = 4'd0;

    n = 0;

    // show nAn
    if (X_is_nan) begin
        HEX5 = 8'b11111111; 
        HEX4 = 8'b10101011; // n
        HEX3 = 8'b10001000; // A
        HEX2 = 8'b10101011; // n
        HEX1 = 8'b11111111; 
        HEX0 = 8'b11111111; 
    end

    // show InF or -InF
    else if (X_is_inf) begin

        if (X_s)
            HEX5 = 8'b10111111; // -
        else
            HEX5 = 8'b11111111; 

        HEX4 = 8'b11111001; // I
        HEX3 = 8'b10101011; // n
        HEX2 = 8'b10001110; // F
        HEX1 = 8'b11111111; 
        HEX0 = 8'b11111111; 
    end

    // normal number, subnormal number, or zero
    else begin

        if (X_s)
            HEX5 = 8'b10111111; // -
        else
            HEX5 = 8'b11111111; 

        // convert FP8 to integer units, 512 units means 1.0
        if (X_e == 4'b0000)
            size = {16'b0, X_m};
        else
            size = ({15'b0, 1'b1, X_m} << (X_e - 1));

        // number before decimal point
        whole_num = size / 512;

        // two digits after decimal point
        decimal_part = ((size - whole_num * 512) * 100) / 512;

        d1 = decimal_part / 10;
        d2 = decimal_part - d1 * 10;

        n = whole_num;
        h = n / 100;
        n = n - h * 100;
        t = n / 10;
        o = n - t * 10;

        HEX4 = show_digit(h); // hundereds
        HEX3 = show_digit(t); // tens
        HEX2 = show_digit(o); // ones
        HEX1 = show_digit(d1); //first dicimal value
        HEX0 = show_digit(d2); // second dicimal value

        // decimal point after ones digit
        HEX2[7] = 1'b0;
    end
end

function [7:0] show_digit;
    input [3:0] num;
    begin
        case (num)
            4'd0: show_digit = 8'b11000000;
            4'd1: show_digit = 8'b11111001;
            4'd2: show_digit = 8'b10100100;
            4'd3: show_digit = 8'b10110000;
            4'd4: show_digit = 8'b10011001;
            4'd5: show_digit = 8'b10010010;
            4'd6: show_digit = 8'b10000010;
            4'd7: show_digit = 8'b11111000;
            4'd8: show_digit = 8'b10000000;
            4'd9: show_digit = 8'b10010000;
            default: show_digit = 8'b11111111;
        endcase
    end
endfunction

endmodule