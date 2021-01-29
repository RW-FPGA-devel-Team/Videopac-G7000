`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    
// Design Name: 
// Module Name:    osd
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
//  Author yomboprime
//
//
//////////////////////////////////////////////////////////////////////////////////

module bin4_to_7seg (
		input wire [3:0] binInput,
		output wire [6:0] segments
	);

	// 7 segment display:
	//      0
	//     ---
	//  3 |   | 4
	//    | 1 |
	//	  ---
	//  5 |   | 6
	//    | 2 |
	//	  ---

	assign segments[ 0 ] = (
			binInput == 4'd0 ||
			binInput == 4'd2 ||
			binInput == 4'd3 ||
			binInput == 4'd5 ||
			binInput == 4'h6 ||
			binInput == 4'h7 ||
			binInput == 4'h8 ||
			binInput == 4'h9 ||
			binInput == 4'hA ||
			binInput == 4'hC ||
			binInput == 4'hE ||
			binInput == 4'hF ) ? 1'b1 : 1'b0;
			
	assign segments[ 1 ] = (
			binInput == 4'd2 ||
			binInput == 4'd3 ||
			binInput == 4'd4 ||
			binInput == 4'd5 ||
			binInput == 4'h6 ||
			binInput == 4'h8 ||
			binInput == 4'h9 ||
			binInput == 4'hA ||
			binInput == 4'hb ||
			binInput == 4'hd ||
			binInput == 4'hE ||
			binInput == 4'hF ) ? 1'b1 : 1'b0;

	assign segments[ 2 ] = (
			binInput == 4'd0 ||
			binInput == 4'd2 ||
			binInput == 4'd3 ||
			binInput == 4'd5 ||
			binInput == 4'h6 ||
			binInput == 4'h8 ||
			binInput == 4'hb ||
			binInput == 4'hC ||
			binInput == 4'hd ||
			binInput == 4'hE ) ? 1'b1 : 1'b0;

	assign segments[ 3 ] = (
			binInput == 4'd0 ||
			binInput == 4'd4 ||
			binInput == 4'd5 ||
			binInput == 4'h6 ||
			binInput == 4'h8 ||
			binInput == 4'h9 ||
			binInput == 4'hA ||
			binInput == 4'hb ||
			binInput == 4'hC ||
			binInput == 4'hE ||
			binInput == 4'hF ) ? 1'b1 : 1'b0;

	assign segments[ 4 ] = (
			binInput == 4'd0 ||
			binInput == 4'd1 ||
			binInput == 4'd2 ||
			binInput == 4'd3 ||
			binInput == 4'd4 ||
			binInput == 4'h7 ||
			binInput == 4'h8 ||
			binInput == 4'h9 ||
			binInput == 4'hA ||
			binInput == 4'hd ) ? 1'b1 : 1'b0;

	assign segments[ 5 ] = (
			binInput == 4'd0 ||
			binInput == 4'd2 ||
			binInput == 4'h6 ||
			binInput == 4'h8 ||
			binInput == 4'hA ||
			binInput == 4'hb ||
			binInput == 4'hC ||
			binInput == 4'hd ||
			binInput == 4'hE ||
			binInput == 4'hF ) ? 1'b1 : 1'b0;

	assign segments[ 6 ] = (
			binInput == 4'd0 ||
			binInput == 4'd1 ||
			binInput == 4'd3 ||
			binInput == 4'd4 ||
			binInput == 4'd5 ||
			binInput == 4'h6 ||
			binInput == 4'h7 ||
			binInput == 4'h8 ||
			binInput == 4'h9 ||
			binInput == 4'hA ||
			binInput == 4'hb ||
			binInput == 4'hd ) ? 1'b1 : 1'b0;

endmodule

module osd_hex_char (
   input wire clk,
   input wire [8:0] hpos,
   input wire [8:0] vpos,
   input wire [8:0] hoffset,
   input wire [8:0] voffset,
   output reg out_alpha,
   input wire [6:0] segments
   );
   
   parameter
		X0 = 10'd0,
		X1 = 10'd9,
		Y0 = 10'd0,
		Y1 = 10'd9,
		Y2 = 10'd18
		;
   
	wire [9:0] x = hpos - hoffset;
	wire [9:0] y = vpos - voffset;

	// 7 segment display:
	//      0
	//     ---
	//  3 |   | 4
	//    | 1 |
	//	  ---
	//  5 |   | 6
	//    | 2 |
	//	  ---

	always @(posedge clk) begin
		out_alpha <=  (
			( x > X0 && x < X1 && y == Y0 && segments[ 0 ] == 1'b1 ) ||
			( x > X0 && x < X1 && y == Y1 && segments[ 1 ] == 1'b1 ) ||
			( x > X0 && x < X1 && y == Y2 && segments[ 2 ] == 1'b1 ) ||
			( y > Y0 && y < Y1 && x == X0 && segments[ 3 ] == 1'b1 ) ||
			( y > Y0 && y < Y1 && x == X1 && segments[ 4 ] == 1'b1 ) ||
			( y > Y1 && y < Y2 && x == X0 && segments[ 5 ] == 1'b1 ) ||
			( y > Y1 && y < Y2 && x == X1 && segments[ 6 ] == 1'b1 ) ) ? 1'b1 : 1'b0;
	end
endmodule

module osd (
   input wire clk,
   input wire [8:0] hpos,
   input wire [8:0] vpos,
   output reg [5:0] out_r,
   output reg [5:0] out_g,
   output reg [5:0] out_b,
   output reg out_alpha,
   input wire sd_initialized,
   input wire [15:0] currentROM,
   output reg [15:0] selectedROM,
   output reg doLoadRom,
   input wire key_released,
   input wire key_ready,
   input wire [7:0] key_ascii
   );

	initial out_alpha = 1'b0;
	initial selectedROM = 16'b0;
	initial doLoadRom = 1'b0;

	// Change this to 1'b1 to load rom 0 every time the osd starts
	parameter
		LOAD_ROM_0_WHEN_STARTING_OSD = 1'b0
		;

	parameter
		STATE_IDLE = 5'd0,
		STATE_START_LOAD_ROM = 5'd1,
		STATE_LOAD_ROM = 5'd2
		;

	reg [4:0] state = STATE_START_LOAD_ROM;
	
	reg uiEnabled;
	initial uiEnabled = 1'b0;

	reg displaying;
	initial displaying = 1'b0;
	
	reg [1:0] keyCounter;
	initial keyCounter = 2'b0;
	
	reg [27:0] timer1;
	initial timer1 = 28'd0;

	reg [3:0] timerLoadSignal;
	initial timerLoadSignal = 4'd0;
	
	reg [23:0] timerWaitSD;
	initial timerWaitSD = 24'hFFFFFF;
   
	wire alphaChar0, alphaChar1, alphaChar2, alphaChar3;
	wire alphaShadowChar0, alphaShadowChar1, alphaShadowChar2, alphaShadowChar3;
	
	wire digit, shadow;
   
	wire [6:0] segments7_0, segments7_1, segments7_2, segments7_3;
	reg [6:0] segments7_0_r, segments7_1_r, segments7_2_r, segments7_3_r;
	
	reg [15:0] displayedROM;
	initial displayedROM = 16'b0;
   
   osd_hex_char char3(
	.clk(clk),
	.hpos(hpos),
	.vpos(vpos),
	.hoffset(9'd38),
	.voffset(9'd4),
	.out_alpha(alphaChar3),
	.segments(segments7_3_r)
   );
   
   osd_hex_char char2(
	.clk(clk),
	.hpos(hpos),
	.vpos(vpos),
	.hoffset(9'd50),
	.voffset(9'd4),
	.out_alpha(alphaChar2),
	.segments(segments7_2_r)
   );
   
   osd_hex_char char1(
	.clk(clk),
	.hpos(hpos),
	.vpos(vpos),
	.hoffset(9'd62),
	.voffset(9'd4),
	.out_alpha(alphaChar1),
	.segments(segments7_1_r)
   );
   
   osd_hex_char char0(
	.clk(clk),
	.hpos(hpos),
	.vpos(vpos),
	.hoffset(9'd74),
	.voffset(9'd4),
	.out_alpha(alphaChar0),
	.segments(segments7_0_r)
   );

   // Shadow digits
   
   osd_hex_char char3_shadow(
	.clk(clk),
	.hpos(hpos),
	.vpos(vpos),
	.hoffset(9'd39),
	.voffset(9'd5),
	.out_alpha(alphaShadowChar3),
	.segments( segments7_3_r )
   );

   osd_hex_char char2_shadow(
	.clk(clk),
	.hpos(hpos),
	.vpos(vpos),
	.hoffset(9'd51),
	.voffset(9'd5),
	.out_alpha(alphaShadowChar2),
	.segments( segments7_2_r )
   );
   
   osd_hex_char char1_shadow(
	.clk(clk),
	.hpos(hpos),
	.vpos(vpos),
	.hoffset(9'd63),
	.voffset(9'd5),
	.out_alpha(alphaShadowChar1),
	.segments( segments7_1_r )
   );
   
   osd_hex_char char0_shadow(
	.clk(clk),
	.hpos(hpos),
	.vpos(vpos),
	.hoffset(9'd75),
	.voffset(9'd5),
	.out_alpha(alphaShadowChar0),
	.segments( segments7_0_r )
   );

   bin4_to_7seg bin_to_7seg_3 (
		.binInput(displayedROM[15:12]),
		.segments(segments7_3)
   );

   bin4_to_7seg bin_to_7seg_2 (
		.binInput(displayedROM[11:8]),
		.segments(segments7_2)
   );

   bin4_to_7seg bin_to_7seg_1 (
		.binInput(displayedROM[7:4]),
		.segments(segments7_1)
   );
   
   bin4_to_7seg bin_to_7seg_0 (
		.binInput(displayedROM[3:0]),
		.segments(segments7_0)
   );
   
   assign digit = alphaChar0 || alphaChar1 || alphaChar2 || alphaChar3;

   assign shadow = alphaShadowChar0 || alphaShadowChar1 || alphaShadowChar2 || alphaShadowChar3;

   always @(posedge clk) begin

		out_alpha <= ( digit || shadow ) && displaying;
   
		out_r <= ( ! sd_initialized ) ? ( digit ? 6'b111111 : 6'b001101 ) : 6'b0;
		out_g <= ( sd_initialized ) ? ( digit ? 6'b111111 : 6'b001000 ) : 6'b0;
		out_b <= 6'b0;

		case (state)
			STATE_IDLE:
			begin

				if ( sd_initialized ) begin
					// Up
					if ( key_ready == 1'b1 && key_released == 1'b0 && key_ascii == 8'h60 ) begin
						if ( keyCounter == 2'd0 ) begin
							keyCounter <= 2'd3;
							displaying <= 1'b1;
							uiEnabled <= 1'b1;
							timer1 <= 28'd0;
							if ( uiEnabled ) begin
								displayedROM <= displayedROM + 16'd1;
							end
							else if ( LOAD_ROM_0_WHEN_STARTING_OSD == 1'b1 ) begin
								state <= STATE_START_LOAD_ROM;
								selectedROM <= 16'b0;
								timerWaitSD <= 24'hFFFFFF;
							end
						end
						else begin
							keyCounter <= keyCounter - 2'd1;
						end
					end
					// Down
					else if ( key_ready == 1'b1 && key_released == 1'b0 && key_ascii == 8'h09 ) begin
						if ( keyCounter == 2'd0 ) begin
							keyCounter <= 2'd3;
							displaying <= 1'b1;
							uiEnabled <= 1'b1;
							timer1 <= 28'd0;
							if ( uiEnabled ) begin
								displayedROM <= displayedROM - 16'd1;
							end
							else if ( LOAD_ROM_0_WHEN_STARTING_OSD == 1'b1 ) begin
								state <= STATE_START_LOAD_ROM;
								selectedROM <= 16'b0;
								timerWaitSD <= 24'hFFFFFF;
							end
						end
						else begin
							keyCounter <= keyCounter - 2'd1;
						end
					end
					else if ( uiEnabled == 1'b1 ) begin
						if ( timer1 >= 28'd129000000 ) begin
							state <= STATE_START_LOAD_ROM;
							selectedROM <= displayedROM;
							timerWaitSD <= 24'hFFFFFF;
							uiEnabled <= 1'b0;
							displaying <= 1'b0;
						end
						else begin
							timer1 <= timer1 + 27'd1;
							if ( timer1 >= 27'd80000000 ) begin
								displaying <= timer1[ 23 ];
							end
						end
					end
					
					segments7_0_r <= segments7_0;
					segments7_1_r <= segments7_1;
					segments7_2_r <= segments7_2;
					segments7_3_r <= segments7_3;
					
				end
				else begin
					displaying <= 1'b1;
					segments7_0_r <= 7'b1111101;
					segments7_1_r <= 7'b1001111;
					segments7_2_r <= 7'b1100110;
					segments7_3_r <= 7'b1100010;
				end

			end

			STATE_START_LOAD_ROM:
			begin
				if ( sd_initialized ) begin
					timerLoadSignal <= 4'd0;
					doLoadRom <= 1'b1;
					state <= STATE_LOAD_ROM;
				end
				else if ( timerWaitSD > 24'd0 ) begin
					doLoadRom <= 1'b0;
					timerWaitSD <= timerWaitSD - 24'd1;
				end
				else begin
					state <= STATE_IDLE;
					displaying <= 1'b1;
					uiEnabled <= 1'b0;
					doLoadRom <= 1'b0;
				end
			end
			
			STATE_LOAD_ROM:
			begin
				if ( timerLoadSignal >= 4'd8 ) begin
					doLoadRom <= 1'b0;
					state <= STATE_IDLE;
				end
				else begin
					timerLoadSignal <= timerLoadSignal + 4'd1;
				end
			end
		endcase
   end
   
endmodule
