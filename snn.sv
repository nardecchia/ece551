module SNN(clk, sys_rst_n, led, uart_tx, uart_rx);
		
	//*** Global params **//
	input clk;			      // 50MHz clock
	input sys_rst_n;			// Unsynched reset from push button. Needs to be synchronized.
	logic rst_n;				 // Synchronized active low reset
	output logic [7:0] led;	// Drives LEDs of DE0 nano board
	
	//** UART-Specific Params**//
	input uart_rx;
	output uart_tx;
	logic uart_rx_ff, uart_rx_synch;	//values for double-flopping
	logic rx_rdy;				//pass rx_rdy to ram as .we  AND snn_core as .start
	logic tx_rdy;				//pass tx_rdy to state machine to tell when uart_tx has sent data back to PC
	logic [7:0] rx_data;			// recieves data to pass to ram 

	//** SSN_CORE-specific Params**//
	logic q_input;				//data from RAM sent to ssn_core
	logic [9:0] addr_input_unit; 		//SSN_Core output / ram_input_unit input. Address of next input bit
	logic done; 				//signal end of process to this module to convert 4 bit number to ASCI LED Value
	logic [3:0] digit;			//value to be converted to ASCI LED Value


	//** SETUP STATE MACHINE **//
	typedef enum reg [1:0] {idle_state, uart_rx_state, snn_core_state, uart_tx_state} state_t;
	state_t state, next_state;
	reg [9:0] data_count; // counts the number of times rx_rdy recieves data before transitioning to snn_core_state
	reg start_ssn_core;

	/******************************************************
	Reset synchronizer
	******************************************************/
	rst_synch i_rst_synch(.clk(clk), .sys_rst_n(sys_rst_n), .rst_n(rst_n));
	
	/******************************************************
	UART
	******************************************************/
	// Double flop RX for meta-stability reasons
	always_ff @(posedge clk, negedge rst_n)
		if (!rst_n) begin
		uart_rx_ff <= 1'b1;
		uart_rx_synch <= 1'b1;
	end else begin
	  uart_rx_ff <= uart_rx;
	  uart_rx_synch <= uart_rx_ff;
	end
	

	//***NEW CODE*** instantiate ssn_core
	snn_core iDUT_ssn_core(.start(start_ssn_core), .q_input(q_input), .addr_input_unit(addr_input_unit), .digit(digit), .done(done), .clk(clk), .rst_n(rst_n));
				//     ^^^ this could be wrong. might need to make a module that fill RAM and outputs a signal when its full? 

	//*** instantiate ram
	ram_snn iDUT_ram(.data(rx_data), .addr(addr_input_unit), .we(rx_rdy), .clk(clk), .q(q_input));
	

	// Instantiate UART_RX and UART_TX and connect them below
	// For UART_RX, use "uart_rx_synch", which is synchronized, not "uart_rx".
	uart_rx iDUT_rx(.rx(uart_rx_synch), .rx_rdy(rx_rdy), .rx_data(rx_data), .clk(clk), .rst_n(rst_n));
	//*** may need to modify these
	uart_tx iDUT_tx(.tx(uart_tx), .tx_start(done), .tx_data(led), .tx_rdy(tx_rdy), .rst_n(rst_n), .clk(clk));
			
	/******************************************************
	LED
	******************************************************/

	// statement assigning LED to ASCII value based on SSN_Core output
	assign led = (digit == 4'h0) ? 8'h30:		 //ASCII 0 == 8'h30
		     (digit == 4'h1) ? 8'h31:
		     (digit == 4'h2) ? 8'h32:
		     (digit == 4'h3) ? 8'h33:
		     (digit == 4'h4) ? 8'h34:
		     (digit == 4'h5) ? 8'h35:
		     (digit == 4'h6) ? 8'h36:
		     (digit == 4'h7) ? 8'h37:
		     (digit == 4'h8) ? 8'h38:
		     (digit == 4'h9) ? 8'h39:
		      8'h00;		//default case, no LED's light up


// STATE MACHINE for this guy

always_comb begin
	data_count = 0;
	start_ssn_core = 0;
	next_state = idle_state;

	case (state)
		idle_state: begin
			if (uart_rx_synch == 1'b0) begin  //possible that this cycle will waste the start bit before it gets to uart module
				next_state = uart_rx_state;
			end else begin
				next_state = idle_state;
				data_count = 0;
			end
		end
		uart_rx_state: begin
			// increment data_count each time uart receives a byte
			if (rx_rdy == 1) begin   //maybe want if(rx_rdy == 1)
				data_count = data_count + 1;
			end 
			if (data_count == 784) begin  // data_count == 784 when each byte has been loaded into RAM
				next_state = snn_core_state;
				start_ssn_core = 1; 
			end else begin
				next_state = uart_rx_state;
			end
		end
		snn_core_state : begin
			if (done == 1) begin
				next_state = uart_tx_state;
			end else begin
				next_state = snn_core_state;
			end
		end
		default: begin           //uart_tx_state
			if(tx_rdy == 1) begin      //possibly unneccessary if we dont need to check if data has been sent
				next_state = idle_state;
				data_count = 0;
			end else begin
				next_state = uart_tx_state;
			end	
		end	
	endcase
end


/* state machine flop
*/
always @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		state <= idle_state;
	else
		state <= next_state;
end

endmodule
