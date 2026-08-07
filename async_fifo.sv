module async_fifo #(
    parameter int DATA_WIDTH = 8,
    parameter int ADDR_WIDTH = 4
) (
    input logic wr_clk,
    input logic rd_clk,

    input logic wr_rst,
    input logic rd_rst,

    input logic rd_en,
    input logic wr_en,
    input logic [DATA_WIDTH-1:0] data_in,
    output logic [DATA_WIDTH-1:0] data_out,
    output logic full,
    output logic empty
);
  //
  logic [  ADDR_WIDTH:0] rd_ptr_gray;
  logic [  ADDR_WIDTH:0] wr_ptr_gray;

  logic [ADDR_WIDTH-1:0] wr_addr;
  logic [ADDR_WIDTH-1:0] rd_addr;

  async_fifo_mem #(
      .DATA_WIDTH(DATA_WIDTH),
      .DEPTH(2 ** ADDR_WIDTH)
  ) mem_inst (
      .wr_clk (wr_clk),
      .wr_en  (wr_en && !full),
      .wr_addr(wr_addr),
      .wr_data(data_in),

      .rd_addr(rd_addr),
      .rd_data(data_out)
  );


  async_fifo_write #(
      .ADDR_WIDTH(ADDR_WIDTH)
  ) wr_inst (
      .wr_clk(wr_clk),
      .wr_rst(wr_rst),

      .wr_en(wr_en),
      .rd_ptr_gray(rd_ptr_gray),
      .wr_addr(wr_addr),
      .wr_ptr_gray(wr_ptr_gray),
      .full(full)
  );

  async_fifo_read #(
      .ADDR_WIDTH(ADDR_WIDTH)
  ) rd_inst (
      .rd_clk(rd_clk),
      .rd_rst(rd_rst),

      .rd_en(rd_en),
      .wr_ptr_gray(wr_ptr_gray),
      .rd_ptr_gray(rd_ptr_gray),
      .rd_addr(rd_addr),
      .empty(empty)
  );

endmodule

module async_fifo_mem #(
    parameter int DATA_WIDTH = 8,
    parameter int DEPTH = 16
) (
    // Write port
    input logic wr_clk,
    input logic wr_en,
    input logic [$clog2(DEPTH)-1:0] wr_addr,
    input logic [DATA_WIDTH-1:0] wr_data,
    // Read port
    input logic [$clog2(DEPTH)-1:0] rd_addr,
    output logic [DATA_WIDTH-1:0] rd_data
);
  logic [DATA_WIDTH-1:0] mem[DEPTH-1:0];
  always_ff @(posedge wr_clk) if (wr_en) mem[wr_addr] <= wr_data;

  assign rd_data = mem[rd_addr];
endmodule


// Write Domain Logic

// This is the more complex half of the async FIFO — it contains:

// 1.The binary write pointer (actual address into the memory)
// 2.The Gray-coded write pointer (for safe CDC crossing to the read domain)
// 3.The synchronized read pointer (received from the read domain via double-flop)
// 4.Full detection logic

module async_fifo_write #(
    parameter int ADDR_WIDTH = 4
) (
    input  logic                  wr_clk,
    input  logic                  wr_rst,
    input  logic                  wr_en,
    input  logic [  ADDR_WIDTH:0] rd_ptr_gray,  // from read domain
    output logic [ADDR_WIDTH-1:0] wr_addr,      // to memory
    output logic [  ADDR_WIDTH:0] wr_ptr_gray,  // to read domain
    output logic                  full
);
  logic [ADDR_WIDTH:0] wr_ptr_bin;
  logic [ADDR_WIDTH:0] rd_ptr_gray_sync1, rd_ptr_gray_sync2;

  assign wr_addr = wr_ptr_bin[ADDR_WIDTH-1:0];

  always_ff @(posedge wr_clk)
    if (wr_rst) wr_ptr_bin <= 0;
    else if (wr_en && !full) wr_ptr_bin <= wr_ptr_bin + 1;

  assign wr_ptr_gray = wr_ptr_bin ^ (wr_ptr_bin >> 1);

  always_ff @(posedge wr_clk) begin
    if (wr_rst) begin
      rd_ptr_gray_sync1 <= 0;
      rd_ptr_gray_sync2 <= 0;

    end else begin
      rd_ptr_gray_sync1 <= rd_ptr_gray;
      rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
    end
  end

  assign full =
    (wr_ptr_gray[ADDR_WIDTH]     != rd_ptr_gray_sync2[ADDR_WIDTH])   &&
    (wr_ptr_gray[ADDR_WIDTH-1]   != rd_ptr_gray_sync2[ADDR_WIDTH-1]) &&
    (wr_ptr_gray[ADDR_WIDTH-2:0] == rd_ptr_gray_sync2[ADDR_WIDTH-2:0]);

endmodule


// 1.The binary write pointer (actual address into the memory)
// 2.The Gray-coded write pointer (for safe CDC crossing to the read domain)
// 3.The synchronized read pointer (received from the read domain via double-flop)
// 4.Full detection logic

module async_fifo_read #(
    parameter int ADDR_WIDTH = 4
) (
    input logic rd_clk,
    input logic rd_rst,
    input logic rd_en,
    input logic [ADDR_WIDTH : 0] wr_ptr_gray,
    output logic [ADDR_WIDTH : 0] rd_ptr_gray,
    output logic [ADDR_WIDTH-1:0] rd_addr,
    output logic empty
);
  logic [ADDR_WIDTH:0] rd_ptr_bin;
  logic [ADDR_WIDTH:0] wr_ptr_gray_sync1, wr_ptr_gray_sync2;

  assign rd_addr = rd_ptr_bin[ADDR_WIDTH-1:0];
  // Increase pointer when read sucess
  always_ff @(posedge rd_clk)
    if (rd_rst) rd_ptr_bin <= 0;
    else if (rd_en && !empty) rd_ptr_bin <= rd_ptr_bin + 1;
  // convert to gray code pointer
  assign rd_ptr_gray = rd_ptr_bin ^ (rd_ptr_bin >> 1);

  // add double ff to safe the write pointer prevent cross domain clock
  always_ff @(posedge rd_clk)
    if (rd_rst) begin
      wr_ptr_gray_sync1 <= 0;
      wr_ptr_gray_sync2 <= 0;
    end else begin
      wr_ptr_gray_sync1 <= wr_ptr_gray;
      wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
    end

  assign empty = (rd_ptr_gray == wr_ptr_gray_sync2);

endmodule
