
module tb_shift_reg;

  logic       clk;
  logic       rst;
  logic       en;
  logic       dir;
  logic       serial_in;
  logic [3:0] data;
  logic       serial_out;

  // Instantiate the DUT (Device Under Test)
  shift_reg dut (
      .clk       (clk),
      .rst       (rst),
      .en        (en),
      .dir       (dir),
      .serial_in (serial_in),
      .data      (data),
      .serial_out(serial_out)
  );

  // Clock generation: 10ns period
  initial clk = 0;
  always #5 clk = ~clk;

  // Stimulus
  initial begin
    rst = 1;
    en  = 0;
    @(posedge clk);
    @(posedge clk);
    rst = 0;


    // En = 1
    en  = 1;
    repeat (2) @(posedge clk);

    dir = 1;
    serial_in = 1;
    repeat (2) @(posedge clk);

    dir = 1;
    serial_in = 0;
    repeat (2) @(posedge clk);

    dir = 0;
    serial_in = 1;
    repeat (2) @(posedge clk);

    dir = 0;
    serial_in = 0;
    repeat (2) @(posedge clk);

    // En = 0
    en = 0;
    repeat (5) @(posedge clk);

    $stop;  // end simulation
  end

  // // Optional: print each cycle
  // initial begin
  //     $monitor("time=%0t rst=%b en=%b count=%d tc=%b", $time, rst, en, count, tc);
  // end

endmodule
