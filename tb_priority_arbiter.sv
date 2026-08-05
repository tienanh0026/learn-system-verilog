module tb_priority_arbiter;
  logic [3:0] req;
  logic [3:0] grant;

  typedef struct packed {
    logic [3:0] req;
    logic [3:0] expected_grant;
  } test_case_t;

  test_case_t inputs[3] = '{'{4'b0001, 4'b0001}, '{4'b0101, 4'b0001}, '{4'b1100, 4'b0100}};

  priority_arbiter dut (
      .req  (req),
      .grant(grant)
  );

  initial begin
    for (int i = 0; i < 3; i++) begin
      req = inputs[i].req;
      #10;
      if (inputs[i].expected_grant == grant) $display("success: req=%b, grant=%b", req, grant);
      else $display("failed: req=%b, grant=%b", req, grant);
    end
    $finish;
  end

endmodule
