module tb_sequence_detector_fsm_moore;
  logic clk;
  logic rst;
  logic data_in;
  logic is_valid;
  sequence_detector_fsm_moore dut (
      .clk(clk),
      .rst(rst),
      .data_in(data_in),
      .is_valid(is_valid)
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

    data_in = 1;
    repeat (1) @(posedge clk);
    data_in = 1;
    repeat (1) @(posedge clk);
    data_in = 0;
    repeat (1) @(posedge clk);
    data_in = 1;
    repeat (1) @(posedge clk);
    data_in = 1;
    repeat (1) @(posedge clk);
    data_in = 0;
    repeat (1) @(posedge clk);
    data_in = 1;
    repeat (1) @(posedge clk);

    $stop;  // end simulation
  end

  // Optional: print each cycle
  initial begin
    $monitor("1");
  end

endmodule



