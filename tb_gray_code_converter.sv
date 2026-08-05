module tb_gray_code_converter;
  logic [3:0] binary_in;
  logic [3:0] gray_out;
  logic [3:0] binary_back;
  binary_to_gray_converter dut1 (
      .binary(binary_in),
      .gray  (gray_out)
  );
  gray_to_binary_converter dut2 (
      .binary(binary_back),
      .gray  (gray_out)
  );

  initial begin
    for (int i = 0; i < 16; i++) begin
      binary_in = i;
      #10;
      if (binary_back == binary_in)
        $display(
            "Success: binary_in=%0d, gray_out=%b, binary_back=%0d", binary_in, gray_out, binary_back
        );
      else
        $display(
            "FAILED: binary_in=%0d, gray_out=%b, binary_back=%0d", binary_in, gray_out, binary_back
        );
    end
    $finish;
  end


endmodule
