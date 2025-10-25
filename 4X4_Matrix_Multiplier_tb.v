module tb_matrix_mult;
    reg clk;
    reg reset;
    reg start;
    wire done;

    matrix_mult_simple_mem uut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .done(done)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("matrix_mult.vcd");
        $dumpvars(0, tb_matrix_mult);

        clk = 0;
        reset = 1;
        start = 0;
        #10;

        reset = 0;
        #10;

        start = 1;
        #10;
        start = 0;

        wait(done);
        #10;
        $finish;
    end
endmodule
