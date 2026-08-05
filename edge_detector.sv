module edge_detector (
    input  logic clk,
    input  logic rst,
    input  logic sig_in,
    output logic pulse
);

  logic sig_in_d;

  always_ff @(posedge clk)
    if (rst) sig_in_d <= 0;
    else sig_in_d <= sig_in;

  assign pulse = sig_in && !sig_in_d;

endmodule
