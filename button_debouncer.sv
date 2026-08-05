module button_debouncer #(
    parameter int COUNTER = 3
) (
    input  logic clk,
    input  logic rst,
    input  logic data_in,
    output logic en
);
  int   cnt = 0;
  logic data_in_d;
  always_ff @(posedge clk)
    if (rst) begin
      cnt <= 0;
      en  <= 0;
    end else begin
      data_in_d <= data_in;
      if (data_in != data_in_d) begin
        en  <= 0;
        cnt <= 0;
      end else if (cnt < COUNTER) cnt <= cnt + 1;
      else en <= 1;
    end
endmodule
