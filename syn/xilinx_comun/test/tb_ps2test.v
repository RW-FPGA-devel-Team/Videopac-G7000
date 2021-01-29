`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   19:11:23 01/08/2021
// Design Name:   ps2_keyboard_interface
// Module Name:   /home/avlixa/FPGA/ZXDOS/VideoPac-ZXDOS/src/test/ps2test.v
// Project Name:  videopac_zxdos_lx16
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: ps2_keyboard_interface
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_ps2test;

	// Inputs
	reg clk;
	reg reset;
	reg ps2_clk;
	reg ps2_data;
	
	reg [7:0] tx_data;
	reg tx_write;
   reg [6:1] keyb_dec_s;
   
	// Outputs
   wire [14:7] keyb_enc_s;
	wire rx_read;
   wire rx_extended;
	wire rx_released;
	wire rx_shift_key_on;
	wire [7:0] rx_ascii;
	wire rx_data_ready;
	wire tx_write_ack;
	wire tx_error_no_keyboard_ack;
	wire keyb_f1;
	wire keyb_f2;
	wire keyb_f3;
	wire keyb_f4;
	wire keyb_f5;
	wire keyb_f6;
	wire keyb_f7;
	wire keyb_f8;
	wire keyb_f9;
	wire keyb_f10;
	wire keyb_f11;
	wire keyb_f12;

	// Instantiate the Unit Under Test (UUT)
	ps2_keyboard_interface uut (
		.clk(clk), 
		.reset(reset), 
		.ps2_clk(ps2_clk), 
		.ps2_data(ps2_data), 
		.rx_extended(rx_extended), 
		.rx_released(rx_released), 
		.rx_shift_key_on(rx_shift_key_on), 
		.rx_ascii(rx_ascii), 
		.rx_data_ready(rx_data_ready), 
		.rx_read(rx_read), 
		.tx_data(tx_data), 
		.tx_write(tx_write), 
		.tx_write_ack(tx_write_ack), 
		.tx_error_no_keyboard_ack(tx_error_no_keyboard_ack), 
		.keyb_f1(keyb_f1), 
		.keyb_f2(keyb_f2), 
		.keyb_f3(keyb_f3), 
		.keyb_f4(keyb_f4), 
		.keyb_f5(keyb_f5), 
		.keyb_f6(keyb_f6), 
		.keyb_f7(keyb_f7), 
		.keyb_f8(keyb_f8), 
		.keyb_f9(keyb_f9), 
		.keyb_f10(keyb_f10), 
		.keyb_f11(keyb_f11), 
		.keyb_f12(keyb_f12)
	);

  vp_keymap uut_keymap  (
      .clk_i(clk),
      .res_n_i(~reset),
      .keyb_dec_i(keyb_dec_s),
      .keyb_enc_o(keyb_enc_s),
      .rx_data_ready_i(rx_data_ready),
      .rx_ascii_i(rx_ascii),
      .rx_released_i(rx_released),
      .rx_read_o(rx_read)
    );

	initial begin
		clk = 1;
		forever begin
		#10 clk = ~clk;
		end
	end

//	initial begin
//		rx_read = 0;
//
//		forever begin
//       #50 rx_read = ( rx_data_ready );
//		end
//   end

	initial begin
      keyb_dec_s = 6'b111111;
		forever begin
         #50 keyb_dec_s = 6'b111110;
         #50 keyb_dec_s = 6'b111101;
         #50 keyb_dec_s = 6'b111011;
         #50 keyb_dec_s = 6'b110111;
         #50 keyb_dec_s = 6'b101111;
         #50 keyb_dec_s = 6'b011111;
         #50 keyb_dec_s = 6'b111111;
		end
	end
      
      
	initial begin
		// Initialize Inputs
		reset = 1;
		ps2_clk = 1;
		ps2_data = 1;
		tx_data = 0;
		tx_write = 0;



		// Wait 100 ns for global reset to finish
		#100;
      reset = 0;
		#50;



        
		// HOLD KEY F3

      #45 ps2_data = 0; //START 0
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //1
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //2
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;

		#45 ps2_data = 1; //3
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //4
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //5
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;

		#45 ps2_data = 0; //6
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0;//7
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //8
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1; //PARITY 9
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1;// STOP 10
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		// Add stimulus here
		
      #200;

		// RELEASE KEY F3

      
		#45 ps2_data = 0; //START 0
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //1
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //2
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;

		#45 ps2_data = 0; //3
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //4
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1; //5
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;

		#45 ps2_data = 1; //6
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1; //7
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1; //8
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1; //PARITY 9
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1;// STOP 10
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
	//BRAKE CODE
		#45 ps2_data = 0; //START 0
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //1
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //2
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;

		#45 ps2_data = 1; //3
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //4
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //5
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;

		#45 ps2_data = 0; //6
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //7
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //8
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1; //PARITY 9
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1;// STOP 10
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;

      #200;
      
		// HOLD KEY A (x1C)

      #45 ps2_data = 0; //START 0
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //1
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //2
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;

		#45 ps2_data = 1; //3
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1; //4
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1; //5
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;

		#45 ps2_data = 0; //6
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0;//7
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //8
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1; //PARITY 9
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1;// STOP 10
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		// Add stimulus here
		
      #200;

		// RELEASE KEY A
      
		#45 ps2_data = 0; //START 0
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //1
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //2
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;

		#45 ps2_data = 0; //3
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //4
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1; //5
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;

		#45 ps2_data = 1; //6
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1; //7
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1; //8
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1; //PARITY 9
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1;// STOP 10
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
	//BRAKE CODE
		#45 ps2_data = 0; //START 0
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //1
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //2
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;

		#45 ps2_data = 1; //3
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1; //4
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1; //5
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;

		#45 ps2_data = 0; //6
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //7
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //8
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1; //PARITY 9
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1;// STOP 10
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;      


      #200;
      
		// HOLD KEY ESC (x76)

      #45 ps2_data = 0; //START 0
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //1
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1; //2
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;

		#45 ps2_data = 1; //3
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //4
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1; //5
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;

		#45 ps2_data = 1; //6
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1;//7
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //8
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1; //PARITY 9
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1;// STOP 10
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		// Add stimulus here
		
      #200;

		// RELEASE KEY ESC
      
		#45 ps2_data = 0; //START 0
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //1
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //2
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;

		#45 ps2_data = 0; //3
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //4
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1; //5
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;

		#45 ps2_data = 1; //6
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1; //7
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1; //8
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1; //PARITY 9
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1;// STOP 10
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
	//BRAKE CODE
		#45 ps2_data = 0; //START 0
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //1
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1; //2
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;

		#45 ps2_data = 1; //3
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //4
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1; //5
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;

		#45 ps2_data = 1; //6
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1; //7
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //8
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1; //PARITY 9
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1;// STOP 10
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;      


      #200;
      
		// HOLD KEY ENTER(x5A)

      #45 ps2_data = 0; //START 0
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //1
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1; //2
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;

		#45 ps2_data = 0; //3
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1; //4
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1; //5
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;

		#45 ps2_data = 0; //6
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1;//7
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //8
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //PARITY 9
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1;// STOP 10
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		// Add stimulus here
		
      #200;

		// RELEASE KEY ENTER
      
		#45 ps2_data = 0; //START 0
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //1
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //2
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;

		#45 ps2_data = 0; //3
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //4
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1; //5
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;

		#45 ps2_data = 1; //6
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1; //7
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1; //8
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1; //PARITY 9
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1;// STOP 10
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
	//BRAKE CODE
		#45 ps2_data = 0; //START 0
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //1
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1; //2
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;

		#45 ps2_data = 0; //3
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1; //4
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1; //5
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;

		#45 ps2_data = 0; //6
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1; //7
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //8
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //PARITY 9
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1;// STOP 10
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;  

      #200;
      
		// HOLD KEY TAB(X66)

      #45 ps2_data = 0; //START 0
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //1
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1; //2
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;

		#45 ps2_data = 1; //3
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //4
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //5
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;

		#45 ps2_data = 1; //6
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1;//7
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //8
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //PARITY 9
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1;// STOP 10
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		// Add stimulus here
		
      #200;

		// RELEASE KEY TAB
      
		#45 ps2_data = 0; //START 0
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //1
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //2
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;

		#45 ps2_data = 0; //3
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //4
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1; //5
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;

		#45 ps2_data = 1; //6
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1; //7
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1; //8
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1; //PARITY 9
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1;// STOP 10
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
	//BRAKE CODE
		#45 ps2_data = 0; //START 0
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //1
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1; //2
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;

		#45 ps2_data = 1; //3
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //4
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //5
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;

		#45 ps2_data = 1; //6
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1; //7
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //8
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 0; //PARITY 9
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;
		
		#45 ps2_data = 1;// STOP 10
		#5 ps2_clk = 0;
		#50 ps2_clk = 1;  


	end
      
endmodule

