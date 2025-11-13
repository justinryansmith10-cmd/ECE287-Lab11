`timescale 1ns/1ps

module pop_count_sequential_tb;

    // DUT signals
    reg clk;
    reg rst;
    reg start;
    reg [9:0] input_number;
    wire [7:0] count;
    wire done;

    // instantiate DUT
    pop_count_sequential dut (
        .clk(clk),
        .rst(rst),
        .input_number(input_number),
        .start(start),
        .count(count),
        .done(done)
    );

    // clock generation: 10ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // simple popcount function used by the testbench
    function integer popcount_fn;
        input [9:0] val;
        integer j;
        begin
            popcount_fn = 0;
            for (j = 0; j < 10; j = j + 1) begin
                popcount_fn = popcount_fn + val[j];
            end
        end
    endfunction

    initial begin
        // waveform dump for GTKWave / viewers
        $dumpfile("pop_count_sequential.vcd");
        $dumpvars(0, pop_count_sequential_tb);

        // initial reset
        rst = 1;
        start = 0;
        input_number = 10'd0;
        #20;
        rst = 0;
        #10;

        // test vectors
        reg [9:0] vectors [0:7];
        vectors[0] = 10'd0;     // 0 ones
        vectors[1] = 10'd1;     // 1 one
        vectors[2] = 10'd2;     // 1 one
        vectors[3] = 10'd3;     // 2 ones
        vectors[4] = 10'd255;   // 8 ones (within 10 bits)
        vectors[5] = 10'd511;   // 9 ones
        vectors[6] = 10'd1023;  // 10 ones (all ones)
        vectors[7] = 10'd682;   // arbitrary value

        integer i;
        integer expected;
        integer passed;
        integer total;

        passed = 0;
        total = 8;

        for (i = 0; i < total; i = i + 1) begin
            // prepare input and expected result
            input_number = vectors[i];
            expected = popcount_fn(vectors[i]);

            // pulse start for one clock
            @(posedge clk);
            start = 1;
            @(posedge clk);
            start = 0;

            // wait for done
            wait (done == 1);
            // give one clock to let count settle
            @(posedge clk);

            // check result
            if (count == expected) begin
                $display("[PASS] input=%0d (0b%b) expected=%0d got=%0d", vectors[i], vectors[i], expected, count);
                passed = passed + 1;
            end else begin
                $display("[FAIL] input=%0d (0b%b) expected=%0d got=%0d", vectors[i], vectors[i], expected, count);
            end

            // deassert start (ensure DUT can go back to START)
            start = 0;
            // wait a little before next case
            repeat (2) @(posedge clk);
        end

        $display("Test complete: %0d/%0d passed", passed, total);
        $finish;
    end

endmodule
