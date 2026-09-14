
module sync_fifo_apb_top #(
    parameter DATA_WIDTH = 32,
    parameter FIFO_DEPTH = 16
) (
    input logic clk,
    input logic rst_n,

    // Slave
    input logic [7:0] paddr,
    input logic psel,
    input logic penable,
    input logic pwrite,
    input logic [DATA_WIDTH-1:0] pwdata,
    output logic [DATA_WIDTH-1:0] prdata,
    output logic pready,

    // Fifo 
    input logic in_valid,
    input logic [DATA_WIDTH-1:0] in_data,
    input logic out_ready,
    output logic in_ready,
    output logic out_valid,
    output logic [DATA_WIDTH-1:0] out_data,

    output logic almost_full,
    output logic almost_empty
);

  logic [$clog2(FIFO_DEPTH):0] count;
  logic empty, full;

  logic fifo_en, fifo_flush;

  // APB register 
  apb_slave #(
      .FIFO_DEPTH(FIFO_DEPTH),
      .DATA_WIDTH(DATA_WIDTH)
  ) apb_slave (
      .pclk(clk),
      .prst_n(rst_n),
      .paddr(paddr),
      .pwrite(pwrite),
      .psel(psel),
      .penable(penable),
      .pwdata(pwdata),
      .prdata(prdata),
      .pready(pready),
      .full(full),
      .empty(empty),
      .count(count),
      .fifo_en(fifo_en),
      .fifo_flush(fifo_flush),
      .almost_full(almost_full),
      .almost_empty(almost_empty)
  );
  // FIFO
  sync_fifo_test #(
      .FIFO_DEPTH(FIFO_DEPTH),
      .DATA_WIDTH(DATA_WIDTH)
  ) sync_fifo (
      .clk(clk),
      .rst_n(rst_n),
      .in_valid(fifo_en && in_valid),
      .in_data(in_data),
      .in_ready(in_ready),
      .out_ready(out_ready),
      .out_valid(out_valid),
      .out_data(out_data),
      .full(full),
      .empty(empty),
      .count(count)
  );



endmodule
