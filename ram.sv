module ram (data, addr, we, clk, q);
 parameter ADDR_WIDTH = 0;
 parameter DATA_WIDTH = 0;
 parameter FILE_IN = "ram_output_contents.txt";
 input [(DATA_WIDTH-1):0] data;
 input [(ADDR_WIDTH-1):0] addr;
 input we, clk;
 output [(DATA_WIDTH-1):0] q;
 // Declare the RAM variable
 reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0];
 // Variable to hold the registered read address
 reg [ADDR_WIDTH-1:0] addr_reg;

 initial begin
	$readmemh(FILE_IN, ram);
 end

 always @ (posedge clk)
 begin
 if (we) // Write
 ram[addr] <= data;
 addr_reg <= addr;
 end
 assign q = ram[addr_reg];
endmodule





module ram_snn (data, addr, we, clk, q);
 input [7:0] data;
 input [9:0] addr;
 input we, clk;
 output q;
 // Declare the RAM variable
 reg [7:0] ram[2**9:0];
 // Variable to hold the registered read address
 reg [9:0] addr_reg;

// initial begin
	//$readmemh(FILE_IN, ram);
 //end

 always @ (posedge clk)
 begin
 if (we) // Write
 ram[addr] <= data;
 addr_reg <= addr;
 end
 assign q = ram[addr_reg];
endmodule