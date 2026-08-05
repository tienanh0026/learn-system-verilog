module tb_round_robin_arbiter;
  logic [3:0] req;
  logic [3:0] grant;
  logic clk;
  logic rst;

  round_robin_arbiter dut (
      .req  (req),
      .grant(grant),
      .clk  (clk),
      .rst  (rst)
  );

  initial clk = 0;
  always #5 clk = ~clk;
  initial begin
    rst = 0;
    req = 4'b1111;
    @(posedge clk);
    #1;
    if (grant == 4'b0010) $display("Success");
    else $display("Failed, grant=%b", grant);

    @(posedge clk);
    #1;
    if (grant == 4'b0100) $display("Success");
    else $display("Failed, grant=%b", grant);

    @(posedge clk);
    #1;
    if (grant == 4'b1000) $display("Success");
    else $display("Failed, grant=%b", grant);

    @(posedge clk);
    #1;
    if (grant == 4'b0001) $display("Success");
    else $display("Failed, grant=%b", grant);

    $finish;
  end

endmodule
