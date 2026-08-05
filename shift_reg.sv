module shift_reg (
    input logic clk,
    input logic rst,
    input logic en,
    input logic dir,
    input logic serial_in,
    output logic [3:0] data,
    output logic serial_out
);
  assign serial_out = dir ? data[3] : data[0];

  always_ff @(posedge clk)
    if (rst) begin
      data <= 4'b0000;
    end else if (en) begin
      if (dir) begin
        data <= {data[2:0], serial_in};
      end else begin
        data <= {serial_in, data[3:1]};
      end
    end else begin
      data <= data;
    end

endmodule
