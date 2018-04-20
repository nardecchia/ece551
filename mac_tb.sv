module mac_tb();

reg [7:0] in1,in2;
reg clk,rst_n,clr_n;

wire [25:0] acc;

mac iDUT(in1,in2,clk,rst_n,acc,clr_n);


initial begin

rst_n = 0;
clk = 0;
clr_n = 1;


#10 rst_n = 1;

in1 = 2;             // first calculation
in2 = 5;

@(posedge clk)
  in1 = -2;
  in2 = 5;

@(posedge clk)
  in1 = -3;
  in2 = 8;

#20 rst_n = 0; 
    clr_n = 0;

#10 rst_n = 1;
    clr_n = 1;

in1 = 126;       // second calculation
in2 = 126;

#30;

#20 rst_n = 0;
    clr_n = 0;

#10 rst_n = 1;
    clr_n = 1;

in1 = 126;       // third calculation
in2 = -126;

#30;

$stop;
end

always 
#5 clk = ~clk;

endmodule 