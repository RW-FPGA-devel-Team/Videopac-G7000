`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   19:07:43 01/08/2021
// Design Name:   vp_keymap
// Module Name:   /home/avlixa/FPGA/ZXDOS/VideoPac-ZXDOS/src/test/testps2.v
// Project Name:  videopac_zxdos_lx16
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: vp_keymap
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module testps2;

	// Inputs
	reg clk_i;
	reg res_n_i;
	reg [6:1] keyb_dec_i;
	reg rx_data_ready_i;
	reg [7:0] rx_ascii_i;
	reg rx_released_i;

	// Outputs
	wire [14:7] keyb_enc_o;
	wire rx_read_o;

	// Instantiate the Unit Under Test (UUT)
	vp_keymap uut (
		.clk_i(clk_i), 
		.res_n_i(res_n_i), 
		.keyb_dec_i(keyb_dec_i), 
		.keyb_enc_o(keyb_enc_o), 
		.rx_data_ready_i(rx_data_ready_i), 
		.rx_ascii_i(rx_ascii_i), 
		.rx_released_i(rx_released_i), 
		.rx_read_o(rx_read_o)
	);

	initial begin
		// Initialize Inputs
		clk_i = 0;
		res_n_i = 0;
		keyb_dec_i = 0;
		rx_data_ready_i = 0;
		rx_ascii_i = 0;
		rx_released_i = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here

	end
      
endmodule

