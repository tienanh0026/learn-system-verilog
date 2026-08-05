
module up_down_counter (
	input logic clk,
	input logic rst,
	input logic load,
	input logic en,
	input logic dir,
	input logic [3:0] data_in,
	output logic [3:0] count
);
	always_ff @( posedge clk)
		if(rst) count <= 0;
		else if (load) count <= data_in;
		else if (en) begin
			if(dir) count <= count+1;
			else if (count) count <= count-1;
			else count <= count;
			end
		else count <= count;
endmodule