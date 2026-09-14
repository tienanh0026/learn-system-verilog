module tb_async_fifo;
  logic wr_clk, wr_rst, rd_clk, rd_rst;
  logic wr_en, rd_en, empty, full;
  logic [7:0] data_in, data_out;

  // Use ADDR_WIDTH=3 (depth=8) so we can actually fill it with 8 writes
  async_fifo #(
      .DATA_WIDTH(8),
      .ADDR_WIDTH(3)
  ) dut (
      .wr_clk  (wr_clk),
      .rd_clk  (rd_clk),
      .wr_rst  (wr_rst),
      .rd_rst  (rd_rst),
      .wr_en   (wr_en),
      .rd_en   (rd_en),
      .data_in (data_in),
      .data_out(data_out),
      .full    (full),
      .empty   (empty)
  );

  initial begin
    wr_clk = 0;
    rd_clk = 0;
  end
  always #5 wr_clk = ~wr_clk;
  always #7 rd_clk = ~rd_clk;

  logic [7:0] wr_data[8] = '{8'hAA, 8'hBB, 8'hCC, 8'hDD, 8'hEE, 8'hFF, 8'd7, 8'd8};
  logic write_done = 0;

  // Write domain
  initial begin
    wr_rst  = 1;
    wr_en   = 0;
    data_in = 0;
    repeat (2) @(posedge wr_clk);
    wr_rst = 0;

    // Write all 8 values
    wr_en  = 1;
    for (int i = 0; i < 8; i++) begin
      data_in = wr_data[i];
      @(posedge wr_clk);
    end
    wr_en = 0;

    // Wait for full flag (needs sync latency to propagate)
    repeat (8) @(posedge wr_clk);
    #1;
    if (full) $display("PASS: full asserted");
    else $display("FAIL: full not asserted (full=%b)", full);

    write_done = 1;  // now signal read domain it's safe to start
  end

  // Read domain
  initial begin
    rd_rst = 1;
    rd_en  = 0;
    repeat (2) @(posedge rd_clk);
    rd_rst = 0;


    // Wait for write domain to finish AND assert full
    @(posedge write_done);  // blocks here until write_done goes high

    repeat (3) @(posedge rd_clk);  // small extra settling margin

    // Read and check all 8 values
    rd_en = 1;
    for (int i = 0; i < 8; i++) begin
      #1;
      if (data_out == wr_data[i]) $display("PASS: data_out=%h (expected %h)", data_out, wr_data[i]);
      else $display("FAIL: data_out=%h (expected %h)", data_out, wr_data[i]);
      @(posedge rd_clk);
    end
    rd_en = 0;

    // Wait for empty flag to propagate
    repeat (4) @(posedge rd_clk);
    #1;
    if (empty) $display("PASS: empty asserted after draining FIFO");
    else $display("FAIL: empty not asserted (empty=%b)", empty);

    $finish;
  end

endmodule
