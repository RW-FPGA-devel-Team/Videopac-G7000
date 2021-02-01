// FPGA Videopac
//-----------------------------------------------------------------------------
//
// Copyright (c) 2007, Arnim Laeuger (arnim.laeuger@gmx.net)
//
// All rights reserved
//
// Redistribution and use in source and synthezised forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice,
// this list of conditions and the following disclaimer.
//
// Redistributions in synthesized form must reproduce the above copyright
// notice, this list of conditions and the following disclaimer in the
// documentation and/or other materials provided with the distribution.
//
// Neither the name of the author nor the names of other contributors may
// be used to endorse or promote products derived from this software without
// specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
// THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
// PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//
// Please report bugs to the author, but before you do so, please
// make sure that this is not a derivative work and that
// you have the latest version of this file.
//
// Based off MiST port by wsoltys in 2014.
//
// Adapted for MiSTer by Kitrinx in 2018

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [44:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	output  [7:0] VIDEO_ARX,
	output  [7:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S, // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)
	input         TAPE_IN,

	// SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,
	output [1:0]  BUFFERMODE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR
);

assign {UART_RTS, UART_TXD, UART_DTR} = 0;


assign LED_USER  = ioctl_download;
assign LED_DISK  = 0;
assign LED_POWER = 0;

assign VIDEO_ARX = status[8] ? 8'd16 : 8'd4;
assign VIDEO_ARY = status[8] ? 8'd9  : 8'd3;

assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CKE, SDRAM_CLK, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;
assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = 0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;


////////////////////////////  HPS I/O  //////////////////////////////////


`include "build_id.v"
parameter CONF_STR = {
	"VIDEOPAC;;",
	"-;",
	"F1,BIN,Load catridge;",
	"F2,ROM,Load XROM;",
   "-;",
	"F3,CHR,Change VDC font;",
	"-;",
	"OE,System,Odyssey2,Videopac;",
	"O6,Palette,Tv (RF),RGB;",
	"O4,TV Set,Color,B/W;",
	"O8,Aspect ratio,4:3,16:9;",
	"O9B,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
	"O1,The Voice,Off,on;",
	"OGH,Buffering,Triple,Single,Low Latency;",
	"O5,Trim Overscan,No,Yes;",
	"-;",
	"O7,Swap Joysticks,No,Yes;",
	"-;",
	"R0,Reset;",
	"J,Action,Reset,1,2,3,4,5,6,7,8,9,0;",
	"V,v",`BUILD_DATE
};

wire  [1:0] buttons;
wire [31:0] status;
wire        forced_scandoubler;

wire        ioctl_download;
wire [24:0] ioctl_addr;
wire [15:0] ioctl_dout;
wire        ioctl_wait;
wire        ioctl_wr;
wire  [7:0] ioctl_index;


wire [15:0] joystick_0,joystick_1;
wire [24:0] ps2_mouse;

hps_io #(.STRLEN($size(CONF_STR)>>3)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),

	.conf_str(CONF_STR),

	.ioctl_download(ioctl_download),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_wait(ioctl_wait),
	.ioctl_index(ioctl_index),

	.forced_scandoubler(forced_scandoubler),
	
	.buttons(buttons),
	.status(status),

	.joystick_0(joystick_0),
	.joystick_1(joystick_1),

	.ps2_key(ps2_key)
);

assign BUFFERMODE = (status[17:16] == 2'b00) ? 2'b01 : (status[17:16] == 2'b01) ? 2'b00 : 2'b10;

wire       PAL = status[14];
wire       joy_swap = status[7];

wire       VOICE = status[1];
wire       MODE = status[6];
wire       SCREEN = status[4];

wire [15:0] joya = joy_swap ? joystick_1 : joystick_0;
wire [15:0] joyb = joy_swap ? joystick_0 : joystick_1;


///////////////////////  CLOCK/RESET  ///////////////////////////////////


wire clock_locked;
wire clk_sys_o2;
wire clk_sys_vp;
wire clk_2m5;
wire clk_sys = PAL ? clk_sys_vp : clk_sys_o2;

pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_sys_o2),
	.outclk_1(clk_sys_vp),
	.outclk_2(clk_2m5),
	.locked(clock_locked)
);

// hold machine in reset until first download starts
reg old_pal = 0;

always @(posedge clk_sys) begin
	old_pal <= PAL;
end

wire reset = buttons[1] | status[0] | ioctl_download | (old_pal != PAL);

// Original Clocks:
// Standard    NTSC           PAL
// Sys clock   42.95454       70.9379 
// Main clock  21.47727 MHz   35.46895 MHz // ntsc/pal colour carrier times 3/4 respectively
// VDC divider 3              5
// VDC clock   7.159 MHz      7.094 MHz
// CPU divider 4              6
// CPU clock   5.369 MHz      5.911 MHz

reg clk_cpu_en;
reg clk_vdc_en;

reg [3:0] clk_cpu_en_ctr;
reg [3:0] clk_vdc_en_ctr;

// Generate pulse enables for cpu and vdc

always @(posedge clk_sys or posedge reset) begin
	if (reset) begin
		clk_cpu_en_ctr <= 4'd0;
		clk_vdc_en_ctr <= 4'd0;
	end else begin

		// CPU Counter
		if (clk_cpu_en_ctr >= (PAL ? 4'd11 : 4'd7)) begin
			clk_cpu_en_ctr <= 4'd0;
			clk_cpu_en <= 1;
		end else begin
			clk_cpu_en_ctr <= clk_cpu_en_ctr + 4'd1;
			clk_cpu_en <= 0;
		end

		// VDC Counter
		if (clk_vdc_en_ctr >= (PAL ? 4'd9 : 4'd5)) begin
			clk_vdc_en_ctr <= 4'd0;
			clk_vdc_en <= 1;
		end else begin
			clk_vdc_en_ctr <= clk_vdc_en_ctr + 4'd1;
			clk_vdc_en <= 0;
		end
	end
end


////////////////////////////  SYSTEM  ///////////////////////////////////


vp_console vp
(
	// System
	.is_pal_g       (PAL),
	.clk_i          (clk_sys),
	.clk_cpu_en_i   (clk_cpu_en),
	.clk_vdc_en_i   (clk_vdc_en),
	
	.res_n_i        (~reset & joy_reset), // low to reset

	// Cart Data
	.cart_cs_o      (cart_cs),
	.cart_cs_n_o    (cart_cs_n),
	.cart_wr_n_o    (cart_wr_n),   // Cart write
	.cart_a_o       (cart_addr),   // Cart Address
	.cart_d_i       (cart_do), // Cart Data
	.cart_d_o       (cart_di),     // Cart data out
	.cart_bs0_o     (cart_bank_0), // Bank switch 0
	.cart_bs1_o     (cart_bank_1), // Bank Switch 1
	.cart_psen_n_o  (cart_rd_n),   // Program Store Enable (read)
	.cart_t0_i      (kb_read_ack || !ldq), // KB/Voice ack
	.cart_t0_o      (),
	.cart_t0_dir_o  (),
	// Char Rom data
	.char_d_i       (char_do), // Char Data
	.char_a_o       (char_addr),
	.char_en        (char_en),


	// Input
	.joy_up_n_i     (joy_up), //-- idx = 0 : left joystick -- idx = 1 : right joystick
	.joy_down_n_i   (joy_down),
	.joy_left_n_i   (joy_left),
	.joy_right_n_i  (joy_right),
	.joy_action_n_i (joy_action),

	.keyb_dec_o     (kb_dec),
	.keyb_enc_i     (kb_enc),

	// Video
	.r_o            (R),
	.g_o            (G),
	.b_o            (B),
	.l_o            (luma),
	.hsync_n_o      (HSync),
	.vsync_n_o      (VSync),
	.hbl_o          (HBlank),
	.vbl_o          (VBlank),
	
	// Sound
	.snd_o          (snd_o),
	.snd_vec_o      (snd)
);

////////////////////////////////////////////////////////////////////////
rom  rom
(
	.clock(clk_sys),
	.address((ioctl_download && ioctl_index < 3)? ioctl_addr[13:0] : rom_addr),
	.data(ioctl_dout),
	.wren(ioctl_wr&& ioctl_index <3),
	.rden(XROM ? rom_oe_n : ~cart_rd_n),
	.q(cart_do)
);

char_rom  char_rom
(
	.clock(clk_sys),
	.address((ioctl_download && ioctl_index == 3) ? ioctl_addr[8:0] : char_addr),
	.data(ioctl_dout),
	.wren(ioctl_wr && ioctl_index == 3),
	.rden(char_en),
	.q(char_do)
);

wire [11:0] cart_addr;
wire [7:0]  cart_do;
wire [11:0] char_addr;
wire [7:0]  char_do;
wire char_en;
wire cart_bank_0;
wire cart_bank_1;
wire cart_rd_n;
reg [15:0]  cart_size;
wire XROM;
wire rom_oe_n = ~(cart_cs_n & cart_bank_0) & cart_rd_n ;
wire [13:0] rom_addr;

reg old_download = 0;


always @(posedge clk_sys) begin
	old_download <= ioctl_download;
	
	if (~old_download & ioctl_download)
	begin
		cart_size <= 16'd0;
		XROM <= (ioctl_index == 2);
	end
	else if (ioctl_download & ioctl_wr)
		cart_size <= cart_size + 16'd1;
end


always @(*)
  begin
   if (XROM == 1'b1)
	   rom_addr <= {2'b0, cart_addr[11:0]};
	else	    
    case (cart_size)
      16'h1000 : rom_addr <= {1'b0,cart_bank_0, cart_addr[11], cart_addr[9:0]};  //4k
      16'h2000 : rom_addr <= {cart_bank_1,cart_bank_0, cart_addr[11], cart_addr[9:0]};   //8K
      16'h4000 : rom_addr <= {cart_bank_1,cart_bank_0, cart_addr[11:0]}; //12K (16k banked)
      default  : rom_addr <= {1'b0, cart_addr[11], cart_addr[9:0]};
    endcase
  end
  
////////////////////////////  SOUND  ////////////////////////////////////

wire [3:0] snd;
wire cart_wr_n;
wire [7:0] cart_di;

// The Voice info:
// $80 to $FF voice writes
// Voice bank select:
// $E4 internal voice rom bank
// $E8, $E9, and $EA external rom banks
// T0_i high if SP0256 command buffer full


//wire [15:0] audio_out = (VOICE?{snd,snd,snd,snd} | {voice_out[7:0],voice_out[7:0]}:{snd, snd, snd,snd}) ;

assign AUDIO_L = VOICE ? {4'b0,snd,snd,4'b0} + voice_out * 2 :{2'b0, snd, snd,6'b0};//{audio, 6'd0};
assign AUDIO_R = AUDIO_L;
assign AUDIO_S = 1;
assign AUDIO_MIX = 0;

assign AUDIO_R = AUDIO_L;

assign AUDIO_S   = 1;
assign AUDIO_MIX = 0;

////////////////////////////  VIDEO  ////////////////////////////////////


wire R;
wire G;
wire B;
wire luma;

wire HSync;
wire VSync;
wire VBlank;
wire HBlank;

wire ce_pix = clk_vdc_en;

wire [23:0] colors = MODE ? color_lut_pal[{R, G, B, luma}] : color_lut_ntsc[{R, G, B, luma}];

assign CLK_VIDEO = clk_sys;
assign VGA_SL = sl[1:0];
assign VGA_F1 = 0;


wire [2:0] scale = status[11:9];
wire [2:0] sl = scale ? scale - 1'd1 : 3'd0;

reg [15:0] ce_h_cnt;
reg old_h;

always @(posedge ce_pix) begin
	old_h <= HSync;
	ce_h_cnt <= (~old_h & HSync) ? 16'd0 : (ce_h_cnt + 16'd1);
end


wire [9:0] grayscale;
vga_to_greyscale vga_to_greyscale
(
  .r_in  ({colors[23:18],colors[23:20]}),
  .g_in  ({colors[15:10],colors[15:12]}),
  .b_in  ({colors[7:2],colors[7:4]}),
  .y_out (grayscale) 
);


video_mixer #(.LINE_LENGTH(455)) video_mixer
(
	.*,
	.HBlank(status[5] ? ((ce_h_cnt <= 46) || (ce_h_cnt >= 367)) : HBlank),
	.VBlank(VBlank),
	.HSync(~HSync),
	.VSync(~VSync),
	.clk_sys(CLK_VIDEO),
	.ce_pix_out(CE_PIXEL),

	.scandoubler(scale || forced_scandoubler),
	.scanlines(0),
	.hq2x(scale==1),
	.mono(0),

	.R(SCREEN ? grayscale[9:2] : colors[23:16]),
	.G(SCREEN ? grayscale[9:2] : colors[15:8] ),
	.B(SCREEN ? grayscale[9:2] : colors[7:0]  ),

);


////////////////////////////  INPUT  ////////////////////////////////////

// [6-15] = Num Keys
// [5]    = Reset
// [4]    = Action
// [3]    = UP
// [2]    = DOWN
// [1]    = LEFT
// [0]    = RIGHT

wire [6:1] kb_dec;
wire [14:7] kb_enc;
wire kb_read_ack;

wire [10:0] ps2_key;
reg [7:0] ps2_ascii;
reg ps2_changed;
reg ps2_released;

reg [7:0] joy_ascii;
reg [9:0] joy_changed;
reg joy_released;

wire [9:0] joy_numpad = (joya[15:6] | joyb[15:6]);

// If the user tries hard enough with the gamepad they can get keys stuck 
// until they press them again. This could stand to be improved in the future.

always @(posedge clk_sys) begin
	reg old_state;
	reg [9:0] old_joy;

	old_state <= ps2_key[10];
	old_joy <= joy_numpad;
	
	ps2_changed <= (old_state != ps2_key[10]);
	ps2_released <= ~ps2_key[9];
	
	joy_changed <= (joy_numpad ^ old_joy);
	joy_released <= (joy_numpad ? 1'b0 : 1'b1);
	
	if(old_state != ps2_key[10]) begin
		casex(ps2_key[8:0])
			'hX16: ps2_ascii <= "1"; // 1
			'hX1E: ps2_ascii <= "2"; // 2
			'hX26: ps2_ascii <= "3"; // 3
			'hX25: ps2_ascii <= "4"; // 4
			'hX2E: ps2_ascii <= "5"; // 5
			'hX36: ps2_ascii <= "6"; // 6
			'hX3D: ps2_ascii <= "7"; // 7
			'hX3E: ps2_ascii <= "8"; // 8
			'hX46: ps2_ascii <= "9"; // 9
			'hX45: ps2_ascii <= "0"; // 0
			
			'hX1C: ps2_ascii <= "a"; // a
			'hX32: ps2_ascii <= "b"; // b
			'hX21: ps2_ascii <= "c"; // c
			'hX23: ps2_ascii <= "d"; // d
			'hX24: ps2_ascii <= "e"; // e
			'hX2B: ps2_ascii <= "f"; // f
			'hX34: ps2_ascii <= "g"; // g
			'hX33: ps2_ascii <= "h"; // h
			'hX43: ps2_ascii <= "i"; // i
			'hX3B: ps2_ascii <= "j"; // j
			'hX42: ps2_ascii <= "k"; // k
			'hX4B: ps2_ascii <= "l"; // l
			'hX3A: ps2_ascii <= "m"; // m
			'hX31: ps2_ascii <= "n"; // n
			'hX44: ps2_ascii <= "o"; // o
			'hX4D: ps2_ascii <= "p"; // p
			'hX15: ps2_ascii <= "q"; // q
			'hX2D: ps2_ascii <= "r"; // r
			'hX1B: ps2_ascii <= "s"; // s
			'hX2C: ps2_ascii <= "t"; // t
			'hX3C: ps2_ascii <= "u"; // u
			'hX2A: ps2_ascii <= "v"; // v
			'hX1D: ps2_ascii <= "w"; // w
			'hX22: ps2_ascii <= "x"; // x
			'hX35: ps2_ascii <= "y"; // y
			'hX1A: ps2_ascii <= "z"; // z
			'hX29: ps2_ascii <= " "; // space
			
			'hX79: ps2_ascii <= "+"; // +
			'hX7B: ps2_ascii <= "-"; // -
			'hX7C: ps2_ascii <= "*"; // *
			'hX4A: ps2_ascii <= "/"; // /
			'hX55: ps2_ascii <= "="; // /
			'hX1F: ps2_ascii <= 8'h11; // gui l / yes
			'hX27: ps2_ascii <= 8'h12; // gui r / no
			'hX5A: ps2_ascii <= 8'd10; // enter
			'hX66: ps2_ascii <= 8'd8; // backspace
			default: ps2_ascii <= 8'h00;
		endcase
	end else if (joy_numpad) begin
		if (joy_numpad[0])
			joy_ascii <= "1";
		else if (joy_numpad[1])
			joy_ascii <= "2";
		else if (joy_numpad[2])
			joy_ascii <= "3";
		else if (joy_numpad[3])
			joy_ascii <= "4";
		else if (joy_numpad[4])
			joy_ascii <= "5";
		else if (joy_numpad[5])
			joy_ascii <= "6";
		else if (joy_numpad[6])
			joy_ascii <= "7";
		else if (joy_numpad[7])
			joy_ascii <= "8";
		else if (joy_numpad[8])
			joy_ascii <= "9";
		else if (joy_numpad[9])
			joy_ascii <= "0";
		else
			joy_ascii <= 8'h00;		
	end
end

vp_keymap vp_keymap
(
	.clk_i(clk_sys),
	.res_n_i(~reset),
	.keyb_dec_i(kb_dec),
	.keyb_enc_o(kb_enc),
	
	.rx_data_ready_i(ps2_changed || joy_changed),
	.rx_ascii_i(ps2_changed ? ps2_ascii : joy_ascii),
	.rx_released_i(ps2_released && joy_released),
	.rx_read_o(kb_read_ack)
);

// Joystick wires are low when pressed
// Passed as a vector bit 1 = left bit 0 = right
// There is no definition as to which is player 1

wire [1:0] joy_up     = {~joya[3], ~joyb[3]};
wire [1:0] joy_down   = {~joya[2], ~joyb[2]};
wire [1:0] joy_left   = {~joya[1], ~joyb[1]};
wire [1:0] joy_right  = {~joya[0], ~joyb[0]};
wire [1:0] joy_action = {~joya[4], ~joyb[4]};
wire       joy_reset  = ~joya[5] & ~joyb[5];



////////////The Voice /////////////////////////////////////////////////


reg signed [9:0] voice_out;
    
wire ldq;
         

sp0256 sp0256 (
        .clk_2m5    (clk_2m5),
        .reset      (rst_a_n),
        .lrq        (ldq),
        .data_in    (rom_addr[6:0]),
        .ald        (ald),
        .audio_out  (voice_out),
);



wire ald     = !rom_addr[7] | cart_wr_n | cart_cs;
wire rst_a_n;



ls74 ls74
(
  .d     (cart_di[5]),
  .clr   (VOICE? 1'b1: 1'b0),
  .q     (rst_a_n),
  .pre   (1'b1),
  .clk   (ald)
);


////////////////////////////////////////////////////////////////////////////////////////////////////////////////	

// LUT using calibrated palette
wire [23:0] color_lut_ntsc[16] = '{
	24'h000000,    //BLACK
	24'h676767,    //BLACK LUMA
	24'h1a37be,
	24'h5c80f6,
	24'h006d07,
	24'h56c469,
	24'h2aaabe,
	24'h77e6eb,
	24'h790000,    //RED
	24'hc75151,    //RED LUMA
	24'h94309f,
	24'hdc84e8,
	24'h77670b,
	24'hc6b86a,
	24'hcecece,     //WHITE 
	24'hffffff      //WHITE LUMA
};

wire [23:0] color_lut_pal[16] = '{
	24'h000000,    //BLACK
	24'h494949,    //BLACK LUMA
	24'h0000B6,    //Blue
	24'h4949ff,
	24'h00B601,    //Green
	24'h49ff49,
	24'h00b6c9,    //Cyan
	24'h49ffff,
	24'hB60000,    //RED
	24'hff4949,    //RED LUMA
	24'hb600b6,    //magenta     
	24'hff49ff,
	24'hb6b600,    //Yellow    
	24'hffff49,
	24'hb6b6b6,     //WHITE 
	24'hffffff      //WHITE LUMA
};


endmodule