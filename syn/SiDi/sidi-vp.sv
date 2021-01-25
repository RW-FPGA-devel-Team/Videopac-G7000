//============================================================================
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
//============================================================================



module sidi_vp
(       
        output        LED,                                              
        output  [5:0] VGA_R,
        output  [5:0] VGA_G,
        output  [5:0] VGA_B,
        output        VGA_HS,
        output        VGA_VS,
        output        AUDIO_L,
        output        AUDIO_R,  
        input         SPI_SCK,
        output        SPI_DO,
        input         SPI_DI,
        input         SPI_SS2,
        input         SPI_SS3,
        input         CONF_DATA0,
        input         CLOCK_27,
		  input         TAPE_IN,
		  input         UART_RX,
		  output        UART_TX,
		  
		          
		  output [12:0] SDRAM_A,
		  inout  [15:0] SDRAM_DQ,
        output        SDRAM_DQML,
        output        SDRAM_DQMH,
        output        SDRAM_nWE,
        output        SDRAM_nCAS,
        output        SDRAM_nRAS,
        output        SDRAM_nCS,
        output  [1:0] SDRAM_BA,
        output        SDRAM_CLK,
        output        SDRAM_CKE
);

assign   SDRAM_CKE = 1'b0;
assign   SDRAM_CLK = 1'b0;
assign   SDRAM_nCS = 1'b1;

assign UART_TX = 'Z;

//////////////////////////////////////////////////////////////////

`include "build_id.v"
parameter CONF_STR = {
	"VIDEOPAC;;",
	"F,BIN,Load catridge;",
	"F,ROM,Load XROM;",
	"F,CHR,Change VDC font;",
	"OE,System,Odyssey2,Videopac;",
	"O5,Palette,NTSC,PAL;",
	"O9B,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;",
	"O1,The Voice,Off,on;",
	"O7,Swap Joysticks,No,Yes;",
	"T0,Reset;",
	"V,v",`BUILD_DATE
};

wire  [1:0] buttons;
wire [31:0] status;
wire        scandoubler_disable;

wire        ioctl_download;
wire [24:0] ioctl_addr;
wire [7:0]  ioctl_dout;
wire        ioctl_wait;
wire        ioctl_wr;
wire  [7:0] ioctl_index;
wire [15:0] joystick_0,joystick_1;
wire [24:0] ps2_mouse;

wire ypbpr;


wire        PAL  = status[14];
wire        VOICE = status[1];
wire        MODE = status[5];

wire        joy_swap = status[7];

wire [15:0] joya = joy_swap ? joystick_1 : joystick_0;
wire [15:0] joyb = joy_swap ? joystick_0 : joystick_1;


mist_io #(.STRLEN($size(CONF_STR)>>3)) mist_io
(
   .SPI_SCK   (SPI_SCK),
	.CONF_DATA0(CONF_DATA0),
	.SPI_SS2   (SPI_SS2),
	.SPI_DO    (SPI_DO),
	.SPI_DI    (SPI_DI),

	.clk_sys   (clk_sys),
	.conf_str  (CONF_STR),
	
   .ioctl_ce(1),
	.ioctl_download(ioctl_download),
	.ioctl_wr  (ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_index(ioctl_index),
	.buttons   (buttons),
	.status    (status),
	.scandoubler_disable(scandoubler_disable),

	.joystick_0(joystick_0),
	.joystick_1(joystick_1),
	
	.ypbpr     (ypbpr),

	.ps2_key   (ps2_key)
);



///////////////////////   CLOCKS   ///////////////////////////////

wire clock_locked;
wire clk_sys_o2;
wire clk_sys_vp;
wire clk_voice;

wire clk_sys = PAL ? clk_sys_vp : clk_sys_o2;

pll pll
(
	.inclk0(CLOCK_27),
	.areset(0),
	.c0(clk_sys_o2),
	.c1(clk_sys_vp),
	.c2(clk_voice),
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



/////////////////////////////////////////////////////////////////

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

/////////////////////////////////////////////////////////////////



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


wire [2:0] scale = status[11:9];
wire [2:0] sl = scale ? scale - 1'd1 : 3'd0;

reg [15:0] ce_h_cnt;
reg old_h;

always @(posedge ce_pix) begin
	old_h <= HSync;
	ce_h_cnt <= (~old_h & HSync) ? 16'd0 : (ce_h_cnt + 16'd1);
end

video_mixer #(.LINE_LENGTH(455)) video_mixer
(
	.*,
	.HSync(~HSync),
	.VSync(~VSync),
	.clk_sys(clk_sys),
	.ce_pix_actual(ce_pix),
	.scandoubler_disable(scandoubler_disable),
	.scanlines(scandoubler_disable ? 2'b00 : {scale==3, scale==2}),
	//.scanlines(0),
	.hq2x(scale==1),
	.mono(0),
	
	.line_start(0),
	.ypbpr_full(1),

	.R({colors[23:16]  >>2}),
	.G({colors[15:8]   >>2}),
	.B({colors[7:0]    >>2})

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


////////////////////////////  MEMORY  ///////////////////////////////////


wire [11:0] cart_addr;
wire [7:0]  cart_do;
wire [11:0] char_addr;
wire [7:0] char_do;
wire char_en;
wire cart_bank_0;
wire cart_bank_1;
wire cart_rd_n;
reg [15:0] cart_size;
wire XROM;
wire rom_oe_n = ~(cart_cs_n & cart_bank_0) & cart_rd_n ;
wire [13:0] rom_addr;

rom  rom
(
	.clock(clk_sys),
	.address((ioctl_download && ioctl_index[1:0] < 3)? ioctl_addr[13:0] : rom_addr),
	.data(ioctl_dout),
	.wren(ioctl_wr&& ioctl_index[1:0] < 3),
	.rden(XROM ? rom_oe_n : ~cart_rd_n),
	.q(cart_do)
);

char_rom  char_rom
(
	.clock(clk_sys),
	.address((ioctl_download && ioctl_index[1:0] == 3) ? ioctl_addr[8:0] : char_addr),
	.data(ioctl_dout),
	.wren(ioctl_wr && ioctl_index[1:0] == 3),
	.rden(char_en),
	.q(char_do)
);

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

//////////////////////////////// SOUND /////////////////////////////////////////////

wire snd_o;
wire the_voice;
wire [3:0] snd;
wire cart_wr_n;
wire [7:0] cart_di;

dac #(
   .c_bits         (16))
  audiodac_l(
   .clk_i        (clk_sys),
   .res_n_i      (1      ),
   .dac_i        (audio_out),
   .dac_o        (AUDIO_L)
  );

wire [15:0] audio_out = (VOICE?{snd, snd, snd,snd} | voice_out[14:0]:{snd,snd,snd,snd,snd}) ;

assign AUDIO_R = AUDIO_L;


////////////The Voice /////////////////////////////////////////////////

wire sample_stb;
reg signed [15:0] signed_voice_out;
reg        [15:0] voice_out;
    
wire ldq;
         

SPEECH256_TOP speech256 (
        .clk        (clk_voice),
        .rst_an     (rst_a_n),
        .ldq        (ldq),
        .data_in    (rom_addr[6:0]),
        .data_stb   (ald_n),
        .pwm_out    (the_voice),
        .sample_out (signed_voice_out),
        .sample_stb ()
);




wire ald_n   = !(!rom_addr[7] | cart_wr_n | cart_cs);
wire rst_a_n ;

ls74 ls74
(
  .d     (cart_di[5]),
  .clr   (VOICE? 1'b1: 1'b0),
  .q     (rst_a_n),
  .pre   (1'b1),
  .clk   (!ald_n)
);


always @* begin
  if (signed_voice_out < 16'd0) begin
    voice_out = ~signed_voice_out;
  end
  else begin
    voice_out = signed_voice_out ;
  end
end

///////////////////////////////////////////////////////////////////////


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
