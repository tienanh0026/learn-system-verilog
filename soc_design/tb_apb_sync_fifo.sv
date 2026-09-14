module tb_apb_sync_fifo ();
  localparam int DATA_WIDTH = 32;
  localparam int FIFO_DEPTH = 16;
  localparam int CLK_PERIOD = 10;

  logic clk, rst_n;


  // Slave
  logic [7:0] paddr;
  logic psel, penable, pwrite, pready;
  logic [DATA_WIDTH-1:0] pwdata, prdata;

  // FIFO
  logic in_valid, out_ready, in_ready, out_valid;
  logic [DATA_WIDTH-1:0] in_data, out_data;
  logic almost_full, almost_empty;


  sync_fifo_apb_top #(
      .DATA_WIDTH(DATA_WIDTH),
      .FIFO_DEPTH(FIFO_DEPTH)
  ) dut (
      .*
  );


  // CLOCK
  initial clk = 0;
  always #(CLK_PERIOD / 2) clk = ~clk;


  function automatic void check(logic condition, string msg);
    if (!condition) begin
      $error("[%0t] FAIL: %s", $time, msg);
    end
  endfunction

  task automatic apb_write(input logic [7:0] addr, input logic [31:0] data);
    begin
      // SETUP
      @(negedge clk);
      psel    <= 1'b1;
      penable <= 1'b0;
      pwrite  <= 1'b1;
      paddr   <= addr;
      pwdata  <= data;
      $display("[%0t] SETUP: paddr=%h pwdata=%h", $time, paddr, pwdata);
      // ACCESS
      @(negedge clk);
      penable <= 1'b1;

      $display("[%0t] ACCESS: paddr=%h pwdata=%h", $time, paddr, pwdata);

      @(posedge clk);

      wait (pready);

      // IDLE
      @(negedge clk);
      psel    <= 1'b0;
      penable <= 1'b0;
      pwrite  <= 1'b0;
      paddr   <= '0;
      pwdata  <= '0;
    end
  endtask

  task automatic apb_read(input logic [7:0] addr, output logic [31:0] data);
    begin
      // SETUP
      @(negedge clk);
      psel    <= 1'b1;
      penable <= 1'b0;
      pwrite  <= 1'b0;
      paddr   <= addr;

      // ACCESS
      @(negedge clk);
      penable <= 1'b1;

      @(posedge clk);

      wait (pready);

      data = prdata;

      // IDLE
      @(negedge clk);
      psel    <= 1'b0;
      penable <= 1'b0;
      pwrite  <= 1'b0;
      paddr   <= '0;
    end
  endtask

  //   TEST 1 APB Register write/read
  task automatic apb_register_write_read_test();
    $display("---  TEST 1 APB Register write/read ---");
    begin
      logic [ 7:0] addr = 8'h0;
      logic [31:0] wrdata = 1;
      logic [31:0] rdata;
      apb_write(.addr(addr), .data(wrdata));
      apb_read(.addr(addr), .data(rdata));

      check(wrdata == rdata, $sformatf(
            "Read/write data mismatch read_data:%0b, write_data:%0b", rdata, wrdata));
    end
  endtask

  //   TEST 2 FIFO_EN
  task automatic apb_fifo_en_test();
    $display("---  TEST 2 FIFO_EN ---");
    begin
      logic [ 7:0] addr = 8'h0;
      logic [31:0] wrdata = 1;
      logic [31:0] level_data;

      apb_write(.addr(addr), .data(wrdata));

      @(posedge clk);
      in_valid = 1;
      in_data  = 100;
      @(posedge clk);
      in_valid = 0;
      apb_read(.addr(8'h10), .data(level_data));
      check(level_data == 1, $sformatf("Expected level_data=1, level_data:%h", level_data));

    end
  endtask

  //  Test 3 — Configure Almost-Full Threshold
  task automatic apb_almost_full_th_test();
    $display("---  TEST 3 Configure Almost-Full Threshold ---");
    begin
      logic [ 7:0] addr = 8'h04;
      logic [31:0] wrdata = 12;

      apb_write(.addr(addr), .data(wrdata));

      @(posedge clk);

      // 11 write entries
      in_valid = 1;
      in_data  = 100;
      repeat (11) @(posedge clk);
      in_valid = 0;

      check(almost_full == 0, $sformatf("Expected almost_full=0, almost_full:%b", almost_full));

      @(posedge clk);

      // one more entry
      in_valid = 1;
      in_data  = 100;
      @(posedge clk);
      in_valid = 0;

      check(almost_full == 1, $sformatf("Expected almost_full=1, almost_full:%b", almost_full));
    end
  endtask

  //  Test 4 — Disabled FIFO streaming
  task automatic apb_disabled_fifo_streaming_test();
    $display("---  TEST 4 Configure Almost-Full Threshold ---");
    begin
      logic [ 7:0] addr = 8'h00;
      logic [31:0] wrdata = 0;

      // 1 write entry
      in_valid = 1;
      in_data  = 100;
      @(posedge clk);
      in_valid = 0;

      apb_write(.addr(addr), .data(wrdata));

      // setup empty threadhold = 0
      apb_write(.addr(8'h08), .data(0));
      @(posedge clk);

      // 1 more write entry
      in_valid = 1;
      in_data  = 100;
      @(posedge clk);
      in_valid = 0;

      check(almost_empty == 0, $sformatf("Expected almost_empty=0, almost_empty:%b", almost_empty));
    end
  endtask

  initial begin
    rst_n     = 0;

    paddr     = 0;
    psel      = 0;
    penable   = 0;
    pwrite    = 0;
    pwdata    = 0;

    in_valid  = 0;
    in_data   = 0;

    out_ready = 0;

    repeat (3) @(posedge clk);

    rst_n = 1;
    @(posedge clk);
    apb_register_write_read_test();
    apb_fifo_en_test();
    apb_almost_full_th_test();
    apb_disabled_fifo_streaming_test();
  end

endmodule
