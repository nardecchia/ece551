module mac (a, b, of, uf, clr_n, acc, clk, rst_n);
input signed [7:0] a, b;
input clr_n, clk, rst_n;
output reg signed [15:0] acc;
output reg of, uf;

wire of_nxt, uf_nxt;
wire signed [15:0] mult, acc_nxt;
wire signed [16:0] add;

assign mult[15:0] = a*b;
assign add[16:0] = {acc[15],acc[15:0]} + {mult[15],mult[15:0]};
assign of_nxt = (add[16:15] == 2'b01);
assign uf_nxt = (add[16:15] == 2'b10);
assign acc_nxt[15:0] = (clr_n == 0) ? 0 : add[15:0];

always @(posedge clk, negedge rst_n)
	begin
	if(!rst_n)
		begin
			of <= 0;
			uf <= 0;
			acc <= 0;
		end
	else
		begin
			of <= of_nxt;
			uf <= uf_nxt;
			acc <= acc_nxt;	
		end
	end	
endmodule


