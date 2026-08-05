
module tb_edge_detector;
  logic clk;
  logic rst;
  logic sig_in;
  logic pulse;
  edge_detector dut (
      .clk(clk),
      .rst(rst),
      .sig_in(sig_in),
      .pulse(pulse)
  );


  // Clock generation: 10ns period
  initial clk = 0;
  always #5 clk = ~clk;

  // Stimulus
  initial begin
    rst = 1;
    @(posedge clk);
    @(posedge clk);
    rst = 0;

    sig_in = 0;
    repeat (1) @(posedge clk);
    sig_in = 0;
    repeat (1) @(posedge clk);
    sig_in = 1;
    repeat (1) @(posedge clk);
    sig_in = 1;
    repeat (1) @(posedge clk);
    sig_in = 1;
    repeat (1) @(posedge clk);
    sig_in = 0;
    repeat (1) @(posedge clk);
    sig_in = 1;
    repeat (1) @(posedge clk);

    $stop;  // end simulation
  end

  // Optional: print each cycle
  initial begin
    $monitor("1");
  end

endmodule
