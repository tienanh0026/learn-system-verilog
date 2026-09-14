// `timescale 1ns / 1ps

// =====================================================================
// Testbench for Assignment 1: Flop-Based Synchronous FIFO
// with Valid/Ready Handshake Interface
//
// Structured to match the assignment's deliverables directly:
//   1) Overflow prevention   -> TEST A
//   2) Underflow prevention  -> TEST B
//   3) Data integrity & ordering under randomized backpressure -> TEST C
//
// DUT: module sync_fifo_test #(DATA_WIDTH, FIFO_DEPTH) (...)
// =====================================================================

module tb_sync_fifo_test_1;

  // -------------------------------------------------------------
  // Parameters
  // -------------------------------------------------------------
  localparam int DATA_WIDTH = 32;
  localparam int FIFO_DEPTH = 16;
  localparam int CLK_PERIOD = 10;

  // -------------------------------------------------------------
  // DUT signals
  // -------------------------------------------------------------
  logic clk, rst_n;
  logic in_valid, in_ready;
  logic [DATA_WIDTH-1:0] in_data;
  logic out_valid, out_ready;
  logic [DATA_WIDTH-1:0] out_data;
  logic full, empty;

  sync_fifo_test #(
      .DATA_WIDTH(DATA_WIDTH),
      .FIFO_DEPTH(FIFO_DEPTH)
  ) dut (
      .clk(clk),
      .rst_n(rst_n),
      .in_valid(in_valid),
      .in_data(in_data),
      .in_ready(in_ready),
      .out_ready(out_ready),
      .out_valid(out_valid),
      .out_data(out_data),
      .full(full),
      .empty(empty)
  );

  // -------------------------------------------------------------
  // Clock
  // -------------------------------------------------------------
  initial clk = 0;
  always #(CLK_PERIOD / 2) clk = ~clk;

  // -------------------------------------------------------------
  // Golden model: simple array + head/tail, mirrors an ideal FIFO
  // -------------------------------------------------------------
  logic [DATA_WIDTH-1:0] ref_mem[FIFO_DEPTH-1:0];

  int ref_head = 0, ref_tail = 0, ref_count = 0;

  function automatic void write_in(logic [DATA_WIDTH-1:0] d);
    ref_mem[ref_tail] = d;
    ref_tail = (ref_tail + 1) % FIFO_DEPTH;
    ref_count++;
  endfunction

  function automatic logic [DATA_WIDTH-1:0] read_out();
    logic [DATA_WIDTH-1:0] d = ref_mem[ref_head];
    ref_head = (ref_head + 1) % FIFO_DEPTH;
    ref_count--;
    return d;
  endfunction

  task automatic reset_dut();
    ref_head = 0;
    ref_tail = 0;
    ref_count = 0;
    rst_n = 0;
    in_valid = 0;
    in_data = 0;
    out_ready = 0;

    repeat (3) @(posedge clk);
    rst_n = 1;
    @(posedge clk);
  endtask

  function automatic void check(logic condition, string msg);
    if (!condition) begin
      $error("[%0t] FAIL: %s", $time, msg);
    end
  endfunction
  // -------------------------------------------------------------
  // Scoreboard: runs every cycle, checks handshakes against the
  // golden model. Covers data integrity + ordering automatically,
  // since it pops in the same order data was pushed.
  // -------------------------------------------------------------

  always @(posedge clk) begin

    if (rst_n) begin
      if (out_valid && out_ready) begin
        if (ref_count > 0) begin
          automatic logic [DATA_WIDTH-1:0] read_data = read_out();
          check(read_data == out_data, $sformatf(
                "data mismatch: got 0x%0h expected 0x%0h", out_data, read_data));
        end
      end
      if (in_valid && in_ready) begin
        write_in(in_data);
      end
      // @(posedge clk);
      #1
      check(
          full == (ref_count == FIFO_DEPTH),
          $sformatf(
              "full flag wrong, full = %0b, ref_count = %0b, FIFO_DEPTH = %0b",
              full,
              ref_count,
              FIFO_DEPTH
          ));
      check(empty == (ref_count == 0), $sformatf(
            "empty flag wrong, empty = %0b, ref_count = %0b", empty, ref_count));

    end
  end

  // =================================================================
  // TEST A — Overflow prevention
  // Fill the FIFO completely (reader off), then try one more write.
  // Requirement: in_ready must go to 0 and hold the extra data off.
  // =================================================================
  task automatic overflow_test();
    $display("--- TEST A: overflow prevention ---");
    reset_dut();

    for (int i = 0; i < FIFO_DEPTH; i++) begin
      @(posedge clk);
      in_data  = i;
      in_valid = 1;
    end

    @(posedge clk);
    check(full == 1, "FIFO should be full");
    check(in_ready == 0, $sformatf("In ready flag should be disabled, in_ready = %0b", in_ready));

    in_data  = 9;
    in_valid = 1;

    // one more write
    @(posedge clk);
    in_data  = 12;
    in_valid = 1;
    check(in_ready == 0, $sformatf(
          "In ready flag should be disabled (overflow blocked), in_ready = %0b", in_ready));
    @(negedge clk) in_valid = 0;
  endtask

  // =================================================================
  // TEST B — Underflow prevention
  // With an empty FIFO, assert out_ready and confirm no false read
  // handshake ever fires (out_valid must stay 0).
  // =================================================================
  task automatic underflow_test();
    $display("--- TEST B: underflow prevention ---");
    reset_dut();

    @(posedge clk);
    check(out_ready == 0, "Out ready flag must be disabled");
    check(out_valid == 0, "Out valid flag must be disabled");

  endtask



  // =================================================================
  // TEST C — Data integrity & ordering under randomized backpressure
  // Randomize in_valid and out_ready simultaneously; the scoreboard
  // (running every cycle above) checks order and content already.
  // =================================================================
  task automatic test_random_backpressure(int num_txns);
    int sent = 0;
    logic [DATA_WIDTH-1:0] wr_data = 0;

    $display("--- TEST C: randomized backpressure (%0d txns) ---", num_txns);
    reset_dut();

    fork
      // writer: random in_valid
      begin
        while (sent < num_txns) begin
          @(negedge clk);
          in_valid = ($urandom_range(0, 99) < 60);
          if (in_valid) begin
            wr_data += 1;
            in_data = wr_data;
          end
          @(posedge clk);
          if (in_valid && in_ready) sent++;
        end
        @(negedge clk) in_valid = 0;
      end
      begin
        while (sent < num_txns || ref_count > 0) begin
          @(negedge clk);
          out_ready = ($urandom_range(0, 99) < 60);
          @(posedge clk);
        end
        @(negedge clk) out_ready = 0;
      end
    join
  endtask

  // -------------------------------------------------------------
  // Main
  // -------------------------------------------------------------
  initial begin
    overflow_test();
    underflow_test();
    test_random_backpressure(50);
  end


endmodule
