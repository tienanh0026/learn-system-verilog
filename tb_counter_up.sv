
module tb_up_counter;

    logic       clk;
    logic       rst;
    logic       en;
    logic [3:0] count;
    logic       tc;

    // Instantiate the DUT (Device Under Test)
    up_counter dut (
        .clk   (clk),
        .rst   (rst),
        .en    (en),
        .count (count),
        .tc    (tc)
    );

    // Clock generation: 10ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // Stimulus
    initial begin
        rst = 1; en = 0;
        @(posedge clk);
        @(posedge clk);
        rst = 0; en = 1;

        repeat (20) @(posedge clk);  // let it count and wrap around

        en = 0;
        repeat (3) @(posedge clk);   // check it holds

        en = 1;
        repeat (5) @(posedge clk);

        $stop;  // end simulation
    end

    // Optional: print each cycle
    initial begin
        $monitor("time=%0t rst=%b en=%b count=%d tc=%b", $time, rst, en, count, tc);
    end

endmodule