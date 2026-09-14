module apb_slave #(
    parameter DATA_WIDTH = 32,
    parameter FIFO_DEPTH = 16
) (
    input logic clk,
    input logic rst_n,
    // Port to/from Master APB
    input logic [7:0] paddr,
    input logic pwrite,
    input logic psel,
    input logic penable,
    input logic [DATA_WIDTH-1:0] pwdata,

    output logic pready,
    output logic [DATA_WIDTH-1:0] prdata,

    // Port to/from Sync FIFO
    output logic rst_n,
    output logic in_valid,
    output logic [DATA_WIDTH-1:0] in_data,
    input logic in_ready,

    output logic out_ready,
    input logic out_valid,
    input logic [DATA_WIDTH-1:0] out_data,
    input logic full,
    input logic empty,
    input logic [$clog2(FIFO_DEPTH):0] count
);

  localparam CTRL = 8'h0;
  localparam AFULL_TH = 8'h04;
  localparam AEMPTY_TH = 8'h08;
  localparam STATUS = 8'h0c;
  localparam LEVEL = 8'h10;  // current element count 

  logic [DATA_WIDTH-1:0] ctrl_reg;
  logic [DATA_WIDTH-1:0] afull_th_reg;
  logic [DATA_WIDTH-1:0] aempty_th_reg;
  logic [DATA_WIDTH-1:0] level_reg;


  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      ctrl_reg <= '0;
      afull_th_reg <= '0;
      aempty_th_reg <= '0;
      level_reg <= '0;
    end
    if (psel && penable)
      case (paddr)
        CTRL: begin
          if (pwrite) ctrl_reg <= pwdata;
          else begin
            prdata <= ctrl_reg;
            if (ctrl_reg[0]) in_valid <= 1;
            else in_valid <= 0;
            if (ctrl_reg[1]) rst_n <= 0;
            else rst_n <= 1;
          end
        end
        AFULL_TH: begin
          if (pwrite) afull_th_reg <= pwdata;
          else prdata <= afull_th_reg;
        end

        AEMPTY_TH: begin
          if (pwrite) aempty_th_reg <= pwdata;
          else prdata <= aempty_th_reg;
        end

        STATUS: begin
          if (pwrite) status_reg <= pwdata;
          else begin
            almost_empty <= (count <= aempty_th_reg[$clog2(FIFO_DEPTH):0]);
            almost_full <= (count >= afull_th_reg[$clog2(FIFO_DEPTH):0]);
            prdata <= {almost_empty, almost_full, empty, full};
          end
        end

        LEVEL: begin
          if (!pwrite) prdata <= count;
        end
      endcase
  end

endmodule

module sync_fifo_apb_top #(
    parameter DATA_WIDTH = 32,
    parameter FIFO_DEPTH = 16
) (
    input logic clk,
    input logic rst_n,

    input logic paddr,
    input logic psel,
    input logic penable,
    input logic pwrite,
    input logic [DATA_WIDTH-1:0] pwdata,
    input logic in_valid,
    input logic in_ready,


    output logic out_valid,
    output logic out_ready,
    output logic almost_full,
    output logic almost_empty
);

  logic [$clog2(FIFO_DEPTH):0] count;
  logic pwrite;
  logic internal_rst_n;

  // assign internal_rst_n

  sync_fifo_test #(
      .FIFO_DEPTH(FIFO_DEPTH),
      .DATA_WIDTH(DATA_WIDTH)
  ) sync_fifo (
      .clk(clk),
      .rst_n(rst_n),
      .in_valid(in_valid),
      .in_ready(in_ready),
      .out_ready(out_ready),
      .out_valid(out_valid),
      .out_data(out_data),
      .full(full),
      .empty(empty),
      .count(count)
  );
  apb_slave #(
      .FIFO_DEPTH(FIFO_DEPTH),
      .DATA_WIDTH(DATA_WIDTH)
  ) apb_slave (
      .paddr(paddr),
      .pwrite(pwrite),
      .psel(psel),
      .penable(penable),
      .pwdata(pwdata),
      .rst_n(n),
      .in_valid(in_valid),
      .in_ready(in_ready),
      .count(count)
  );

endmodule
