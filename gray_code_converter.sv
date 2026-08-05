module binary_to_gray_converter #(
    parameter int WIDTH = 4
) (
    input  logic [WIDTH-1:0] binary,
    output logic [WIDTH-1:0] gray
);

  always_comb begin
    for (int i = WIDTH - 1; i >= 0; i = i - 1) begin
      if (i == WIDTH - 1) gray[i] = binary[i];
      else gray[i] = binary[i] ^ binary[i+1];
    end
  end

endmodule

module gray_to_binary_converter #(
    parameter int WIDTH = 4
) (
    input  logic [WIDTH-1:0] gray,
    output logic [WIDTH-1:0] binary
);

  always_comb begin
    for (int i = WIDTH - 1; i >= 0; i = i - 1) begin
      if (i == WIDTH - 1) binary[i] = gray[i];
      else binary[i] = gray[i] ^ binary[i+1];
    end
  end

endmodule
