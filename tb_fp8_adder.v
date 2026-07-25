module tb_fp8_adder;

reg  [7:0] A;
reg  [7:0] B;
wire [7:0] SUM;

reg [7:0] expected_answer [0:65535];

integer a;
integer b;
integer wrong_count;

fp8_adder uut (A, B, SUM);

initial begin

    wrong_count = 0;

    // read the correct answers from the memory file
    $readmemh("fp8_ref.mem", expected_answer);

    // test all possible values of A and B
    for (a = 0; a < 256; a = a + 1) begin
        for (b = 0; b < 256; b = b + 1) begin

            A = a;
            B = b;

            #10;

            if (SUM != expected_answer[a*256 + b]) begin
                wrong_count = wrong_count + 1;

                $display("Wrong answer: A=%h B=%h SUM=%h Expected=%h",
                         A, B, SUM, expected_answer[a*256 + b]);
            end

        end
    end

    $display("Test finished");
    $display("Total tests = 65536");
    $display("Wrong tests = %0d", wrong_count);
    $display("Correct tests = %0d", 65536 - wrong_count);

    $stop;

end

endmodule