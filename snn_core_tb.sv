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


ram #(.DATA_WIDTH(1), .ADDR_WIDTH(10), .FILE_IN("sample_in/ram_input_contents_sample_9.txt"))
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
/*
always @(posedge clk) begin
	if (iDUT.state == iDUT.LAYER2) begin
		$display("HID # %d x OUT # %d = %d x %d = %d. ACC = %d", iDUT.count - 1, iDUT.node_count, iDUT.mac_a, iDUT.mac_b, iDUT.MAC0.mult, iDUT.MAC0.acc_nxt);
	end
end
always @(posedge clk) begin
	if (iDUT.state == iDUT.L2_MAC_CLR || iDUT.state == iDUT.L2_LUT_WRITE) begin
		$display("===================================");
		$display("LUT: #%d = f(%d) = %d\n", iDUT.node_count, iDUT.mac_out, iDUT.rom_lut_q);
	end
end*/

endmodule

