
module up_counter (
    input  logic       clk,
    input  logic       rst,
    input  logic       en,
    output logic [3:0] count,
    output logic       tc
);
  assign tc = (count == 15);
  always_ff @(posedge clk)
    if (rst) count <= 0;
    else if (en) count <= count + 1;
    else count <= count;

endmodule
