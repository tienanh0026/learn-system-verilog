module sync_fifo #(
    parameter DEPTH = 8,
    parameter WIDTH = 8
) (
    input  logic             clk,
    input  logic             rst,
    input  logic             wr_en,
    input  logic             rd_en,
    input  logic [WIDTH-1:0] data_in,
    output logic [WIDTH-1:0] data_out,
    output logic             full,
    output logic             empty
);

  logic [WIDTH-1:0] queue[DEPTH-1:0];
  logic [2:0] wr_ptr;
  logic [2:0] rd_ptr;
  logic [3:0] count;  // needs to count up to 8, so 4 bits (0 to 8 needs 4 bits, not 3), count represent the number of item inside queue

  // ---- Sequential: pointers, memory writes, and item count ----
  always_ff @(posedge clk) begin
    if (rst) begin
      wr_ptr <= 3'b000;
      rd_ptr <= 3'b000;
      count  <= 4'b0000;
    end else begin
      // Write: only if requested AND not full
      if (wr_en && !full) begin
        queue[wr_ptr] <= data_in;
        wr_ptr        <= wr_ptr + 1;
      end

      // Read: only if requested AND not empty
      if (rd_en && !empty) begin
        rd_ptr <= rd_ptr + 1;
      end

      // Count: independent of pointers, tracks net change
      case ({
        wr_en && !full, rd_en && !empty
      })
        2'b10:   count <= count + 1;  // write only
        2'b01:   count <= count - 1;  // read only
        default: count <= count;  // both or neither -> no net change
      endcase
    end
  end

  // ---- Combinational: read data, status flags ----
  assign data_out = queue[rd_ptr];
  assign full     = (count == DEPTH);
  assign empty    = (count == 0);

endmodule
