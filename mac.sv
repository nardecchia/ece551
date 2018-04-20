module mac(in1,in2,clk,rst_n,acc,clr_n);

input signed [7:0] in1,in2; // input
input clk,rst_n,clr_n;

output reg [25:0] acc; // output

wire [25:0] mult_ext, acc_nxt, add; 
wire [15:0] mult;

assign mult = in1 * in2;

assign mult_ext = {{10{mult[15]}}, mult[15:0]}; // sign-extend


assign add = mult_ext + acc; // increment the result


assign acc_nxt = clr_n? add : 26'h0000000; // reset

always @ (posedge clk, negedge rst_n) begin // register to increment the result
  if (rst_n == 1'b0) 
    acc <= 26'h0000000;
  else 
    acc <= acc_nxt;
end

endmodule 