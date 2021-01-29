`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   17:25:08 10/24/2014
// Design Name:   Keyboard
// Module Name:   /home/s1349598/Keyboard/TestingKeyboard.v
// Project Name:  Keyboard
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: Keyboard
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module TestingKeyboard;

	// Inputs
	reg CLK;
	reg PS2_CLK;
	reg PS2_DATA;

	// Outputs
	wire scan_err;
	wire [10:0] scan_code;
	wire [3:0]COUNT;
	wire TRIG_ARR;
	wire [7:0]CODEWORD;
	wire [7:0] LED;

	// Instantiate the Unit Under Test (UUT)
	Keyboard uut (
		.CLK(CLK), 
		.PS2_CLK(PS2_CLK), 
		.PS2_DATA(PS2_DATA), 
		.scan_err(scan_err), 
		.scan_code(scan_code),
		.TRIG_ARR(TRIG_ARR),
		.COUNT(COUNT),
		.CODEWORD(CODEWORD),
		.LED(LED)
	);

	initial begin
		CLK = 1;
		forever begin
		#1 CLK = ~CLK;
		end
	end
	
	initial begin
		// Initialize Inputs
		PS2_CLK = 1;
		PS2_DATA = 1;

		// Wait 100 ns for global reset to finish
		#100;
		
      #45 PS2_DATA = 0; //START 0
		#5 PS2_CLK = 0;
		#50 PS2_CLK = 1;
		
		#45 PS2_DATA = 1; //1
		#5 PS2_CLK = 0;
		#50 PS2_CLK = 1;
		
		#45 PS2_DATA = 0; //2
		#5 PS2_CLK = 0;
		#50 PS2_CLK = 1;

		#45 PS2_DATA = 1; //3
		#5 PS2_CLK = 0;
		#50 PS2_CLK = 1;
		
		#45 PS2_DATA = 0; //4
		#5 PS2_CLK = 0;
		#50 PS2_CLK = 1;
		
		#45 PS2_DATA = 1; //5
		#5 PS2_CLK = 0;
		#50 PS2_CLK = 1;

		#45 PS2_DATA = 1; //6
		#5 PS2_CLK = 0;
		#50 PS2_CLK = 1;
		
		#45 PS2_DATA = 1; //7
		#5 PS2_CLK = 0;
		#50 PS2_CLK = 1;
		
		#45 PS2_DATA = 0; //8
		#5 PS2_CLK = 0;
		#50 PS2_CLK = 1;
		
		#45 PS2_DATA = 0; //PARITY 9
		#5 PS2_CLK = 0;
		#50 PS2_CLK = 1;
		
		#45 PS2_DATA = 1;// STOP 10
		#5 PS2_CLK = 0;
		#50 PS2_CLK = 1;
		// Add stimulus here
		
		#45 PS2_DATA = 0; //START 0
		#5 PS2_CLK = 0;
		#50 PS2_CLK = 1;
		
		#45 PS2_DATA = 0; //1
		#5 PS2_CLK = 0;
		#50 PS2_CLK = 1;
		
		#45 PS2_DATA = 0; //2
		#5 PS2_CLK = 0;
		#50 PS2_CLK = 1;

		#45 PS2_DATA = 0; //3
		#5 PS2_CLK = 0;
		#50 PS2_CLK = 1;
		
		#45 PS2_DATA = 0; //4
		#5 PS2_CLK = 0;
		#50 PS2_CLK = 1;
		
		#45 PS2_DATA = 1; //5
		#5 PS2_CLK = 0;
		#50 PS2_CLK = 1;

		#45 PS2_DATA = 1; //6
		#5 PS2_CLK = 0;
		#50 PS2_CLK = 1;
		
		#45 PS2_DATA = 1; //7
		#5 PS2_CLK = 0;
		#50 PS2_CLK = 1;
		
		#45 PS2_DATA = 1; //8
		#5 PS2_CLK = 0;
		#50 PS2_CLK = 1;
		
		#45 PS2_DATA = 1; //PARITY 9
		#5 PS2_CLK = 0;
		#50 PS2_CLK = 1;
		
		#45 PS2_DATA = 1;// STOP 10
		#5 PS2_CLK = 0;
		#50 PS2_CLK = 1;
	//BRAKE CODE
		#45 PS2_DATA = 0; //START 0
		#5 PS2_CLK = 0;
		#50 PS2_CLK = 1;
		
		#45 PS2_DATA = 1; //1
		#5 PS2_CLK = 0;
		#50 PS2_CLK = 1;
		
		#45 PS2_DATA = 0; //2
		#5 PS2_CLK = 0;
		#50 PS2_CLK = 1;

		#45 PS2_DATA = 1; //3
		#5 PS2_CLK = 0;
		#50 PS2_CLK = 1;
		
		#45 PS2_DATA = 0; //4
		#5 PS2_CLK = 0;
		#50 PS2_CLK = 1;
		
		#45 PS2_DATA = 1; //5
		#5 PS2_CLK = 0;
		#50 PS2_CLK = 1;

		#45 PS2_DATA = 1; //6
		#5 PS2_CLK = 0;
		#50 PS2_CLK = 1;
		
		#45 PS2_DATA = 1; //7
		#5 PS2_CLK = 0;
		#50 PS2_CLK = 1;
		
		#45 PS2_DATA = 0; //8
		#5 PS2_CLK = 0;
		#50 PS2_CLK = 1;
		
		#45 PS2_DATA = 0; //PARITY 9
		#5 PS2_CLK = 0;
		#50 PS2_CLK = 1;
		
		#45 PS2_DATA = 1;// STOP 10
		#5 PS2_CLK = 0;
		#50 PS2_CLK = 1;
	end
      
endmodule

