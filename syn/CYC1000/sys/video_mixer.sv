//
//
// Copyright (c) 2017 Sorgelig, (c) 2021rampa
//
// This program is GPL Licensed. See COPYING for the full license.
//
// Based on ther mister scandoubler, this one is tailored for the ATLAS FPGA.
// The only video output is direct HDMI.
//
////////////////////////////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

//
// LINE_LENGTH: Length of  display line in pixels
//              Usually it's length from HSync to HSync.
//              May be less if line_start is used.
//
// HALF_DEPTH:  If =1 then color dept is 4 bits per component
//              For half depth 8 bits monochrome is available with
//              mono signal enabled and color = {G, R}

module video_mixer
#(
	parameter LINE_LENGTH  = 768,
	parameter HALF_DEPTH   = 0
)
(
	// master clock
	// it should be multiple by (ce_pix*4).
	input            clk_sys,
	
	input            CLK_12MHZ,
	
	// Pixel clock or clock_enable (both are accepted).
	input            ce_pix,
	output           ce_pix_out,

	// scanlines (00-none 01-25% 10-50% 11-75%)
	input      [1:0] scanlines,

	// High quality 2x scaling
	input            hq2x,

	// color
	input [DWIDTH:0] R,
	input [DWIDTH:0] G,
	input [DWIDTH:0] B,

	// Monochrome mode (for HALF_DEPTH only)
	input            mono,

	// Positive pulses.
	input            HSync,
	input            VSync,
	input            HBlank,
	input            VBlank,

	output reg [7:0] TMDS

);

localparam DWIDTH = HALF_DEPTH ? 3 : 7;


reg [7:0] VGA_R;
reg [7:0] VGA_G;
reg [7:0] VGA_B;
reg VGA_HS;
reg VGA_VS;
reg VGA_BLANK;


wire [DWIDTH:0] R_sd;
wire [DWIDTH:0] G_sd;
wire [DWIDTH:0] B_sd;
wire hs_sd, vs_sd, hb_sd, vb_sd, ce_pix_sd;

scandoubler #(.LENGTH(LINE_LENGTH), .HALF_DEPTH(HALF_DEPTH)) sd
(
	.*,
	.hs_in(HSync),
	.vs_in(VSync),
	.hb_in(HBlank),
	.vb_in(VBlank),
	.r_in(R),
	.g_in(G),
	.b_in(B),

	.ce_pix_out(ce_pix_sd),
	.hs_out(hs_sd),
	.vs_out(vs_sd),
	.hb_out(hb_sd),
	.vb_out(vb_sd),
	.r_out(R_sd),
	.g_out(G_sd),
	.b_out(B_sd)
);

wire [DWIDTH:0] rt  = R_sd ;
wire [DWIDTH:0] gt  = G_sd ;
wire [DWIDTH:0] bt  = B_sd ;


pll_hdmi pll_hdmi
(
  .inclk0 (CLK_12MHZ),
  .c0 (clk_vdi),
  .c1 (clk_pixel)
);

assign TMDS[0]=1'b0;
assign TMDS[2]=1'b0;
assign TMDS[4]=1'b0;
assign TMDS[6]=1'b0;

hdmi hdmi_18bits
(
        //clocks
        .CLK_DVI_I(clk_vdi),     
        .CLK_PIXEL_I(clk_pixel),        

        // components
        .R_I(VGA_R),
        .G_I(VGA_G),
        .B_I(VGA_B),
        .BLANK_I(~VGA_BLANK),
        .HSYNC_I(VGA_HS),                        
        .VSYNC_I(VGA_VS),                        
        .TMDS_D0_O(TMDS[3]),            
        .TMDS_D1_O(TMDS[5]),            
        .TMDS_D2_O(TMDS[7]),            
        .TMDS_CLK_O(TMDS[1])
);      


generate
	if(HALF_DEPTH) begin
		wire [7:0] r  = mono ? {gt,rt} : {rt,rt};
		wire [7:0] g  = mono ? {gt,rt} : {gt,gt};
		wire [7:0] b  = mono ? {gt,rt} : {bt,bt};
	end else begin
		wire [7:0] r  = rt;
		wire [7:0] g  = gt;
		wire [7:0] b  = bt;
	end
endgenerate

wire hs =  hs_sd ;
wire vs =  vs_sd ;

assign ce_pix_out = ce_pix_sd;


reg scanline = 0;
always @(posedge clk_sys) begin
	reg old_hs, old_vs;
	
	old_hs <= hs;
	old_vs <= vs;
	
	if(old_hs && ~hs) scanline <= ~scanline;
	if(old_vs && ~vs) scanline <= 0;
end

wire hde =  ~hb_sd ;
wire vde =  ~vb_sd ;

always @(posedge clk_sys) begin
	reg old_hde;

	case(scanlines & {scanline, scanline})
		1: begin // reduce 25% = 1/2 + 1/4
			VGA_R <= {1'b0, r[7:1]} + {2'b00, r[7:2]};
			VGA_G <= {1'b0, g[7:1]} + {2'b00, g[7:2]};
			VGA_B <= {1'b0, b[7:1]} + {2'b00, b[7:2]};
		end

		2: begin // reduce 50% = 1/2
			VGA_R <= {1'b0, r[7:1]};
			VGA_G <= {1'b0, g[7:1]};
			VGA_B <= {1'b0, b[7:1]};
		end

		3: begin // reduce 75% = 1/4
			VGA_R <= {2'b00, r[7:2]};
			VGA_G <= {2'b00, g[7:2]};
			VGA_B <= {2'b00, b[7:2]};
		end

		default: begin
			VGA_R <= r;
			VGA_G <= g;
			VGA_B <= b;
		end
	endcase

	VGA_VS <= vs;
	VGA_HS <= hs;

	old_hde <= hde;
	if(~old_hde && hde) VGA_BLANK <= vde;
	if(old_hde && ~hde) VGA_BLANK <= 0;
end

endmodule
