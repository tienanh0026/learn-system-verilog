module tb_uart_tx ();

  localparam int CLK_FREQ = 8;
  localparam int BAUD_RATE = 2;
  localparam int CYCLES_PER_BIT = CLK_FREQ / BAUD_RATE;  // = 4

  logic clk, rst, tx_start, tx, tx_busy;
  logic [7:0] data;


  // Clock cycles = 4;
  uart_transmitter #(
      .CLK_FREQ (CLK_FREQ),
      .BAUD_RATE(BAUD_RATE)
  ) dut (
      .clk(clk),
      .rst(rst),
      .tx_start(tx_start),
      .data(data),
      .tx(tx),
      .tx_busy(tx_busy)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  // Expected bits for 8'b10001010: LSB first = 0,1,0,1,0,0,0,1
  logic [9:0] expected = 10'b1_10001010_0;  // stop, data MSB→LSB, start — read right to left
  // Actually bit order: [0]=start=0, [1..8]=data LSB first, [9]=stop=1


  initial begin
    // Reset
    rst = 1;
    tx_start = 0;
    data = 0;
    @(posedge clk);
    @(posedge clk);
    rst = 0;

    // Start transmission
    data = 8'b10001010;
    tx_start = 1;
    @(posedge clk);
    tx_start = 0;


    // Wait half a bit period to sample mid-bit
    repeat (CYCLES_PER_BIT / 2) @(posedge clk);
    #1;

    // Check start bit
    if (tx == 1'b0) $display("PASS: start bit tx=%b", tx);
    else $display("FAIL: start bit tx=%b (expected 0)", tx);

    // Check each data bit (LSB first: 0,1,0,1,0,0,0,1 for 8'b10001010)
    begin
      automatic logic [7:0] d = 8'b10001010;
      for (int i = 0; i < 8; i++) begin
        repeat (CYCLES_PER_BIT) @(posedge clk);
        #1;
        if (tx == d[i]) $display("PASS: bit[%0d] tx=%b", i, tx);
        else $display("FAIL: bit[%0d] tx=%b (expected %b)", i, tx, d[i]);
      end
    end

    // Check stop bit
    repeat (CYCLES_PER_BIT) @(posedge clk);
    #1;
    if (tx == 1'b1) $display("PASS: stop bit tx=%b", tx);
    else $display("FAIL: stop bit tx=%b (expected 1)", tx);

    // Confirm tx_busy drops after stop
    repeat (CYCLES_PER_BIT) @(posedge clk);
    #1;
    if (!tx_busy) $display("PASS: tx_busy cleared after stop");
    else $display("FAIL: tx_busy still high after stop");

    $finish;
  end

endmodule

