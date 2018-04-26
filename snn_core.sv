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
wire [7:0] sext_q;
reg [7:0] mac_a, mac_b;
wire [10:0] mac_out;
reg mac_clr_n;

reg [4:0] ram_h_addr;
//reg [3:0] ram_o_addr;
reg ram_h_we;// ram_o_we;
wire [7:0] ram_h_q;// ram_o_q;
wire [14:0] rom_hw_addr;
reg [8:0] rom_ow_addr;
wire [7:0] rom_hw_q, rom_ow_q, rom_lut_q;
reg output_clr;
reg output_comp_en;
reg [3:0] output_digit, gt_digit;
reg [7:0] output_value, gt_value;
wire [10:0] rom_lut_addr;

/* State definiitons */
typedef enum reg [3:0] {IDLE, LAYER1, L1_MAC_CLR, L1_LUT_WRITE, L1_L2_BUFFER, LAYER2, L2_MAC_CLR, L2_LUT_WRITE, OUTPUT} state_t;
state_t state, next_state;

/* counting logic */
assign count_L1 = (count == 10'h30F) ? 1'b1 : 1'b0;				// 783
assign count_L2 = (count == 10'h20) ? 1'b1 : 1'b0;				// 32
assign count_hidden = (node_count == 6'h20) ? 1'b1 : 1'b0;		// 32
assign count_output = (node_count == 6'hA) ? 1'b1 : 1'b0;		// 10

/* output comparing logic */
assign gt_value = (output_value > rom_lut_q) ? output_value : rom_lut_q;
assign gt_digit = (output_value > rom_lut_q) ? output_digit : (node_count - 1'b1);

/* misc logic */
assign addr_input_unit = count;
assign sext_q = {1'b0, {7{q_input}}};
//assign ram_h_addr = count[4:0] - 1'b1;		// -1 because count was
				//incremented in L1_LUT_WRITE state before we could use it
assign rom_hw_addr = {node_count[4:0], count};
assign rom_ow_addr = {node_count[3:0], count[4:0]};
assign rom_lut_addr = mac_out + 11'h400;		// rect(mac) + 1024

/* mac module instantiation */
mac MAC0(.in1(mac_a), .in2(mac_b), .clr_n(mac_clr_n),
	     .acc_out(mac_out), .clk(clk), .rst_n(rst_n), .acc());

/* ram and rom instantiation */
ram #(.DATA_WIDTH(8), .ADDR_WIDTH(5), .FILE_IN("ram_hidden_contents.txt"))
	hidden_unit(.data(rom_lut_q), .addr(ram_h_addr),
				.we(ram_h_we), .q(ram_h_q), .clk(clk));
/*ram #(.DATA_WIDTH(8), .ADDR_WIDTH(4), . FILE_IN(""))
	output_unit(.data(rom_lut_q), .addr(ram_o_addr),
				.we(ram_o_we), .q(ram_o_q), .clk(clk));*/
rom #(.DATA_WIDTH(8), .ADDR_WIDTH(15), .FILE_IN("rom_hidden_weight_contents.txt"))
	hidden_weight(.addr(rom_hw_addr), .q(rom_hw_q), .clk(clk));
rom #(.DATA_WIDTH(8), .ADDR_WIDTH(9), .FILE_IN("rom_output_weight_contents.txt"))
	output_weight(.addr(rom_ow_addr), .q(rom_ow_q), .clk(clk));
rom #(.DATA_WIDTH(8), .ADDR_WIDTH(11), .FILE_IN("rom_act_func_lut_contents.txt"))
	act_func_lut(.addr(rom_lut_addr), .q(rom_lut_q), .clk(clk));

/* state machine logic
*/
always_comb begin
	// default values
	next_state = IDLE;
	clr_count = 1;
	inc_ncount = 0;
	clr_ncount = 1;
	done = 0;
	digit = output_digit;
	//digit = 4'h0;
	mac_clr_n = 0;
	mac_a = sext_q;
	mac_b = rom_hw_q;
	ram_h_we = 0;
	output_comp_en = 0;
	output_clr = 0;
	ram_h_addr = count[4:0]; // default for Layer 2 state

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
			else
				next_state = LAYER1;
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
			ram_h_addr = node_count[4:0] - 1'b1;// -1 because node_count was
				//incremented in L1_MAC_CLR state before we could use it
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
			output_clr = 1;
			mac_clr_n = 0;
			clr_ncount = 0;
			clr_count = 0;
			next_state = LAYER2;
		end
		LAYER2: begin
			mac_clr_n = 1;
			clr_count = 0;
			clr_ncount = 0;
			mac_a = ram_h_q;
			mac_b = rom_ow_q;
			if (count_L2) begin
				next_state = L2_MAC_CLR;
				clr_count = 1;
			end
			else
				next_state = LAYER2;
		end
		L2_MAC_CLR: begin
			mac_clr_n = 0;
			clr_ncount = 0;
			inc_ncount = 1;
			next_state = L2_LUT_WRITE;
		end
		L2_LUT_WRITE: begin
			mac_clr_n = 0;
			output_comp_en = 1;
			clr_ncount = 0;
			clr_count = 0;
			if (count_output) begin
				next_state = OUTPUT;
				clr_ncount = 1;
				clr_count = 1;
			end
			else begin
				next_state = LAYER2;
			end
		end
		default: begin			// OUTPUT state
			done = 1;
			digit = output_digit;
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

/* counter flop and logic
*/
always @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		count <= 0;
	end
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
	end
	else begin
		if (clr_ncount)
			node_count <= 0;
		else begin
			if (inc_ncount)
				node_count <= node_count + 1'b1;
			else
				node_count <= node_count;
		end
	end
end

/* digit compare flop and logic
*/
always @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		output_digit <= 0;
		output_value <= 0;
	end
	else begin
		if (output_clr) begin
			output_digit <= 0;
			output_value <= 0;
		end
		else if (output_comp_en) begin
			output_digit <= gt_digit;
			output_value <= gt_value;
		end
		else begin
			output_digit <= output_digit;
			output_value <= output_value;
		end
	end
end


endmodule
