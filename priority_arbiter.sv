// Priority Arbiter
// Design a 4-input fixed-priority arbiter: given 4 request signals (req[3:0]), 
// output a one-hot grant signal (grant[3:0]) 
// where lower-indexed requests always win over higher-indexed ones 
// when multiple are asserted simultaneously. 
// Combinational logic only.

module priority_arbiter #(
    parameter int WIDTH = 4
) (
    input  logic [WIDTH-1:0] req,
    output logic [WIDTH-1:0] grant
);
  always_comb begin
    grant = 4'b0000;
    for (int i = 0; i < WIDTH; i = i + 1) begin
      if (req[i] && grant == 0) begin
        grant[i] = 1;
      end
    end
  end

endmodule
