module snn_tb();

reg clk, sys_rst_n, uart_rx, tx_start;

wire [7:0] q;
wire [7:0] coreOutput;

wire uart_tx, tx_rdy, rx_rdy;
wire [7:0] led;
logic [9:0] addr_input;


snn iDUT1(clk, sys_rst_n, coreOutput, uart_tx, tx);

uart_tx iDUT2(tx, tx_start, q, tx_rdy, rst_n, clk);

uart_rx iDUT3(uart_tx, rx_rdy, led, clk, rst_n);

ram #(.DATA_WIDTH(1), .ADDR_WIDTH(10), .FILE_IN("sample_in/ram_input_contents_sample_0.txt"))
	input_unit(.data(1'b0), .addr(addr_input),
				.we(1'b0), .q(q), .clk(clk));


initial begin

  clk = 0;
  sys_rst_n = 0;
  tx_start = 1;

  #1 sys_rst_n = 1;
  addr_input = 0;

  for (int i = 0; i < 784; i++) begin

  tx_start = 0;

  repeat (2604 * 10)  @(posedge clk) ;
  addr_input = addr_input + 1;

  tx_start = 1;

  #2;
  end

  




end 

always 
 #1 clk = ~clk;

endmodule 
