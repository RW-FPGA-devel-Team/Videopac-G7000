`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    09:00:25 07/20/2018 
// Design Name: 
// Module Name:    joydecoder for zxuno models
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments:
//
//  Based on original joystick test by mcleod_Ideafix http://zxuno.speccy.org
//
//////////////////////////////////////////////////////////////////////////////////

module joydecoder (
  input wire clk_sys,
  input wire [1:0] boardzxuno, //UNO board: (0) single joystick / (1) 2 joystick splitter / (2) 2 joystick VGA2M
  
  //Joystick1
  input wire JOY_U,
  input wire JOY_D,
  input wire JOY_L,
  input wire JOY_R,
  input wire JOY_A,
  input wire JOY_B,
  inout wire joy_c,

  //Joystick2
  input wire JOY2_U,
  input wire JOY2_D,
  input wire JOY2_L,
  input wire JOY2_R,
  input wire JOY2_A,
  input wire JOY2_B,
  
  output wire [7:0] joy1, //    SACBRLDU - active = 0
  output wire [7:0] joy2  //    SACBRLDU - active = 0
  );
  
	reg [1:0] joy_split = 0; //ZXUNO joystick splitter
	reg [7:0] joy1_aux =  8'b11111111;; //    SACBRLDU
	reg [7:0] joy2_aux =  8'b11111111;; //    SACBRLDU

	//ZXUNO
   //Joystick type: 0 - Single Joystick, 
   //               1 - 2 joystick in splitter, 
   //               2 - 2 joystick ZXUNO VGA 2M, 
	
	assign joy_c = (boardzxuno == 2'b01 )? joy_split[1] : 1'bZ; //Selección joystick 1/2 mediante splitter
   assign joy1 = joy1_aux;
   assign joy2 = joy2_aux;
	
	always @(posedge clk_sys) begin
		joy_split <= joy_split + 1;
		case (boardzxuno)
			2'b01: begin //splitter
				if (!joy_split[1] && joy_split[0]) begin
					joy1_aux[0] <= JOY_U;
					joy1_aux[1] <= JOY_D;
					joy1_aux[2] <= JOY_L;
					joy1_aux[3] <= JOY_R;
					joy1_aux[4] <= JOY_A;
					joy1_aux[5] <= JOY_B;
					joy1_aux[6] <= 1'b1;
					joy1_aux[7] <= 1'b1;
				end
				else if (joy_split[1] && joy_split[0]) begin
					joy2_aux[0] <= JOY_U;
					joy2_aux[1] <= JOY_D;
					joy2_aux[2] <= JOY_L;
					joy2_aux[3] <= JOY_R;
					joy2_aux[4] <= JOY_A;
					joy2_aux[5] <= JOY_B;
					joy2_aux[6] <= 1'b1;
					joy2_aux[7] <= 1'b1;
				end
			end
			2'b10: begin //ZXUNO VGA 2M
				joy1_aux[0] <= JOY_U;
				joy1_aux[1] <= JOY_D;
				joy1_aux[2] <= JOY_L;
				joy1_aux[3] <= JOY_R;
				joy1_aux[4] <= JOY_A;
				joy1_aux[5] <= JOY_B;
				joy1_aux[6] <= 1'b1;
				joy1_aux[7] <= 1'b1;
				joy2_aux[0] <= JOY2_U;
				joy2_aux[1] <= JOY2_D;
				joy2_aux[2] <= JOY2_L;
				joy2_aux[3] <= JOY2_R;
				joy2_aux[4] <= JOY2_A;
				joy2_aux[5] <= JOY2_B;
				joy2_aux[6] <= 1'b1;
				joy2_aux[7] <= 1'b1;
			end
			default: begin //single joystick
				joy1_aux[0] <= JOY_U;
				joy1_aux[1] <= JOY_D;
				joy1_aux[2] <= JOY_L;
				joy1_aux[3] <= JOY_R;
				joy1_aux[4] <= JOY_A;
				joy1_aux[5] <= JOY_B;
				joy1_aux[6] <= joy_c;
				joy1_aux[7] <= 1'b1;
				joy2_aux   <=  8'b11111111;
			end
		endcase
	end;


endmodule
