-------------------------------------------------------------------------------
--
-- FPGA Videopac
--
-- $Id: zefant_xs3_vp.vhd,v 1.18 2007/04/07 10:49:05 arnim Exp $
-- $Name: videopac_rel_1_0 $
--
-- Toplevel of the Spartan3 port for Simple Solutions' Zefant-XS3 board.
--   http://zefant.de/
--
-- Ported to ZX-Uno by yomboprime 2018
--
-------------------------------------------------------------------------------
--
-- Copyright (c) 2007, Arnim Laeuger (arnim.laeuger@gmx.net)
--
-- All rights reserved
--
-- Redistribution and use in source and synthezised forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- Redistributions of source code must retain the above copyright notice,
-- this list of conditions and the following disclaimer.
--
-- Redistributions in synthesized form must reproduce the above copyright
-- notice, this list of conditions and the following disclaimer in the
-- documentation and/or other materials provided with the distribution.
--
-- Neither the name of the author nor the names of other contributors may
-- be used to endorse or promote products derived from this software without
-- specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--
-- Please report bugs to the author, but before you do so, please
-- make sure that this is not a derivative work and that
-- you have the latest version of this file.
--
-------------------------------------------------------------------------------

library IEEE;
use ieee.std_logic_1164.all;
Library UNISIM;
use UNISIM.vcomponents.all;

entity videopac_zxdos_lx16 is
  port (

    -- Clock oscillator
    clk50mhz                     : in    std_logic;
    
    -- SD card
    sd_clk                      : out    std_logic;
    sd_mosi                     : out    std_logic;
    sd_miso                     : in    std_logic;
    sd_cs_n                     : out    std_logic;
    
    -- SRAM
    --sram_addr                    : out   std_logic_vector(18 downto 0);
	 sram_addr                    : out   std_logic_vector(20 downto 0);
    sram_data                    : inout std_logic_vector(7 downto 0);
    sram_we_n                    : out   std_logic;
--	 sram_ub_n                    : out   std_logic;
--	 sram_lb_n                    : out   std_logic;


    -- User Interface
    testled0                      : out   std_logic;
	 testled1                      : out   std_logic;
    
    --debugled                     : out   std_logic_vector(7 downto 0);

    VGA_R                    : out   std_logic_vector(5 downto 0);
    VGA_G                    : out   std_logic_vector(5 downto 0);
    VGA_B                    : out   std_logic_vector(5 downto 0);
    hsync                : out   std_logic;
    --vid_psave_n              : out   std_logic;
    --vid_sync_n               : out   std_logic;
    vsync                : out   std_logic;
    
    clkps2                : inout   std_logic;
    dataps2               : inout   std_logic;
    
    joy_data              : in   std_logic;
    joy_load_n            : out   std_logic;
    joy_clk               : out   std_logic;
    
    audioL                : out std_logic;
    audioR                : out std_logic

  );
end videopac_zxdos_lx16;


library ieee;
use ieee.numeric_std.all;
 
library unisim;
use unisim.vcomponents.all;

use work.tech_comp_pack.vp_por;
use work.vp_console_comp_pack.vp_console;
--use work.board_misc_comp_pack.mc_ctrl;
use work.board_misc_comp_pack.dblscan;
use work.board_misc_comp_pack.vga_scandoubler;
use work.i8244_col_pack.all;
use work.board_misc_comp_pack.vp_keymap;
use work.ps2_keyboard_comp_pack.ps2_keyboard_interface;
use work.i8244_col_pack.all;

--use work.joydecoder;
 
architecture struct of videopac_zxdos_lx16 is

  -----------------------------------------------------------------------------
  -- Include multicard controller
  --
  -- Settings the following constant to true, includes the multicard
  -- controller. It supports selecting several cartridge images on SR1 by
  -- software.
  -- If it's set to false, one single cartridge image will be expected at SR1.
  --
  constant multi_card_c : boolean := false;
  --
  -----------------------------------------------------------------------------

--  component zxuno_xs6_pll
--    port (
--      clkin_i    : in  std_logic;
--      locked_o   : out std_logic;
--      clk_43m_o  : out std_logic;
--      clk_21m5_o : out std_logic
--    );
--  end component;

  component relojes_pll
  port
	 (-- Clock in ports
	  CLK_IN1           : in     std_logic; --50Mhz
	  -- Clock out ports
	  CLK_OUT1          : out    std_logic; --50Mhz
	  CLK_OUT2          : out    std_logic; --70.833Mhz
	  CLK_OUT3          : out    std_logic; --42.500Mhz
     -- Status and control signals
	  LOCKED            : out    std_logic
	 );
  end component;

  component rom_vp
    port(
      --Clk : in  std_logic;
      A   : in  std_logic_vector(12 downto 0);
      D   : out std_logic_vector(7 downto 0)
    );
  end component;
  
  component joydecoder
    port (
      clk: in  std_logic;
      joy_data: in  std_logic;
      joy_clk: out  std_logic;
      joy_load_n: out  std_logic;
      joy1up: out  std_logic;
      joy1down: out  std_logic;
      joy1left: out  std_logic;
      joy1right: out  std_logic;
      joy1fire1: out  std_logic;
      joy1fire2: out  std_logic;
      joy1fire3: out  std_logic;
      joy1start: out  std_logic;
      joy2up: out  std_logic;
      joy2down: out  std_logic;
      joy2left: out  std_logic;
      joy2right: out  std_logic;
      joy2fire1: out  std_logic;
      joy2fire2: out  std_logic;
      joy2fire3: out  std_logic;
      joy2start: out  std_logic
    );
  end component;

  component rom_loader
    port (
      clk: in  std_logic;
      clk21m: in  std_logic;
		reset: in  std_logic;
      --SRAM
      sram_addr: out std_logic_vector(18 downto 0);
      sram_data: inout std_logic_vector(7 downto 0);
      sram_we_n: out  std_logic;
      -- ROM ADDR
      rom_addr: out std_logic_vector(13 downto 0);
      -- CHAR RAM
      char_addr: out std_logic_vector(8 downto 0);
      char_data: out std_logic_vector(7 downto 0);
      char_we  : out std_logic;
      --VP
      --vp_addr: in std_logic_vector(12 downto 0);
      cart_addr: in std_logic_vector(11 downto 0);
      cart_bs0: in  std_logic;
      cart_bs1: in  std_logic;
      vp_data: out std_logic_vector(7 downto 0);
      vp_en_n: in  std_logic;
      vp_rst_n: out std_logic;
		host_bootdata: in  std_logic_vector(31 downto 0);
	   host_bootdata_req: in  std_logic;
      host_bootdata_reset: in  std_logic;
		host_bootdata_ack: out std_logic;
		host_bootdata_size: in  std_logic_vector(15 downto 0);
		currentROM: out std_logic_vector(15 downto 0);
	   loadchr: in  std_logic;
      test_rom: in  std_logic;
		test_led: out  std_logic
    );
  end component;

  component dac
  generic (
    msbi_g : integer := 7
  );
  port (
    clk_i   : in  std_logic;
    res_n_i : in  std_logic;
    dac_i   : in  std_logic_vector(msbi_g downto 0);
    dac_o   : out std_logic
  );
  end component;


  component charset_ram
  generic (
    addr_width_g : integer := 9;
    data_width_g : integer := 8
  );
  port (
    clk_a_i  : in  std_logic;
    we_i     : in  std_logic;
    rd_i     : in  std_logic;
    addr_a_i : in  std_logic_vector(addr_width_g-1 downto 0);
    data_a_i : in  std_logic_vector(data_width_g-1 downto 0);
    data_a_o : out std_logic_vector(data_width_g-1 downto 0)
  );
  end component;

   component sp0256 is
   port
   (
      clk_2m5     : in std_logic;
      reset          : in std_logic;
      lrq            : out std_logic;
      data_in        : in  std_logic_vector(6 downto 0);
      ald            : in  std_logic;
      audio_out      : out std_logic_vector(9 downto 0)
   );
   end component;

   component compressor is
   port(
      clk : in  std_logic;
      din : in  signed(9 downto 0);
      dout: out std_logic_vector(8 downto 0)
   );
   end component;

   component ls74 is
   port(d,
        clr,
        pre,
        clk   : IN std_logic;
        q     : OUT std_logic);
   end component;

  signal dcm_locked_s   : std_logic;
  signal reset_n_s,
         reset_s        : std_logic;
  signal reset_v_n_s      : std_logic; -- reset the voice
         
  signal reset_video_s   : std_logic;
  signal reset_video_n_s   : std_logic;
  signal por_n_s        : std_logic;
  signal clk_43m_s      : std_logic;
  --signal clk_21m5_s     : std_logic;
  signal clk_50m_s      : std_logic; --50Mhz
  signal clk_71m_s      : std_logic; --70.833Mhz
  signal clk_2m5_s      : std_logic; --2.5 Mhz

  signal clk_sys       :  std_logic;
  signal clk_cpu       :  std_logic;
  signal clk_vdc       :  std_logic;
  signal clk_vga       :  std_logic;
  signal clk_main       :  std_logic;
  signal is_pal_s      :  std_logic;
  signal is_pal_i      :  integer;
  signal clk_sysp, clk_sysp_next :  std_logic;
  signal clk_sysn, clk_sysn_next :  std_logic;
  
  signal glob_res_n_s   : std_logic;
  
  signal control_rst_n    : std_logic;

  -- Relojes NTSC (Odyssey2)
  -- CPU clock counter = PLL clock 42.5 MHz / 8 = 5.312
  constant cnt_cpu_cn    : unsigned(3 downto 0) := to_unsigned(7, 4);
  -- VDC clock = PLL clock 42.5 MHz / 6 = 7.083
  -- note: VDC core runs with double frequency than compared with 8244 chip
  constant cnt_vdc_cn    : unsigned(3 downto 0) := to_unsigned(5, 4);
  -- VGA clock = PLL clock 42.5 MHz / 3 (2x VDC clock) = 14.166
  constant cnt_vga_cn    : unsigned(3 downto 0) := to_unsigned(2, 4);
  -- The voice clock = PLL clock 42.5 MHz / 16 (2x VDC clock) = 2.656
  constant cnt_voice_cn  : unsigned(4 downto 0) := to_unsigned(16, 5);
  --
  signal cnt_cpu_qn      : unsigned(3 downto 0);
  signal cnt_vdc_qn      : unsigned(3 downto 0);
  signal cnt_vga_qn      : unsigned(3 downto 0);
  signal cnt_voice_qn    : unsigned(4 downto 0);
  signal clk_cpu_en_sn,
         clk_vdc_en_sn,
         clk_vga_en_qn,
         clk_voice_en_qn : std_logic;

  -- Relojes PAL (Videopac)
  -- CPU clock counter = PLL clock 70.83 MHz / 12 = 5.9027
  constant cnt_cpu_cp    : unsigned(3 downto 0) := to_unsigned(11, 4);
  -- VDC clock = PLL clock 70.83 MHz / 10 = 7.083
  -- note: VDC core runs with double frequency than compared with 8244 chip
  constant cnt_vdc_cp    : unsigned(3 downto 0) := to_unsigned(9, 4);
  -- VGA clock = PLL clock 70.83 MHz / 5 (2x VDC clock)  = 14.166
  constant cnt_vga_cp    : unsigned(3 downto 0) := to_unsigned(4, 4);
  --
  signal cnt_cpu_qp      : unsigned(3 downto 0);
  signal cnt_vdc_qp      : unsigned(3 downto 0);
  signal cnt_vga_qp      : unsigned(3 downto 0);
  signal clk_cpu_en_sp,
         clk_vdc_en_sp,
         clk_vga_en_qp   : std_logic;

  signal cart_a_s       : std_logic_vector(11 downto 0);
  signal rom_a_s        : std_logic_vector(12 downto 0);
  
  signal cart_d_s,
         cart_d_from_vp_s: std_logic_vector( 7 downto 0);
  signal cart_bs0_s,
         cart_bs1_s,
         cart_psen_n_s  : std_logic;
  signal rom_addr_s: std_logic_vector(13 downto 0);
  
   signal but_up_s,
          but_down_s,
          but_left_s,
          but_right_s,
          but_action_s    : std_logic_vector( 1 downto 0);

    signal but_up_s0,
           but_down_s0,
           but_left_s0,
           but_right_s0,
           but_action_s0,
			  but_f2_s0,
           but_up_s1,
           but_down_s1,
           but_left_s1,
           but_right_s1,
           but_action_s1,
			  but_f2_s1      : std_logic;

  signal rgb_r_s,
         rgb_g_s,
         rgb_b_s,
         rgb_l_s        : std_logic;
  signal rgb_hsync_n_s,
         rgb_hsync_s,
         rgb_vsync_n_s,
         rgb_vsync_s    : std_logic;
  signal vga_r_s,
         vga_g_s,
         vga_b_s,
         vga_l_s        : std_logic;
  signal vga_hsync_s,
         vga_vsync_s    : std_logic;
--   signal blank_s        : std_logic;
  signal snd_s          : std_logic;
  signal snd_vec_s      : std_logic_vector( 3 downto 0);
--   signal pcm_audio_s    : signed(8 downto 0);

	signal audio_s    : std_logic;
   signal dac_i_s    : std_logic_vector( 10 downto 0);

--   signal aud_bit_clk_s  : std_logic;

  signal hpos: std_logic_vector(8 downto 0);
  signal vpos: std_logic_vector(8 downto 0);
  signal oddLine: std_logic;

  signal keyb_dec_s      : std_logic_vector( 6 downto 1);
  signal keyb_enc_s      : std_logic_vector(14 downto 7);
  signal rx_data_ready_s : std_logic;
  signal rx_ascii_s      : std_logic_vector( 7 downto 0);
  signal rx_released_s   : std_logic;
  signal rx_extended_s     : std_logic;
  signal rx_read_s       : std_logic;
-- the voice signals
  signal ldq_s            : std_logic;
  signal ald_s            : std_logic;
  signal signed_voice_o_s : signed(9 downto 0);
  signal voice_os_s       : std_logic_vector(9 downto 0);
  signal voice_o_s        : std_logic_vector(8 downto 0);
  signal voice_on_s       : std_logic;
  

  signal cart_cs_s,
         cart_cs_n_s,
         cart_wr_n_s     : std_logic;
--  signal extmem_a_s      : std_logic_vector(18 downto 0);

  signal gnd8_s : std_logic_vector(7 downto 0);
  
  signal currentROM: std_logic_vector(15 downto 0);

  -- function keys
  signal keyb_f1 : std_logic;
  signal keyb_f2 : std_logic;
  signal keyb_f3 : std_logic;
  
  -- use test rom
  signal test_rom : std_logic;

  -- Control module
  signal osd_bkgr: std_logic_vector(2 downto 0);
  signal joy2zpuflex: std_logic_vector(8 downto 0); -- 8: 0 - ZXDOS/1 - ZXUNO, [7:0] - Joystick (SACUDLRB)
  signal key_hard_reset:  std_logic; 
  signal key_videomode, video_mode:  std_logic;
  signal joykeys    : std_logic_vector(15 downto 0);
  signal ps2k_clk_in : std_logic;
  signal ps2k_clk_out : std_logic;
  signal ps2k_dat_in : std_logic;
  signal ps2k_dat_out : std_logic;
  
  -- Host control signals, from the Control module
  signal host_reset_n: std_logic;
  signal host_divert_sdcard : std_logic;
  signal host_divert_keyboard : std_logic;
  signal host_ps2_data : std_logic;
  signal host_ps2_clk : std_logic;
  signal host_pal : std_logic;
  signal host_select : std_logic;
  signal host_start : std_logic;

  signal host_bootdata : std_logic_vector(31 downto 0);
  signal host_bootdata_req : std_logic;
  signal host_bootdata_reset : std_logic;
  signal host_bootdata_ack : std_logic;
  signal size: std_logic_vector(15 downto 0) := (others => '0');
  -- Internal video signals:  
  signal vga_vsync_i : std_logic := '0';
  signal vga_hsync_i : std_logic := '0';
  signal vga_hsync_aux : std_logic;
  signal vga_red_i : std_logic_vector(7 downto 0) := (others => '0');
  signal vga_green_i : std_logic_vector(7 downto 0) := (others => '0');
  signal vga_blue_i	: std_logic_vector(7 downto 0) := (others => '0');
  
  signal osd_window : std_logic;
  signal osd_pixel : std_logic;
 
  signal scanlines : std_logic;
  -- Joystick
  signal joy1,joy2: std_logic_vector(11 downto 0);

  signal aux_sd_clk:     std_logic;
  signal aux_sd_mosi:     std_logic;
  signal aux_sd_miso:     std_logic;
  signal aux_sd_cs_n:     std_logic;
  signal swapjoystick_s:     std_logic;
  signal joinjoystick_s:     std_logic;

  -- Joystick type for zxuno
  signal zxunoboard: std_logic_vector(1 downto 0);
  
  -- Monochrome output
  signal vga2grey: std_logic_vector(1 downto 0);
  -- aux video signal for monocrome output
  signal rgb_r_o_prev           : std_logic_vector( 9 downto 0);
  signal rgb_g_o_prev           : std_logic_vector( 9 downto 0);
  signal rgb_b_o_prev           : std_logic_vector( 9 downto 0);
  signal rgb_y_sign             : std_logic_vector( 9 downto 0);
  
  --dipswitches for isim
  signal dipswt_nc              : std_logic_vector(18 downto 0);

  --char rom
  signal char_addr_s  : std_logic_vector( 8 downto 0);
  signal char_addrr_s : std_logic_vector( 8 downto 0);
  signal char_addrw_s : std_logic_vector( 8 downto 0);
  signal char_do_s   : std_logic_vector( 7 downto 0);
  signal char_di_s   : std_logic_vector( 7 downto 0);
  signal char_we_s   : std_logic;
  signal char_en_s   : std_logic;
  signal loadchr_s   : std_logic;
  
begin

	audioL <= audio_s;
	audioR <= audio_s;
	
	gnd8_s <= (others => '0');

	-- Reset
	glob_res_n_s <= por_n_s and dcm_locked_s and control_rst_n;
	reset_n_s <= glob_res_n_s and dcm_locked_s  --;-- and
					and not(keyb_f1 or keyb_f2 or keyb_f3)
					and host_reset_n;
               --(but_tl_s(0) or but_tr_s(0));
	reset_s   <= not reset_n_s;
	
	reset_video_n_s <= por_n_s and dcm_locked_s;
	reset_video_s <= not reset_video_n_s;
	
  -----------------------------------------------------------------------------
  -- Power-on reset module
  -----------------------------------------------------------------------------
  por_b : vp_por
    generic map (
      delay_g     => 6,
      cnt_width_g => 3
    )
    port map (
      clk_i   => clk_43m_s,
      por_n_o => por_n_s
    );

  -----------------------------------------------------------------------------
  -- The PLL
  -----------------------------------------------------------------------------
--  pll_b : zxuno_xs6_pll
--    port map (
--      clkin_i    => clk50mhz,
--      locked_o   => dcm_locked_s,
--      clk_43m_o  => clk_43m_s,     --42.857Mhz
--      clk_21m5_o => clk_21m5_s     --21.428Mhz
--    );

  pll_dual : relojes_pll
  port map
	 (-- Clock in ports
	  CLK_IN1           => clk50mhz, --50Mhz
	  -- Clock out ports
	  CLK_OUT1          => clk_50m_s,       --50Mhz
	  CLK_OUT2          => clk_71m_s,       --70.833Mhz
	  CLK_OUT3          => clk_43m_s,       --42.500Mhz
     --CLK_OUT3          => clk_50m_s,       --50Mhz
	  -- Status and control signals
	  LOCKED            => dcm_locked_s
	 );

-- Original Clocks:
-- Standard    NTSC           PAL
-- Main clock  42.95454       70.9379 
-- Sys  clock  21.47727 MHz   35.46895 MHz // ntsc/pal colour carrier times 3/4 respectively
-- VDC divider 3              5
-- VDC clock   7.159 MHz      7.094 MHz
-- CPU divider 4              6
-- CPU clock   5.369 MHz      5.911 MHz

-- Core Clocks:
-- Standard    NTSC           PAL
-- Main clock  42.500         70.833 
-- Sys clock   21.25 MHz      35.41666 MHz // ntsc/pal colour carrier times 3/4 respectively
-- VGA divider 3              5
-- VGA clok    14,1666        14,16666
-- VDC divider 6              10
-- VDC clock   7.0833 MHz     7.0833 MHz
-- CPU divider 4              6
-- CPU clock   5.3125 MHz     5.9027 MHz
-- Voice clk divider 16
-- Voice clock 2.656


  -----------------------------------------------------------------------------
  -- Process clk_en
  --
  -- Purpose:
  --   Generates the CPU and VDC clock enables.
  --   For NTSC signal
  clk_en: process (clk_43m_s, reset_video_s)
  begin
    if reset_video_s = '1' then
      cnt_cpu_qn    <= cnt_cpu_cn;
      cnt_vdc_qn    <= cnt_vdc_cn;
		cnt_vga_qn    <= cnt_vga_cn;
      cnt_voice_qn  <= cnt_voice_cn;
		clk_vga_en_qn <= '0';
      --clk_vdc_en_sn <= '0';
		clk_sysn <= '0';
    elsif rising_edge(clk_43m_s) then
      clk_sysn <= clk_sysn_next; --not clk_sysn; --'1' when clk_sysn = '0' else '0';
      --CPU
		if clk_cpu_en_sn = '1' then
        cnt_cpu_qn <= cnt_cpu_cn;
      else
        cnt_cpu_qn <= cnt_cpu_qn - 1;
      end if;
      --VDC
      if clk_vdc_en_sn = '1' then
        cnt_vdc_qn <= cnt_vdc_cn;
      else
        cnt_vdc_qn <= cnt_vdc_qn - 1;
      end if;
		--VGA
      if cnt_vga_qn = 0 then
        cnt_vga_qn    <= cnt_vga_cn;
        clk_vga_en_qn <= '1';
        --clk_vdc_en_sn <= not clk_vdc_en_sn;
      else
        cnt_vga_qn    <= cnt_vga_qn - 1;
        clk_vga_en_qn <= '0';
      end if;				

      --THE VOICE
      if clk_2m5_s = '1' then
        cnt_voice_qn <= cnt_voice_cn;
      else
        cnt_voice_qn <= cnt_voice_qn - 1;
      end if;

    end if;
  end process clk_en;
  --
  clk_sysn_next <= '1' when clk_sysn = '0' else '0';
  clk_cpu_en_sn <= '1' when cnt_cpu_qn = 0 else '0';
  clk_vdc_en_sn <= '1' when cnt_vdc_qn = 0 else '0';
  clk_2m5_s <= '1' when cnt_voice_qn = 0 else '0';
--  clk_vga_en_qn <= '1' when cnt_vga_qn = 0 else '0';
  --
  -----------------------------------------------------------------------------
  -- Process clk_en
  --
  -- Purpose:
  --   Generates the CPU and VDC clock enables.
  --   For PAL signal
  clk_ep: process (clk_71m_s, reset_video_s)
  begin
	 if reset_video_s = '1' then
      cnt_cpu_qp    <= cnt_cpu_cp;
      cnt_vdc_qp    <= cnt_vdc_cp;
		cnt_vga_qp    <= cnt_vga_cp;
		--clk_vga_en_qp <= '0';
		clk_sysp <= '0';
    elsif rising_edge(clk_71m_s) then
      clk_sysp <= clk_sysp_next; --not clk_sysp; --'1' when clk_sysp = '0' else '0';
      --CPU
		if clk_cpu_en_sp = '1' then
        cnt_cpu_qp <= cnt_cpu_cp;
      else
        cnt_cpu_qp <= cnt_cpu_qp - 1;
      end if;
      --VDC
      if clk_vdc_en_sp = '1' then
        cnt_vdc_qp <= cnt_vdc_cp;
      else
        cnt_vdc_qp <= cnt_vdc_qp - 1;
      end if;
		--VGA
      if cnt_vga_qp = 0 then
        cnt_vga_qp    <= cnt_vga_cp;
        clk_vga_en_qp <= '1';
      else
        cnt_vga_qp    <= cnt_vga_qp - 1;
        clk_vga_en_qp <= '0';
      end if;		
    end if;
  end process clk_ep;
  --
  clk_sysp_next <= '1' when clk_sysp = '0' else '1';
  clk_cpu_en_sp <= '1' when cnt_cpu_qp = 0 else '0';
  clk_vdc_en_sp <= '1' when cnt_vdc_qp = 0 else '0';
--  clk_vga_en_qp <= '1' when cnt_vga_cp = 0 else '0';
  --

   -----------------------------------------------------------------------------
   -- Process clock selection
   -----------------------------------------------------------------------------
   -- Purpose:
   --   Generates the global clocks depending on model (PAL/NTSC).
   --
 
   -- BUFGMUX: Global Clock Mux Buffer
   --          Spartan-6
   -- Xilinx HDL Language Template, version 14.7

   BUFGMUX_inst : BUFGMUX
   generic map (
      CLK_SEL_TYPE => "SYNC"  -- Glitchles ("SYNC") or fast ("ASYNC") clock switch-over
   )
   port map (
      O => clk_main,          -- 1-bit output: Clock buffer output
      I0 => clk_43m_s,        -- 1-bit input: Clock buffer input (S=0)
      I1 => clk_71m_s,        -- 1-bit input: Clock buffer input (S=1)
      S => is_pal_s           -- 1-bit input: Clock buffer select
   );
  
   --clk_sys <= clk_sysp when (is_pal_s = '1') else clk_sysn;
   BUFGMUX_inst2 : BUFGMUX
   generic map (
      CLK_SEL_TYPE => "SYNC"  -- Glitchles ("SYNC") or fast ("ASYNC") clock switch-over
   )
   port map (
      O => clk_sys,          -- 1-bit output: Clock buffer output
      I0 => clk_sysn,        -- 1-bit input: Clock buffer input (S=0)
      I1 => clk_sysp,        -- 1-bit input: Clock buffer input (S=1)
      S => is_pal_s           -- 1-bit input: Clock buffer select
   );

  clk_cpu <= clk_cpu_en_sp when (is_pal_s = '1') else clk_cpu_en_sn;
  clk_vdc <= clk_vdc_en_sp when (is_pal_s = '1') else clk_vdc_en_sn;
  clk_vga <= clk_vga_en_qp when (is_pal_s = '1') else clk_vga_en_qn;
  
   -----------------------------------------------------------------------------
	-- Rom management
   -----------------------------------------------------------------------------

--	sram_ub_n <= '1';
--	sram_lb_n <= '0';
	sram_addr(20 downto 19) <= "00";
	
    romload : rom_loader
    port map (
		clk => clk_43m_s,
      clk21m => clk_sysn,
		reset => not host_reset_n,
      sram_addr => sram_addr(18 downto 0),
      sram_data => sram_data,
      sram_we_n => sram_we_n,
      rom_addr  => rom_addr_s,
      char_addr => char_addrw_s,
      char_data => char_di_s,
      char_we   => char_we_s,
      --vp_addr => rom_a_s,
      cart_addr => cart_a_s,
      cart_bs0 => cart_bs0_s,
      cart_bs1 => cart_bs1_s,
      vp_data => cart_d_s,
      vp_en_n => cart_psen_n_s,
      vp_rst_n => control_rst_n,
		host_bootdata => host_bootdata,
		host_bootdata_req => host_bootdata_req,
      host_bootdata_reset => host_bootdata_reset,
		host_bootdata_ack => host_bootdata_ack,
		host_bootdata_size => size,
		currentROM => currentROM,
      loadchr => loadchr_s,
		test_rom => test_rom,
		test_led => testled1
    );

	 testled0 <= not test_rom;
    
  
   is_pal_i <= to_integer(unsigned'('0' & is_pal_s));

  -----------------------------------------------------------------------------
  -- Char rom 
  -----------------------------------------------------------------------------
  char_addr_s <=  char_addrw_s when (loadchr_s = '1')
                  else char_addrr_s;
   
  char_rom : charset_ram
  port map (
    clk_a_i  => clk_main,
    we_i     => char_we_s,
    rd_i     => char_en_s,
    addr_a_i => char_addr_s,
    data_a_i => char_di_s,
    data_a_o => char_do_s
  );   
  
  -----------------------------------------------------------------------------
  -- The Videopac console
  -----------------------------------------------------------------------------
  vp_console_b : vp_console
    port map (
      --is_pal_g => is_pal_s,
      is_pal_g       => is_pal_i,
      clk_i          => clk_main,
      clk_cpu_en_i   => clk_cpu,
      clk_vdc_en_i   => clk_vdc,
      res_n_i        => reset_n_s,
      --cart data
      cart_cs_o      => cart_cs_s,
      cart_cs_n_o    => cart_cs_n_s,
      cart_wr_n_o    => cart_wr_n_s, --Cart write
      cart_a_o       => cart_a_s,    --Cart Address
      cart_d_i       => cart_d_s,    --Cart Data
      cart_d_o       => cart_d_from_vp_s, --Cart data out
      cart_bs0_o     => cart_bs0_s,  --Bank switch 0
      cart_bs1_o     => cart_bs1_s,  --Bank switch 1
      cart_psen_n_o  => cart_psen_n_s, --Program Store Enable (read)
      --cart_t0_i      => gnd8_s(0),
      cart_t0_i      => rx_read_s or not ldq_s,  --KB/Voice ack
      cart_t0_o      => open,
      cart_t0_dir_o  => open,
      -- Char ROM -----------------
      char_a_o       => char_addrr_s,
      char_d_i       => char_do_s,
      char_en        => char_en_s,
      -- Joystick -----------------
      -- idx = 0 : left joystick
      -- idx = 1 : right joystick
      joy_up_n_i     => but_up_s,
      joy_down_n_i   => but_down_s,
      joy_left_n_i   => but_left_s,
      joy_right_n_i  => but_right_s,
      joy_action_n_i => but_action_s,
      -- Keyboard
      keyb_dec_o     => keyb_dec_s,
      keyb_enc_i     => keyb_enc_s,
      -- Video
      r_o            => rgb_r_s,
      g_o            => rgb_g_s,
      b_o            => rgb_b_s,
      l_o            => rgb_l_s,
      hsync_n_o      => rgb_hsync_n_s,
      vsync_n_o      => rgb_vsync_n_s,
      hbl_o          => open,
      vbl_o          => open,
      -- Sound
      snd_o          => snd_s,
      snd_vec_o      => snd_vec_s
    );

    --
    -- Audio dac
    --
    dac1 : dac
    generic map (
      msbi_g => 10
    )
    port map (
      clk_i => clk_vdc, --_en_sp,
      res_n_i => reset_n_s,
      --dac_i => '0' & snd_vec_s,
      dac_i => dac_i_s,
      dac_o => audio_s
    );
    dac_i_s <= "00" & (('0' & snd_vec_s & snd_vec_s) or voice_o_s) when ( voice_on_s = '1')
               else ("000" & snd_vec_s & snd_vec_s);
--   audio_s <= snd_s;

    --
    -- The voice logic
    --
      --// The Voice info:
      --// $80 to $FF voice writes
      --// Voice bank select:
      --// $E4 internal voice rom bank
      --// $E8, $E9, and $EA external rom banks
      --// T0_i high if SP0256 command buffer full
    
    ldq_s <= '1'; --no habilitado
    voice_o_s <= (others=>'0');
    
--    sp0256_imp : sp0256 
--    port map (
--        clk_2m5    => clk_2m5_s,
--        reset      => reset_v_n_s,
--        lrq        => ldq_s,
--        data_in    => rom_addr_s(6 downto 0),
--        ald        => ald_s,
--        audio_out  => voice_os_s
--    );
--    
--    signed_voice_o_s <= signed(voice_os_s);
--    ald_s <= '1' when (rom_addr_s(7) = '0' or  cart_wr_n_s = '1' or cart_cs_s = '1')
--                 else '0';
--    voice_o_s <= voice_os_s(9 downto 1);
----    compressor_imp : compressor
----    port map (
----        clk  => clk_main,
----        din  => signed_voice_o_s,
----        dout => voice_o_s
----    );
--    
--    ls74_imp : ls74
--    port map (
--     d     => cart_d_from_vp_s(5),
--     clr   => voice_on_s,
--     q     => reset_v_n_s,
--     pre   => '1',
--     clk   => ald_s
--    );
    
  -----------------------------------------------------------------------------
  -- Multicard controller
  -----------------------------------------------------------------------------
--  use_mc: if multi_card_c generate
--    mc_ctrl_b : mc_ctrl
--      port map (
--        clk_i       => clk_sys,
--        reset_n_i   => glob_res_n_s,
--        cart_a_i    => cart_a_s,
--        cart_d_i    => cart_d_from_vp_s,
--        cart_cs_i   => cart_cs_s,
--        cart_cs_n_i => cart_cs_n_s,
--        cart_wr_n_i => cart_wr_n_s,
--        cart_bs0_i  => cart_bs0_s,
--        cart_bs1_i  => cart_bs1_s,
--        extmem_a_o  => extmem_a_s
--      );
--  end generate;
--  no_mc: if not multi_card_c generate
--    extmem_a_s <= (others => '0');
--  end generate;


  -----------------------------------------------------------------------------
  -- VGA Scan Doubler
  -----------------------------------------------------------------------------
  rgb_hsync_s <= not rgb_hsync_n_s;
  rgb_vsync_s <= not rgb_vsync_n_s;
  --
  dblscan_b : dblscan
    generic map (
       dbl_adjustn_c  => 20, --20 ZXDOS+ // 22 ZXDOS
       dbl_adjustp_c  => 2
    )
    port map (
      is_pal_in  => is_pal_s,
      RGB_R_IN   => rgb_r_s,
      RGB_G_IN   => rgb_g_s,
      RGB_B_IN   => rgb_b_s,
      RGB_L_IN   => rgb_l_s,
      HSYNC_IN   => rgb_hsync_s,
      VSYNC_IN   => rgb_vsync_s,
      VGA_R_OUT  => vga_r_s,
      VGA_G_OUT  => vga_g_s,
      VGA_B_OUT  => vga_b_s,
      VGA_L_OUT  => vga_l_s,
      HSYNC_OUT  => vga_hsync_s,
      VSYNC_OUT  => vga_vsync_s,
      BLANK_OUT  => open, --blank_s,
      CLK_RGB    => clk_vdc,
      CLK_VGA    => clk_vga,
      RESET_N_I  => reset_video_n_s,
      ODD_LINE   => oddLine
    );

--  vid_clk   <= clk_vga_en_q;
  vga_rgb: process (clk_main, reset_video_s)
    variable col_v : natural range 0 to 15;
  begin
    if reset_video_s ='1' then
      vga_red_i <= (others => '0');
      vga_green_i <= (others => '0');
      vga_blue_i <= (others => '0');
      vga_hsync_i <= '1';
      vga_vsync_i <= '1';
      --vid_blank <= '1';
    elsif rising_edge(clk_main) then
		if video_mode = '0' then --VGA
			if clk_vga = '1' then
			  col_v := to_integer(unsigned'(vga_l_s & vga_r_s & vga_g_s & vga_b_s));

					vga_red_i(7 downto 0) <= std_logic_vector(to_unsigned(full_rgb_table_c(col_v)(r_c), 8));
					vga_green_i(7 downto 0) <= std_logic_vector(to_unsigned(full_rgb_table_c(col_v)(g_c), 8));
					vga_blue_i(7 downto 0) <= std_logic_vector(to_unsigned(full_rgb_table_c(col_v)(b_c), 8));

			  vga_hsync_i <= not vga_hsync_s;
			  vga_vsync_i <= not vga_vsync_s;
			end if;
		else --RGB
			if clk_vdc = '1' then
			  col_v := to_integer(unsigned'(rgb_l_s & rgb_r_s & rgb_g_s & rgb_b_s));

					vga_red_i(7 downto 0) <= std_logic_vector(to_unsigned(full_rgb_table_c(col_v)(r_c), 8));
					vga_green_i(7 downto 0) <= std_logic_vector(to_unsigned(full_rgb_table_c(col_v)(g_c), 8));
					vga_blue_i(7 downto 0) <= std_logic_vector(to_unsigned(full_rgb_table_c(col_v)(b_c), 8));

			  vga_hsync_i <= not rgb_hsync_s;
			  vga_vsync_i <= not rgb_vsync_s;
			end if;
      end if;        
    end if;
  end process vga_rgb;
  
  -- Joysticks
  joys : joydecoder
    port map (
      clk => clk_sysn,
      joy_data => joy_data,
      joy_clk => joy_clk,
      joy_load_n => joy_load_n,
      joy1up => but_up_s1,
      joy1down => but_down_s1,
      joy1left => but_left_s1,
      joy1right => but_right_s1,
      joy1fire1 => but_action_s1,
      joy1fire2 => but_f2_s1,
      joy1fire3 => open,
      joy1start => open,
      joy2up => but_up_s0,
      joy2down => but_down_s0,
      joy2left => but_left_s0,
      joy2right => but_right_s0,
      joy2fire1 => but_action_s0,
      joy2fire2 => but_f2_s0,
      joy2fire3 => open,
      joy2start => open
    );

   but_up_s(0) <= (but_up_s0 and but_up_s1) when (joinjoystick_s = '1') else
                  but_up_s0 when (swapjoystick_s = '0') else but_up_s1;
   but_down_s(0) <= (but_down_s0 and but_down_s1) when (joinjoystick_s = '1') else
                     but_down_s0 when (swapjoystick_s = '0') else but_down_s1;
   but_left_s(0) <= (but_left_s0 and but_left_s1) when (joinjoystick_s = '1') else
                     but_left_s0 when (swapjoystick_s = '0') else but_left_s1;
   but_right_s(0) <= (but_right_s0 and but_right_s1) when (joinjoystick_s = '1') else
                     but_right_s0 when (swapjoystick_s = '0') else but_right_s1;
   but_action_s(0) <= (but_action_s0 and but_action_s1) when (joinjoystick_s = '1') else
                     but_action_s0 when (swapjoystick_s = '0') else but_action_s1;
   
   but_up_s(1) <= (but_up_s0 and but_up_s1) when (joinjoystick_s = '1') else
                     but_up_s1 when (swapjoystick_s = '0') else but_up_s0;
   but_down_s(1) <=  (but_down_s0 and but_down_s1) when (joinjoystick_s = '1') else
                     but_down_s1 when (swapjoystick_s = '0') else but_down_s0;
   but_left_s(1) <=  (but_left_s0 and but_left_s1) when (joinjoystick_s = '1') else
                     but_left_s1 when (swapjoystick_s = '0') else but_left_s0;
   but_right_s(1) <=  (but_right_s0 and but_right_s1) when (joinjoystick_s = '1') else
                     but_right_s1 when (swapjoystick_s = '0') else but_right_s0;
   but_action_s(1) <=  (but_action_s0 and but_action_s1) when (joinjoystick_s = '1') else
                     but_action_s1 when (swapjoystick_s = '0') else but_action_s0;

  -----------------------------------------------------------------------------
  -- Keyboard components
  -----------------------------------------------------------------------------
  vp_keymap_b : vp_keymap
    port map (
      clk_i           => clk_sysn,
      res_n_i         => reset_video_n_s,
      keyb_dec_i      => keyb_dec_s,
      keyb_enc_o      => keyb_enc_s,
      rx_data_ready_i => rx_data_ready_s,
      rx_ascii_i      => rx_ascii_s,
      rx_released_i   => rx_released_s,
      rx_read_o       => rx_read_s
    );
  --
  ps2_keyboard_b : ps2_keyboard_interface
    generic map (
      TIMER_60USEC_VALUE_PP => 1380, -- Number of sys_clks for 60usec
      TIMER_60USEC_BITS_PP  =>   11, -- Number of bits needed for timer
      TIMER_5USEC_VALUE_PP  =>  115, -- Number of sys_clks for debounce
      TIMER_5USEC_BITS_PP   =>    7  -- Number of bits needed for timer
    )
    port map (
      clk             => clk_sysn,
      reset           => reset_video_s,
      ps2_clk         => host_ps2_clk,
      ps2_data        => host_ps2_data,
      rx_extended     => rx_extended_s,
      rx_released     => rx_released_s,
      rx_shift_key_on => open,
      rx_ascii        => rx_ascii_s,
      rx_data_ready   => rx_data_ready_s,
      rx_read         => rx_read_s,
      tx_data         => gnd8_s,
      tx_write        => gnd8_s(0),
      tx_write_ack    => open,
      tx_error_no_keyboard_ack => open,
	   keyb_f1         => keyb_f1,
	   keyb_f2         => keyb_f2,
	   keyb_f3         => keyb_f3
    );

--	-- pal/ntsc selection - F2
--	function_keys_f2 : process(keyb_f2, reset_video_s)
--	begin
--	  if (reset_video_s = '1') then
--			is_pal_s <= '0';
--	  elsif keyb_f2'event and keyb_f2 = '1' then
--			is_pal_s <= not is_pal_s;
--	  end if;
--	end process;

	-- VOICE ON/OFF selection - F2
	function_keys_f2 : process(keyb_f2, reset_video_s)
	begin
	  if (reset_video_s = '1') then
			voice_on_s <= '0';
	  elsif keyb_f2'event and keyb_f2 = '1' then
			voice_on_s <= not voice_on_s;
	  end if;
	end process;

	-- test_rom selection - F1
	function_keys_f1 : process(keyb_f1, reset_video_s)
	begin
	  if (reset_video_s = '1') then
			test_rom <= '0';
	  elsif keyb_f1'event and keyb_f1 = '1' then
			test_rom <= not test_rom;
	  end if;
	end process;

	-- video_mode selection - Scroll-lock
	videomode_keys : process(key_videomode, reset_video_s)
	begin
	  if (reset_video_s = '1') then
			video_mode <= '0';
	  elsif key_videomode'event and key_videomode = '1' then
			video_mode <= not video_mode;
	  end if;
	end process;

   ------------------------------------------------------------
   -- ZPUFLEX : Control module
   ------------------------------------------------------------

  ps2k_dat_in <= dataps2;
  dataps2 <= '0' when ps2k_dat_out='0' else 'Z';
  ps2k_clk_in <= clkps2;
  clkps2 <= '0' when ps2k_clk_out='0' else 'Z';

  ps2k_clk_out <= '1';
  ps2k_dat_out <= '1';

  --Entrada de joystick para control de zpuflex (SACBRLDU) --(SACUDLRB)
  joy2zpuflex <= "0" -- 1 - ZXUNO, 0 - ZXDOS
					& not (joy1(7 downto 0) and joy2(7 downto 0) ) ;
--					& not (joy1_aux(7 downto 5) and joy2_aux(7 downto 5) )
--					& not (joy1_aux(0) and joy2_aux(0) )
--					& not (joy1_aux(1) and joy2_aux(1) )
--					& not (joy1_aux(2) and joy2_aux(2) )
--					& not (joy1_aux(3) and joy2_aux(3) )
--					& not (joy1_aux(4) and joy2_aux(4) ) ;
  joy1 <= "111111" & but_f2_s1 & but_action_s1 & but_right_s1 & but_left_s1 & but_down_s1 & but_up_s1;
  joy2 <= "111111" & but_f2_s0 & but_action_s0 & but_right_s0 & but_left_s0 & but_down_s0 & but_up_s0;
  
  --Block keyboard signals from reaching the host when host_divert_keyboard is high.
  host_ps2_data <= dataps2 or host_divert_keyboard;
  host_ps2_clk <= clkps2 or host_divert_keyboard;

  MyCtrlModule : entity work.CtrlModule
   generic map (
         sysclk_frequency => 425 --708 --430 --500  -- Sysclk frequency * 10 
   )  
	port map (
		--clk => clk_50m_s,
      clk => clk_43m_s,
		reset_n => por_n_s,

		-- Video signals for OSD
		vga_hsync => vga_hsync_i,
		vga_vsync => vga_vsync_i,
		osd_window => osd_window,
		osd_pixel => osd_pixel,
		osd_bkgr  => osd_bkgr,

		-- PS2 keyboard
		ps2k_clk_in => ps2k_clk_in,
		ps2k_dat_in => ps2k_dat_in,
		
		-- SD card signals
		spi_clk => sd_clk,
		spi_mosi => sd_mosi,
		spi_miso => sd_miso,
		spi_cs => sd_cs_n,

		-- DIP switches
		dipswitches(18 downto 17) => dipswt_nc(18 downto 17),
		dipswitches(16 downto 15) => dipswt_nc(16 downto 15),
		dipswitches(14 downto 13) => dipswt_nc(14 downto 13),
		dipswitches(12 downto 11) => dipswt_nc(12 downto 11),
		dipswitches(10 downto 9) => dipswt_nc(10 downto 9),
      dipswitches(8) => loadchr_s,
      dipswitches(7) => joinjoystick_s,
      dipswitches(6 downto 5) => vga2grey,
		dipswitches(4) => is_pal_s,
		dipswitches(3 downto 2) => zxunoboard,
		dipswitches(1) => swapjoystick_s,
		dipswitches(0) => scanlines,
		
		--ROM size
		size => size,
		
		-- JOY Keystrokes
		joykeys => joykeys,
		hard_reset => key_hard_reset,
		video_mode => key_videomode,
		
		-- joystick input
		joy_pins => joy2zpuflex,
				
		-- Control signals
		host_divert_keyboard => host_divert_keyboard,
		host_divert_sdcard => host_divert_sdcard,
		host_reset_n => host_reset_n,
		host_start => host_start,
      host_select => host_select,
		
		-- Boot data upload signals
		host_bootdata => host_bootdata,
		host_bootdata_req => host_bootdata_req,
		host_bootdata_ack => host_bootdata_ack,
      host_bootdata_reset => host_bootdata_reset
      
	);

   overlay : entity work.OSD_Overlay
	port map
	(
		--clk => clk_50m_s,
      clk => clk_43m_s,
		red_in => vga_red_i,
		green_in => vga_green_i,
		blue_in => vga_blue_i,
		window_in => '1',
		osd_window_in => osd_window,
		osd_pixel_in => osd_pixel,
		osd_bkgr_in => osd_bkgr,
		hsync_in => vga_hsync_i,
		red_out => rgb_r_o_prev(9 downto 2),
		green_out => rgb_g_o_prev(9 downto 2),
		blue_out => rgb_b_o_prev(9 downto 2),
		window_out => open,
		scanline_ena => scanlines
	);

  hsync <= vga_hsync_aux;
  vga_hsync_aux <= vga_hsync_i when (video_mode = '0')
					else not (vga_hsync_i xor vga_vsync_i) ;  --!(hs_orig ^ vs_orig)
  vsync <= vga_vsync_i when (video_mode = '0')
					else '1';

  rgb_r_o_prev(1 downto 0) <= rgb_r_o_prev(9 downto 8);
  rgb_g_o_prev(1 downto 0) <= rgb_g_o_prev(9 downto 8);
  rgb_b_o_prev(1 downto 0) <= rgb_b_o_prev(9 downto 8);
  
   ------------------------------------------------------------
   -- VIDEO : Monocrome signal
   ------------------------------------------------------------
	convert_grey: entity work.vga_to_greyscale  
	port map(
     r_in => rgb_r_o_prev,
	  g_in => rgb_g_o_prev,
	  b_in => rgb_b_o_prev,
     y_out => rgb_y_sign
    );

   VGA_R <= rgb_r_o_prev(9 downto 4) when (vga2grey = "00") 
	           else rgb_y_sign (9 downto 4) when (vga2grey = "01") --mono
	           else rgb_y_sign (9 downto 4) when (vga2grey = "11") --orange
				  else (others=>'0'); --green

   VGA_G <= rgb_g_o_prev(9 downto 4) when (vga2grey = "00") 
	           else rgb_y_sign (9 downto 4) when (vga2grey = "01") --mono
	           else ("00" & rgb_y_sign (9 downto 6)) when (vga2grey = "11") --orange
				  else rgb_y_sign (9 downto 4); --green

   VGA_B <= rgb_b_o_prev(9 downto 4) when (vga2grey = "00") 
	           else rgb_y_sign (9 downto 4) when (vga2grey = "01") --mono
	           else ("0000" & rgb_y_sign (9 downto 8)) when (vga2grey = "11") --orange
				  else (others=>'0'); --green

   ------------------------------------------------------------
	-- master reset CTRL+ALT+BACKSPACE
   ------------------------------------------------------------
   multiboot_lx16 : entity work.multiboot
   port map
	(
       clk_icap => clk_vga_en_qn,
       REBOOT => key_hard_reset
   );

end struct;
