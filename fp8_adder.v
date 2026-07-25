module fp8_adder (A, B, SUM);

input  [7:0] A;
input  [7:0] B;
output reg [7:0] SUM;

// split A and B
wire A_s, B_s;
wire [3:0] A_e, B_e;
wire [2:0] A_m, B_m;

assign A_s = A[7];
assign A_e = A[6:3];
assign A_m = A[2:0];

assign B_s = B[7];
assign B_e = B[6:3];
assign B_m = B[2:0];

// special cases
wire A_is_nan, B_is_nan;
wire A_is_inf, B_is_inf;
wire A_is_zero, B_is_zero;

assign A_is_nan  = (A_e == 4'b1111) && (A_m != 3'b000);
assign B_is_nan  = (B_e == 4'b1111) && (B_m != 3'b000);

assign A_is_inf  = (A_e == 4'b1111) && (A_m == 3'b000);
assign B_is_inf  = (B_e == 4'b1111) && (B_m == 3'b000);

assign A_is_zero = (A_e == 4'b0000) && (A_m == 3'b000);
assign B_is_zero = (B_e == 4'b0000) && (B_m == 3'b000);

// change FP8 to integer first, then add
wire signed [18:0] A_num;
wire signed [18:0] B_num;
wire signed [18:0] sum_num;

assign A_num = to_number(A);
assign B_num = to_number(B);

assign sum_num = A_num + B_num;

always @(*) begin

    if (A_is_nan || B_is_nan)
        SUM = 8'b01111001;                 // NaN

    else if (A_is_inf && B_is_inf && (A_s != B_s))
        SUM = 8'b01111001;                 // +inf + -inf

    else if (A_is_inf)
        SUM = {A_s, 4'b1111, 3'b000};      // A is infinity

    else if (B_is_inf)
        SUM = {B_s, 4'b1111, 3'b000};      // B is infinity

    else if (sum_num == 0) begin
        if (A_is_zero && B_is_zero && A_s && B_s)
            SUM = 8'b10000000;             // -0
        else
            SUM = 8'b00000000;             // +0
    end

    else
        SUM = to_fp8(sum_num);

end


// This function changes FP8 into an integer. In this code, 512 means 1.0.
function signed [18:0] to_number;
    input [7:0] x;

    reg x_s;
    reg [3:0] x_e;
    reg [2:0] x_m;
    reg [18:0] size;

    begin
        x_s = x[7];
        x_e = x[6:3];
        x_m = x[2:0];

        if (x_e == 4'b0000)
            size = {16'b0, x_m};
        else
            size = {15'b0, 1'b1, x_m} << (x_e - 1);

        if (x_s)
            to_number = -size;
        else
            to_number = size;
    end
endfunction


// This function changes the integer answer back to FP8.
function [7:0] to_fp8;
    input signed [18:0] value;

    reg ans_s;
    reg [18:0] size;
    reg [3:0] ans_e;
    reg [4:0] ans_m;

    reg [18:0] remainder;
    reg [18:0] half;
    integer shift;

    begin

        // get sign and positive size
        if (value[18]) begin
            ans_s = 1'b1;
            size  = -value;
        end
        else begin
            ans_s = 1'b0;
            size  = value;
        end

        // too big, so make it infinity
        if (size >= 19'd126976) begin
            to_fp8 = {ans_s, 4'b1111, 3'b000};
        end

        // very small number
        else if (size < 19'd8) begin
            to_fp8 = {ans_s, 4'b0000, size[2:0]};
        end

        // normal number
        else begin

            if      (size < 19'd16)    ans_e = 4'd1;
            else if (size < 19'd32)    ans_e = 4'd2;
            else if (size < 19'd64)    ans_e = 4'd3;
            else if (size < 19'd128)   ans_e = 4'd4;
            else if (size < 19'd256)   ans_e = 4'd5;
            else if (size < 19'd512)   ans_e = 4'd6;
            else if (size < 19'd1024)  ans_e = 4'd7;
            else if (size < 19'd2048)  ans_e = 4'd8;
            else if (size < 19'd4096)  ans_e = 4'd9;
            else if (size < 19'd8192)  ans_e = 4'd10;
            else if (size < 19'd16384) ans_e = 4'd11;
            else if (size < 19'd32768) ans_e = 4'd12;
            else if (size < 19'd65536) ans_e = 4'd13;
            else                       ans_e = 4'd14;

            shift = ans_e - 1;
            ans_m = size >> shift;

            // check if we need to round up
            if (shift > 0) begin
                remainder = size - ({14'b0, ans_m} << shift);
                half = 19'd1 << (shift - 1);

                if ((remainder > half) || ((remainder == half) && ans_m[0]))
                    ans_m = ans_m + 1'b1;
            end

            // if mantissa became too big
            if (ans_m >= 5'd16) begin
                ans_m = 5'd8;
                ans_e = ans_e + 1'b1;
            end

            // exponent too big means infinity
            if (ans_e >= 4'd15)
                to_fp8 = {ans_s, 4'b1111, 3'b000};
            else
                to_fp8 = {ans_s, ans_e, ans_m[2:0]};
        end
    end
endfunction

endmodule