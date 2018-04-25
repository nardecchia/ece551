module snn_core_tb();
reg clk, rst_n;

initial begin
	clk = 0;
	forever
		#5 clk = ~clk;
end

reg start;
wire done, q;
wire [3:0] digit;
wire [9:0] addr_input;
snn_core iDUT(.start(start), .q_input(q), .addr_input_unit(addr_input), .digit(digit), .done(done), .clk(clk), .rst_n(rst_n));


ram #(.DATA_WIDTH(1), .ADDR_WIDTH(10), .FILE_IN("sample_in/ram_input_contents_sample_0.txt"))
	input_unit(.data(1'b0), .addr(addr_input),
				.we(1'b0), .q(q), .clk(clk));

initial begin
	rst_n = 0;
	start = 0;
	#10;
	rst_n = 1;
	start = 1;
	#10
	start = 0;
	@(posedge done)
	;
	$display("digit: %h", digit);
	$stop();
end

endmodule

