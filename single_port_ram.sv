// Design a parameterized single-port RAM (parameterize data width and address width) 
// with one clock, a write-enable signal, and synchronous read — meaning the read address
// is registered, and the data output appears one clock cycle later, 
// not immediately (this is different from combinational/asynchronous read, 
// and it's the standard style used in real FPGA/ASIC block RAMs).

module single_port_ram #(
    parameter int DATA_WIDTH = 8,
    parameter int ADDR_WIDTH = 4
) (
    input logic clk,
    input logic rst,
    input logic we,
    input logic [ADDR_WIDTH-1:0] addr,
    input logic [DATA_WIDTH-1:0] data_in,
    output logic [DATA_WIDTH-1:0] data_out
);
  logic [DATA_WIDTH-1:0] mem[0:2**ADDR_WIDTH-1];

  always_ff @(posedge clk)
    if (rst) data_out <= '0;
    else begin
      data_out <= mem[addr];
      if (we) begin
        mem[addr] <= data_in;
      end
    end

endmodule
