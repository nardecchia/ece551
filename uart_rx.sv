module uart_rx(rx, rx_rdy, rx_data, clk, rst_n);
input rx, clk, rst_n;
output reg rx_rdy;
output [7:0] rx_data;

typedef enum reg [1:0] {IDLE, LEAD, RX, TAIL} state_t;
state_t state, next_state;
// number of clock cycles per baud
localparam HALF_BAUD = 12'h516;		// 1302 decimal
localparam BAUD 	 = 12'hA2C;		// 2604 decimal

reg [11:0] baud_cnt;		// for counting baud cycles
reg [3:0] bit_cnt;			// for counting number of bits received
reg [7:0] shift_reg;

reg shift_in;
reg clr_bit, incr_bit;
reg clr_baud;

wire baud, half_baud;

/* state machine logic
*/
always_comb begin
	rx_rdy = 0;
	next_state = IDLE;
	clr_baud = 0;
	clr_bit = 0;
	incr_bit = 0;
	shift_in = 0;

	case (state)
		IDLE: begin
			if (rx == 1'b0) begin
				next_state = LEAD;
			end else begin
				next_state = IDLE;
				clr_baud = 1;
				clr_bit = 1;
			end
		end
		LEAD: begin
			// wait for a half baud before moving to the next state
			if (half_baud) begin
				next_state = RX;
				clr_bit = 1;
				clr_baud = 1;
			end else begin
				next_state = LEAD;
			end
		end
		RX: begin
			if (baud) begin
				clr_baud = 1;
				if (bit_cnt == 4'h8) begin
					next_state = TAIL;
					if (rx == 1'b1)
						rx_rdy = 1;
					else
						rx_rdy = 0;
				end else begin
					next_state = RX;
					incr_bit = 1;
					shift_in = 1;
				end
			end else begin
				next_state = RX;
			end
		end
		default: begin		// TAIL state
			if (half_baud) begin
				next_state = IDLE;
				clr_baud = 1;
				clr_bit = 1;
			end else begin
				next_state = TAIL;
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

assign half_baud = (baud_cnt == HALF_BAUD) ? 1'b1 : 1'b0;
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
		shift_reg <= 0;
	else begin
		if (shift_in)
			shift_reg <= {rx, shift_reg[7:1]};
		else
			shift_reg <= shift_reg;
	end
end

assign rx_data = shift_reg;

endmodule
