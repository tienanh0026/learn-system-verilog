
module tb_up_down_counter;
	 logic clk;
	 logic rst;
	 logic load;
	 logic en;
	 logic dir;
	 logic [3:0] data_in;
	logic [3:0] count;
	up_down_counter dut(
		.clk(clk),
		.rst(rst),
		.load(load),
		.en(en),
		.dir(dir),
		.data_in(data_in),
		.count(count)
	);

	
    	// Clock generation: 10ns period
    	initial clk = 0;
    	always #5 clk = ~clk;

    // Stimulus
    initial begin
        rst = 1; en = 0;
        @(posedge clk);
        @(posedge clk);
        rst = 0; en = 1;
		
	load = 1;
	data_in = 8;
        repeat (3) @(posedge clk); 

	data_in = 10;
        repeat (3) @(posedge clk); 

        en = 1;
	load = 0;
	dir = 0;
        repeat (2) @(posedge clk);  
	dir = 1;
        repeat (4) @(posedge clk);  
	dir = 0;
        repeat (3) @(posedge clk);  


        en = 0;
        repeat (5) @(posedge clk);

        $stop;  // end simulation
    end

    // Optional: print each cycle
    initial begin
       $monitor("1");
    end

endmodule
		