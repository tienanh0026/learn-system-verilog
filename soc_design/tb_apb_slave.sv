module tb_apb_slave;

  localparam DATA_WIDTH = 32;
  localparam FIFO_DEPTH = 16;

  logic                              clk;
  logic                              rst_n;

  logic [                       7:0] paddr;
  logic                              pwrite;
  logic                              psel;
  logic                              penable;
  logic [            DATA_WIDTH-1:0] pwdata;

  logic [            DATA_WIDTH-1:0] prdata;
  logic                              pready;

  // FIFO status 
  logic                              full;
  logic                              empty;
  logic [$clog2(FIFO_DEPTH + 1)-1:0] count;

  // APB slave output
  logic                              fifo_en;
  logic                              fifo_flush;
  logic                              almost_empty;
  logic                              almost_full;


  apb_slave #(
      .FIFO_DEPTH(FIFO_DEPTH),
      .DATA_WIDTH(DATA_WIDTH)
  ) dut (
      .pclk        (clk),
      .prst_n      (rst_n),
      .paddr       (paddr),
      .pwrite      (pwrite),
      .psel        (psel),
      .penable     (penable),
      .pwdata      (pwdata),
      .prdata      (prdata),
      .pready      (pready),
      .full        (full),
      .empty       (empty),
      .count       (count),
      .fifo_en     (fifo_en),
      .fifo_flush  (fifo_flush),
      .almost_full (almost_full),
      .almost_empty(almost_empty)
  );


  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  function automatic void check(logic condition, string msg);
    if (!condition) begin
      $error("[%0t] FAIL: %s", $time, msg);
    end
  endfunction

  task automatic apb_write(input logic [7:0] addr, input logic [31:0] data);
    begin
      // SETUP
      @(negedge clk);
      psel    = 1'b1;
      penable = 1'b0;
      pwrite  = 1'b1;
      paddr   = addr;
      pwdata  = data;
      $display("[%0t] SETUP: paddr=%h pwdata=%h", $time, paddr, pwdata);

      // ACCESS
      @(negedge clk);
      penable = 1'b1;

      $display("[%0t] ACCESS: paddr=%h pwdata=%h", $time, paddr, pwdata);

      @(posedge clk);

      wait (pready);

      // IDLE
      @(negedge clk);
      psel    = 1'b0;
      penable = 1'b0;
      pwrite  = 1'b0;
      paddr   = '0;
      pwdata  = '0;
    end
  endtask

  task automatic apb_read(input logic [7:0] addr, output logic [31:0] data);
    begin
      // SETUP
      @(negedge clk);
      psel    = 1'b1;
      penable = 1'b0;
      pwrite  = 1'b0;
      paddr   = addr;

      // ACCESS
      @(negedge clk);
      penable = 1'b1;

      @(posedge clk);

      wait (pready);

      data = prdata;

      // IDLE
      @(negedge clk);
      psel    = 1'b0;
      penable = 1'b0;
      pwrite  = 1'b0;
      paddr   = '0;
    end
  endtask

  //   TEST 1 APB Register write/read
  task automatic apb_register_write_read_test();
    $display("---  TEST 1 APB Register write/read ---");
    begin
      logic [ 7:0] addr = 8'h4;

      logic [31:0] wrdata = 1;
      logic [31:0] rdata;
      apb_write(.addr(addr), .data(wrdata));
      apb_read(.addr(addr), .data(rdata));

      check(wrdata == rdata, $sformatf(
            "Read/write data mismatch read_data:%0b, write_data:%0b", rdata, wrdata));
    end
  endtask

  //   TEST 2 APB FIFO ENABLE
  task automatic apb_fifo_enable();
    $display("---  TEST 2 APB FIFO ENABLE ---");
    begin
      logic [ 7:0] addr = 8'h0;
      logic [31:0] wrdata = 1;
      apb_write(.addr(addr), .data(wrdata));

      check(fifo_en == 1, $sformatf("Expected fifo_en=1, fifo_en:%0b", fifo_en));
    end
  endtask

  //   TEST 3 APB AFULL_TH
  task automatic apb_afull_th_enable();
    $display("---  TEST 3 APB AFULL_TH ---");
    begin
      logic [ 7:0] addr = 8'h04;
      logic [31:0] wrdata = 12;
      logic [31:0] rdata;

      apb_write(.addr(addr), .data(wrdata));
      apb_read(.addr(addr), .data(rdata));
      check(wrdata == rdata, $sformatf(
            "Read/write data mismatch read_data:%0b, write_data:%0b", rdata, wrdata));
    end
  endtask

  //   TEST 4 APB ALMOST_FULL
  task automatic apb_almost_full_test();
    $display("---  TEST 4 APB AFULL_TH ---");
    begin
      logic [ 7:0] addr = 8'h04;
      logic [31:0] wrdata = 12;

      apb_write(.addr(addr), .data(wrdata));

      count = 11;
      check(almost_full == 0, $sformatf(
            "Expected almost_full=0, actual almost_full=%0b", almost_full));
      @(posedge clk);
      count = 12;
      #1
      check(
          almost_full == 1,
          $sformatf(
              "Expected almost_full=1, actual almost_full=%0b", almost_full
          ));
    end
  endtask

  initial begin
    rst_n   = 1'b0;

    paddr   = '0;
    pwrite  = 1'b0;
    psel    = 1'b0;
    penable = 1'b0;
    pwdata  = '0;

    full  = 1'b0;
    empty = 1'b1;
    count = '0;

    repeat (2) @(posedge clk);
    rst_n = 1'b1;

    @(posedge clk);
    apb_register_write_read_test();
    apb_fifo_enable();
    apb_afull_th_enable();
    apb_almost_full_test();
  end

endmodule
