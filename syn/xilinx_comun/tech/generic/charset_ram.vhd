-------------------------------------------------------------------------------
--
-- FPGA Videopac
--
-- $Id: charset_ram.vhd,v 1.0 2021/01/17 avlixa Exp $
--
-- Dual port RAM for use as a configurable char rom.
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

library ieee;
use ieee.std_logic_1164.all;
Library UNISIM;
use UNISIM.vcomponents.all;

Library UNIMACRO;
use UNIMACRO.vcomponents.all;

entity charset_ram is

--  generic (
--    addr_width_g : integer := 9;
--    data_width_g : integer := 8
--  );
  port (
    clk_a_i  : in  std_logic;
    we_i     : in  std_logic;
    rd_i     : in  std_logic;
    addr_a_i : in  std_logic_vector(8 downto 0);
    data_a_i : in  std_logic_vector(7 downto 0);
    data_a_o : out std_logic_vector(7 downto 0)
  );

end charset_ram;


library ieee;
use ieee.numeric_std.all;

architecture rtl of charset_ram is
--  type   ram_t          is array (natural range 2**addr_width_g-1 downto 0) of
--    std_logic_vector(data_width_g-1 downto 0);
--  signal ram_q          : ram_t
--    -- pragma translate_off
--    --:= (others => (others => '0'))
--    := ( )
--    -- pragma translate_on
--    ;
--    
    signal read_addr_a_q  :  std_logic_vector(9 downto 0);
    signal mem_addr_a_q   :  std_logic_vector(9 downto 0);
    signal we_s: std_logic_vector(0 downto 0);
begin

  mem_a: process (clk_a_i)
  begin
    if clk_a_i'event and clk_a_i = '1' then
--      if we_i = '1' then
--        ram_q(to_integer(unsigned(addr_a_i))) <= data_a_i;
--      end if;
--
--
      if rd_i = '1'  then
         read_addr_a_q <= '0' & addr_a_i;
      end if;
    end if;
  end process mem_a;
--
--  data_a_o <= ram_q(to_integer(read_addr_a_q));


   -- BRAM_SINGLE_MACRO: Single Port RAM
   --                    Spartan-6
   -- Xilinx HDL Language Template, version 14.7

   -- Note -  This Unimacro model assumes the port directions to be "downto". 
   --         Simulation of this model with "to" in the port directions could lead to erroneous results.
  
   ---------------------------------------------------------------------
   --  READ_WIDTH | BRAM_SIZE | READ Depth  | ADDR Width |            --
   -- WRITE_WIDTH |           | WRITE Depth |            |  WE Width  --
   -- ============|===========|=============|============|============--
   --    19-36    |  "18Kb"   |      512    |    9-bit   |    4-bit   --
   --    10-18    |  "18Kb"   |     1024    |   10-bit   |    2-bit   --
   --    10-18    |   "9Kb"   |      512    |    9-bit   |    2-bit   --
   --     5-9     |  "18Kb"   |     2048    |   11-bit   |    1-bit   --
   --     5-9     |   "9Kb"   |     1024    |   10-bit   |    1-bit   --
   --     3-4     |  "18Kb"   |     4096    |   12-bit   |    1-bit   --
   --     3-4     |   "9Kb"   |     2048    |   11-bit   |    1-bit   --
   --       2     |  "18Kb"   |     8192    |   13-bit   |    1-bit   --
   --       2     |   "9Kb"   |     4096    |   12-bit   |    1-bit   --
   --       1     |  "18Kb"   |    16384    |   14-bit   |    1-bit   --
   --       1     |   "9Kb"   |     8192    |   13-bit   |    1-bit   --
   ---------------------------------------------------------------------

 
   BRAM_SINGLE_MACRO_inst : BRAM_SINGLE_MACRO
   generic map (
      BRAM_SIZE => "9Kb", -- Target BRAM, "9Kb" or "18Kb" 
      DEVICE => "SPARTAN6", -- Target Device: "VIRTEX5", "VIRTEX6", "SPARTAN6" 
      DO_REG => 0, -- Optional output register (0 or 1)
      INIT => X"000000000",   --  Initial values on output port
      INIT_FILE => "NONE",
      WRITE_WIDTH => 8,   -- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="18Kb")
      READ_WIDTH => 8,   -- Valid values are 1-36 (19-36 only valid when BRAM_SIZE="18Kb")
      SRVAL => X"000000000",   -- Set/Reset value for port output
      WRITE_MODE => "WRITE_FIRST", -- "WRITE_FIRST", "READ_FIRST" or "NO_CHANGE" 
      -- The following INIT_xx declarations specify the initial contents of the RAM
      INIT_00 => X"007CC6063C06C67C007E6030180C663C003C181818183818007CC6C6C6C6C67C",
      INIT_01 => X"00C06030180C06FE007CC6C6FCC0C67C007CC6067CC0C0FE000C0C0CFECCCCCC",
      INIT_02 => X"00187E1A7E587E180000181800181800007CC6067EC6C67C007CC6C67CC6C67C",
      INIT_03 => X"00C0C0C0FCC6C6FC00FEC0C0C0C0C0C000180018180C663C0000000000000000",
      INIT_04 => X"00C6CCD8FCC6C6FC00FEC0C0F8C0C0FE00C6EEFED6C6C6C6000018187E181800",
      INIT_05 => X"007CC6C6C6C6C67C003C18181818183C007CC6C6C6C6C6C6001818181818187E",
      INIT_06 => X"00C0C0C0F8C0C0FE00FCC6C6C6C6C6FC007CC6067CC0C67C0076CCDEC6C6C67C",
      INIT_07 => X"00C6CCD8F0D8CCC6007CC6060606060600C6C6C6FEC6C6C6007EC6CEC0C0C67C",
      INIT_08 => X"007CC6C0C0C0C67C00C6C66C386CC6C6007E6030180C067E00C6C6FEC6C66C38",
      INIT_09 => X"003838000000000000C6C6C6D6FEEEC600FCC6C6FCC6C6FC00386CC6C6C6C6C6",
      INIT_0A => X"0000007C007C0000000018007E0018000000663C183C6600000000007E000000",
      INIT_0B => X"00FFFFFFFFFFFFFF00C06030180C060300C6CEDEFEF6E6C6001818183C666666",
      INIT_0C => X"002634181E181C1C001C18181E181C1C003C7E7E7E3C000000CEDBDBDBDBDBCE",
      INIT_0D => X"001818FFFF7E3C180000180CFE0C1800003818187818383800642C1878183838",
      INIT_0E => X"0003060C183060C0006C28B8FE12383800FFFEFCF8F0E0C000FF7F3F1F0F0703",
      INIT_0F => X"007EFF6E06000000007EFF3810000000000818FFFF630300007EFF08080C0000",
      INIT_10 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_11 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_12 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_13 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_14 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_15 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_16 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_17 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_18 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_19 => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_1A => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_1B => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_1C => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_1D => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_1E => X"0000000000000000000000000000000000000000000000000000000000000000",
      INIT_1F => X"0000000000000000000000000000000000000000000000000000000000000000") --,

--      -- The next set of INIT_xx are for "18Kb" configuration only
--      INIT_20 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_21 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_22 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_23 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_24 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_25 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_26 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_27 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_28 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_29 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_2A => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_2B => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_2C => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_2D => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_2E => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_2F => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_30 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_31 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_32 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_33 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_34 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_35 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_36 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_37 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_38 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_39 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_3A => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_3B => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_3C => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_3D => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_3E => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INIT_3F => X"0000000000000000000000000000000000000000000000000000000000000000",
         
--      -- The next set of INITP_xx are for the parity bits
--      INITP_00 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INITP_01 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INITP_02 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INITP_03 => X"0000000000000000000000000000000000000000000000000000000000000000",

--      -- The next set of INITP_xx are for "18Kb" configuration only
--      INITP_04 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INITP_05 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INITP_06 => X"0000000000000000000000000000000000000000000000000000000000000000",
--      INITP_07 => X"0000000000000000000000000000000000000000000000000000000000000000")


    port map (
      DO => data_a_o,   -- Output data, width defined by READ_WIDTH parameter
      ADDR => mem_addr_a_q, -- Input address, width defined by read/write port depth
      CLK => clk_a_i,   -- 1-bit input clock
      DI => data_a_i,   -- Input data port, width defined by WRITE_WIDTH parameter
      EN => '1',        -- 1-bit input RAM enable
      REGCE => '0',     -- 1-bit input output register enable
      RST => '0',       -- 1-bit input reset
      WE => we_s(0 downto 0)        -- Input write enable, width defined by write port depth
   );
   
   mem_addr_a_q <= ('0' & addr_a_i) when (we_i = '1') else read_addr_a_q;
   -- End of BRAM_SINGLE_MACRO_inst instantiation

   we_s(0) <= we_i;

end rtl;
