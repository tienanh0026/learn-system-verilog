module edge_detector_both (
    input  logic clk,
    input  logic rst,
    input  logic sig_in,
    output logic pulse_fall,
    output logic pulse_any
);
  logic sig_in_d;
  always_ff @(posedge clk)
    if (rst) sig_in_d <= 0;
    else sig_in_d <= sig_in;

  assign pulse_fall = sig_in_d & ~sig_in;
  assign pulse_any  = sig_in ^ sig_in_d;
endmodule
