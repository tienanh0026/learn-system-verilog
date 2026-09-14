module apb_slave #(
    parameter DATA_WIDTH = 32,
    parameter FIFO_DEPTH = 16
) (
    input logic pclk,
    input logic prst_n,
    // Port to/from Master APB
    input logic [7:0] paddr,
    input logic pwrite,
    input logic psel,
    input logic penable,
    input logic [DATA_WIDTH-1:0] pwdata,

    output logic pready,
    output logic [DATA_WIDTH-1:0] prdata,

    // Port to/from Sync FIFO
    input logic full,
    input logic empty,
    input logic [$clog2(FIFO_DEPTH):0] count,

    output logic fifo_en,
    output logic fifo_flush,
    output logic almost_empty,
    output logic almost_full

);
  localparam COUNT_WIDTH = $clog2(FIFO_DEPTH + 1);

  localparam CTRL = 8'h0;
  localparam AFULL_TH = 8'h04;
  localparam AEMPTY_TH = 8'h08;
  localparam STATUS = 8'h0c;
  localparam LEVEL = 8'h10;  // current element count 

  logic [DATA_WIDTH-1:0] ctrl_reg;
  logic [DATA_WIDTH-1:0] afull_th_reg;
  logic [DATA_WIDTH-1:0] aempty_th_reg;

  always_ff @(posedge pclk, negedge prst_n) begin : WRITE
    if (!prst_n) begin
      ctrl_reg = '0;
      afull_th_reg = '0;
      aempty_th_reg = '0;
    end else begin
      fifo_flush = 1'b0;

      if (psel && penable && pwrite)
        case (paddr)
          CTRL: begin
            ctrl_reg <= pwdata;
            if (pwdata[1]) fifo_flush <= 1'b1;
          end
          AFULL_TH:  afull_th_reg <= pwdata;
          AEMPTY_TH: aempty_th_reg <= pwdata;
        endcase
    end
  end

  assign fifo_en = ctrl_reg[0];

  assign almost_empty = (count <= aempty_th_reg[COUNT_WIDTH-1:0]);
  assign almost_full = (count >= afull_th_reg[COUNT_WIDTH-1:0]);

  always_comb begin : READ
    prdata = '0;
    pready = 1'b1;  // Only handle in 1 cycle
    if (psel && penable && !pwrite)
      case (paddr)
        CTRL: prdata = ctrl_reg;
        AFULL_TH: prdata = afull_th_reg;
        AEMPTY_TH: prdata = aempty_th_reg;
        STATUS: prdata = {28'b0, almost_empty, almost_full, empty, full};
        LEVEL: prdata = count;
        default: prdata = '0;
      endcase
  end


endmodule
