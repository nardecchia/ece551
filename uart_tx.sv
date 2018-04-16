module uart_tx(tx, tx_start, tx_data, tx_rdy, rst_n, clk);
input tx_start, rst_n, clk;
input [7:0] tx_data;
output reg tx;
output reg tx_rdy;

typedef enum reg {IDLE, TX} state_t;
state_t state, next_state;

localparam BAUD = 12'hA2C;		// 2604 decimal

reg [9:0] shift_tx;
reg [3:0] bit_cnt;
reg [11:0] baud_cnt;

reg shift_out;
reg clr_bit, incr_bit;
reg clr_baud;
wire baud;

//assign tx = shift_tx[0];

/* state machine logic
*/
always_comb begin
	tx_rdy 		= 1;
	next_state 	= IDLE;
	clr_baud 	= 0;
	clr_bit 	= 0;
	incr_bit	= 0;
	shift_out	= 0;
	tx			= 1;

	case (state)
		IDLE: begin
			if (tx_start)
				next_state = TX;
			else begin
				next_state = IDLE;
				clr_baud = 1;
				clr_bit = 1;
			end
		end

		default: begin			// TX state
			tx = shift_tx[0];
			tx_rdy = 0;
			if (baud) begin
				clr_baud = 1;
				if (bit_cnt == 4'h9) begin
					next_state = IDLE;
					clr_bit = 1;
				end else begin
					next_state = TX;
					incr_bit = 1;
					shift_out = 1;
				end
			end else begin
				next_state = TX;
			end
		end
	endcase
end

/* state machine flop
*/
always @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		state <= IDLE;
	else
		state <= next_state;
end

/* baud counter
*/
always @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		baud_cnt <= 0;
	else begin
		if (clr_baud)
			baud_cnt <= 0;
		else
			baud_cnt <= baud_cnt + 12'h1;
	end
end

assign baud = (baud_cnt == BAUD) ? 1'b1 : 1'b0;

/* received bit counter
*/
always @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		bit_cnt <= 0;
	else begin
		if (clr_bit)
			bit_cnt <= 0;
		else if (incr_bit)
			bit_cnt <= bit_cnt + 4'h1;
		else
			bit_cnt <= bit_cnt;
	end
end

/* shift register
*/
always @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		shift_tx <= 0;
	else begin
		if (tx_start)
			shift_tx <= {1'b1, tx_data, 1'b0};
		else if (shift_out)
			shift_tx <= {1'b0, shift_tx[9:1]};
		else
			shift_tx <= shift_tx;
	end
end


endmodule
