module rom (addr, clk, q);
 parameter ADDR_WIDTH = 0;
 parameter DATA_WIDTH = 0;
 parameter FILE_IN = "ram_output_contents.txt";
 input [(ADDR_WIDTH-1):0] addr;
 input clk;
 output reg [(DATA_WIDTH-1):0] q;
 // Declare the ROM variable
 reg [DATA_WIDTH-1:0] rom[2**ADDR_WIDTH-1:0];
 initial begin
	$readmemh(FILE_IN, rom);
 end
 always @ (posedge clk)
 begin
 q <= rom[addr];
 end
endmodule 
