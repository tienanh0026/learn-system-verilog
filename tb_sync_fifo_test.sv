
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

module tb_sync_fifo_test;

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
      .*
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
  int error_cnt = 0;

  function automatic void ref_push(logic [DATA_WIDTH-1:0] d);
    ref_mem[ref_tail] = d;
    ref_tail = (ref_tail + 1) % FIFO_DEPTH;
    ref_count++;
  endfunction

  function automatic logic [DATA_WIDTH-1:0] ref_pop();
    logic [DATA_WIDTH-1:0] d = ref_mem[ref_head];
    ref_head = (ref_head + 1) % FIFO_DEPTH;
    ref_count--;
    return d;
  endfunction

  function automatic void check(bit cond, string msg);
    if (!cond) begin
      error_cnt++;
      $error("[%0t] FAIL: %s", $time, msg);
    end
  endfunction

  task automatic reset_dut();
    rst_n = 0;
    in_valid = 0;
    in_data = '0;
    out_ready = 0;
    ref_head = 0;
    ref_tail = 0;
    ref_count = 0;
    repeat (3) @(posedge clk);
    rst_n = 1;
    @(posedge clk);
  endtask

  // -------------------------------------------------------------
  // Scoreboard: runs every cycle, checks handshakes against the
  // golden model. Covers data integrity + ordering automatically,
  // since it pops in the same order data was pushed.
  // -------------------------------------------------------------
  always @(posedge clk) begin
    if (rst_n) begin
      if (out_valid && out_ready) begin
        check(ref_count > 0, "read handshake happened but FIFO should be empty (underflow)");
        if (ref_count > 0) begin
          static logic [DATA_WIDTH-1:0] exp = ref_pop();
          check(out_data === exp, $sformatf("data mismatch: got 0x%0h expected 0x%0h", out_data, exp
                ));
        end
      end
      if (in_valid && in_ready) ref_push(in_data);

      check(full == (ref_count == FIFO_DEPTH), "full flag wrong");
      check(empty == (ref_count == 0), "empty flag wrong");
    end
  end

  // =================================================================
  // TEST A — Overflow prevention
  // Fill the FIFO completely (reader off), then try one more write.
  // Requirement: in_ready must go to 0 and hold the extra data off.
  // =================================================================
  task automatic test_overflow();
    $display("--- TEST A: overflow prevention ---");
    reset_dut();
    out_ready = 0;

    for (int i = 0; i < FIFO_DEPTH; i++) begin
      @(negedge clk);
      in_valid = 1;
      in_data  = i;
      @(posedge clk);
    end
    @(negedge clk) in_valid = 0;
    @(posedge clk);

    check(full == 1, "FIFO should be full after writing FIFO_DEPTH items");
    check(in_ready == 0, "in_ready should be 0 when full");

    // attempt an extra write while full — must be held off
    @(negedge clk);
    in_valid = 1;
    in_data  = 32'hDEAD_BEEF;
    @(posedge clk);
    check(in_ready == 0, "in_ready must stay 0 while full (overflow blocked)");
    @(negedge clk) in_valid = 0;
  endtask

  // =================================================================
  // TEST B — Underflow prevention
  // With an empty FIFO, assert out_ready and confirm no false read
  // handshake ever fires (out_valid must stay 0).
  // =================================================================
  task automatic test_underflow();
    $display("--- TEST B: underflow prevention ---");
    reset_dut();
    check(empty == 1, "FIFO should be empty right after reset");

    out_ready = 1;
    repeat (5) @(posedge clk);
    check(out_valid == 0, "out_valid must stay 0 on an empty FIFO (no false read)");
    out_ready = 0;
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
      // reader: random out_ready, runs until everything sent is drained
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
    test_overflow();
    test_underflow();
    test_random_backpressure(50);

    repeat (5) @(posedge clk);
    $display("=====================================");
    if (error_cnt == 0) $display("RESULT: PASS");
    else $display("RESULT: FAIL (%0d errors)", error_cnt);
    $display("=====================================");
    $finish;
  end

  initial begin
    #(CLK_PERIOD * 20000);
    $error("TIMEOUT");
    $finish;
  end

endmodule
