module alu (
    input logic [3:0] a,
    input logic [3:0] b,
    input logic [2:0] op,
    output logic [3:0] result,
    output logic zero  // high when result == 0
);

  always_comb begin : alu
    case (op)
      (3'b000): result = a + b;
      (3'b001): result = a - b;
      (3'b010): result = a & b;
      (3'b011): result = a | b;
      (3'b100): result = a ^ b;
      (3'b101): result = ~a;

      default: result = 0;
    endcase

    zero = result == 0;

  end

endmodule
