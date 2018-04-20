module snn_core(start, q_input, addr_input_unit, digit, done, clk, rst_n);
input start, q_input;
input clk, rst_n;
output [9:0] addr_input_unit;
output reg [3:0] digit;
output reg done;

/* wires and registers */
wire count_L1, count_L2;		// counters for state transitions
reg [9:0] count;
reg [5:0] node_count;
reg clr_count, inc_ncount, clr_ncount;
wire [3:0] digit_logic;
wire [7:0] sext_q;
wire[7:0] mac_a, mac_b;
wire[10:0] mac_out;
reg mac_clr_n;

reg [4:0] ram_h_addr;
reg [3:0] ram_o_addr;
reg ram_h_we, ram_o_we;
wire [7:0] ram_h_q, ram_o_q;
wire [14:0] rom_hw_addr;
reg [8:0] rom_ow_addr;
wire [7:0] rom_hw_q, rom_ow_q, rom_lut_q;

/* State definiitons */
typedef enum reg [3:0] {IDLE, LAYER1, L1_MAC_CLR, L1_LUT_WRITE, L1_L2_BUFFER, LAYER2, OUTPUT} state_t;
state_t state, next_state;

/* counting logic */
assign count_L1 = (count == 10'h310) ? 1'b1 : 1'b0;			// 0x310 is 784
assign count_L2 = (count == 10'h20) ? 1'b1 : 1'b0;			// 0x20 is 32
assign count_hidden = (node_count == 6'h20) ? 1'b1 : 1'b0;		// 0x20 is 32
assign count_output = (node_count == 6'hA) ? 1'b1 : 1'b0;		// 0xA is 10

/* misc logic */
assign addr_input_unit = count;
assign sext_q = {1'b0, {7{q_input}}};
assign ram_h_addr = node_count - 1'b1;		// -1 because node_count was
				//incremented in L1_MAC_CLR state before we could use it
assign rom_hw_addr = {node_count[4:0], count};

/* mac module instantiation */
mac MAC0(.a(mac_a), .b(mac_b), .clr_n(mac_clr_n),
	     .acc(mac_out), .clk(clk), .rst_n(rst_n));

/* ram and rom instantiation */
ram hidden_unit(.data(rom_lut_q), .addr(ram_h_addr), .we(ram_h_we), .q(ram_h_q), .clk(clk));	// dw 8 aw 5
ram output_unit(.data(rom_lut_q), .addr(ram_o_addr), .we(ram_o_we), .q(ram_o_q), .clk(clk));	// dw 8 aw 4
rom hidden_weight(.addr(rom_hw_addr), .q(rom_hw_q), .clk(clk));				// dw 8 aw 15
rom output_weight(.addr(rom_ow_addr), .q(rom_ow_q), .clk(clk));				// dw 8 aw 9
rom act_func_lut(.addr(mac_out), .q(rom_lut_q), .clk(clk));					// dw 8 aw 11

/* state machine logic
*/
always_comb begin
	// default values
	next_state = IDLE;
	clr_count = 1;
	inc_ncount = 0;
	clr_ncount = 1;
	done = 0;
	digit = 4'h0;
	mac_clr_n = 0;
	mac_a = sext_q;
	mac_b = rom_hw_q;
	ram_h_we = 0;
	ram_o_we = 0;

	case (state)
		IDLE: begin
			if (start)
				next_state = LAYER1;
		end
		LAYER1: begin
			mac_clr_n = 1;
			clr_count = 0;
			clr_ncount = 0;
			mac_a = sext_q;
			mac_b = rom_hw_q;
			if (count_L1) begin
				next_state = L1_MAC_CLR;
				clr_count = 1;
			end
		end
		L1_MAC_CLR: begin
			mac_clr_n = 0;
			clr_ncount = 0;
			inc_ncount = 1;
			next_state = L1_LUT_WRITE;
		end
		L1_LUT_WRITE: begin
			mac_clr_n = 0;
			ram_h_we = 1;
			clr_ncount = 0;
			clr_count = 0;
			if (count_hidden) begin
				next_state = L1_L2_BUFFER;
				clr_ncount = 1;
				clr_count = 1;
			end
			else begin
				next_state = LAYER1;
			end
		end
		L1_L2_BUFFER: begin
			// exists so node_count gets reset before and rom output weight
			// appears on its output before entering LAYER2
			mac_clr_n = 0;
			clr_ncount = 0;
			clr_count = 0;
			next_state = LAYER2;
		end
		/* I haven't been working on these
		LAYER2: begin
			mac_clr_n = 1;
			clr_count = 0;
			clr_ncount = 0;
		end
		default: begin			// OUTPUT state
			done = 1;
			digit = digit_logic;
		end*/
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

/* counter flop and logic
*/
always @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		count <= 0;
	else begin
		if (clr_count)
			count <= 0;
		else
			count <= count + 1'b1;
	end
end

/* node counter flop and logic
*/
always @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		node_count <= 0;
	else begin
		if (clr_ncount)
			node_count <= 0;
		else
			if (inc_ncount)
				node_count <= node_count + 1'b1;
			else
				node_count <= node_count;
	end
end

endmodule
