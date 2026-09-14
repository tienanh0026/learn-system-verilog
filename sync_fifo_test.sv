module sync_fifo_test #(
    parameter DATA_WIDTH = 32,
    parameter FIFO_DEPTH = 16
) (
    input logic clk,
    input logic rst_n,

    // Write port
    input logic in_valid,
    input logic [DATA_WIDTH-1:0] in_data,
    output logic in_ready,

    // Read port
    input logic out_ready,
    output logic out_valid,
    output logic [DATA_WIDTH-1:0] out_data,

    // Status flags
    output logic full,
    output logic empty,

    // Count flags
    output logic [$clog2(FIFO_DEPTH):0] count
);
  localparam int BIT_NUM = $clog2(FIFO_DEPTH);

  logic [DATA_WIDTH-1:0] mem[FIFO_DEPTH-1:0];

  logic [BIT_NUM:0] wr_ptr;
  logic [BIT_NUM:0] rd_ptr;

  // Write operation
  always_ff @(posedge clk or negedge rst_n) begin : Write_Operation
    if (!rst_n) wr_ptr <= 0;
    else begin
      if (in_ready && in_valid) begin
        mem[wr_ptr[BIT_NUM-1:0]] <= in_data;
        wr_ptr <= wr_ptr + 1;
      end
    end
  end

  // Read operation
  always_ff @(posedge clk or negedge rst_n) begin : Read_Operation
    if (!rst_n) rd_ptr <= 0;
    else begin
      if (out_ready && out_valid) begin
        rd_ptr <= rd_ptr + 1;
      end
    end
  end

  assign out_data = mem[rd_ptr[BIT_NUM-1:0]];

  assign full = (wr_ptr[BIT_NUM] != rd_ptr[BIT_NUM]) && (wr_ptr[BIT_NUM-1:0] == rd_ptr[BIT_NUM-1:0]);
  assign in_ready = !(full) || (out_valid && out_ready);

  assign empty = (wr_ptr == rd_ptr);
  assign out_valid = !empty;

  assign count = wr_ptr - rd_ptr;

endmodule
