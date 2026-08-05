module tb_single_port_ram;
  logic clk;
  logic rst;
  logic we;
  logic [3:0] addr;
  logic [7:0] data_in;
  logic [7:0] data_out;

  single_port_ram dut (
      .clk(clk),
      .rst(rst),
      .we(we),
      .addr(addr),
      .data_in(data_in),
      .data_out(data_out)
  );


  // 10ns period
  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    rst = 1;
    @(posedge clk);
    @(posedge clk);
    rst = 0;

    // Write 8'h02 to addr 2
    data_in = 8'h02;
    addr = 2;
    we = 1;
    @(posedge clk);
    // At this point, data_out reflects mem[addr] from BEFORE this edge (old/garbage value) — nothing meaningful to check yet since this was the first real access

    // Read back addr 2 (we=0 now)
    data_in = 8'h00;
    addr = 2;
    we = 0;
    @(posedge clk);
    // NOW data_out should show the value written last cycle (8'h02), because THIS edge registered mem[2] using the addr=2 we set just before it
    #1;
    if (data_out == 8'h02) $display("PASS: read addr=2, data_out=%h (expected 02)", data_out);
    else $display("FAIL: read addr=2, data_out=%h (expected 02)", data_out);

    // Write 8'h03 to addr 3
    data_in = 8'h03;
    addr = 3;
    we = 1;
    @(posedge clk);

    // Read-during-write test: write 8'hFF to addr 3 WHILE reading addr 3 same cycle
    data_in = 8'hFF;
    addr = 3;
    we = 1;
    @(posedge clk);
    // data_out now shows mem[3] as it was BEFORE this write took effect (old value = 8'h03, since read-old-data behavior)
    #1;
    if (data_out == 8'h03)
      $display("PASS: read-during-write addr=3, data_out=%h (expected 03, old value)", data_out);
    else $display("FAIL: read-during-write addr=3, data_out=%h (expected 03)", data_out);

    $finish;
  end

endmodule
