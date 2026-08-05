module tb_button_debouncer;
  logic clk;
  logic rst;
  logic data_in;
  logic en;
  button_debouncer dut (
      .clk(clk),
      .rst(rst),
      .data_in(data_in),
      .en(en)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    rst = 1;
    @(posedge clk);
    @(posedge clk);
    rst = 0;

    @(posedge clk);

    data_in = 1;
    @(posedge clk);
    data_in = 1;
    @(posedge clk);
    data_in = 1;
    @(posedge clk);
    data_in = 1;
    @(posedge clk);
    #1;
    if (en) $display("PASS");
    else $display("FAIL");


    data_in = 0;
    @(posedge clk);
    data_in = 1;
    @(posedge clk);
    data_in = 0;
    @(posedge clk);
    data_in = 1;
    @(posedge clk);
    #1;
    if (!en) $display("PASS");
    else $display("FAIL");

    $finish;
  end

endmodule
