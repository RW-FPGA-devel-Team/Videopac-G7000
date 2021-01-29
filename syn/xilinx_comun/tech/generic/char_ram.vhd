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

entity charset_ram is

  generic (
    addr_width_g : integer := 9;
    data_width_g : integer := 8
  );
  port (
    clk_a_i  : in  std_logic;
    we_i     : in  std_logic;
    addr_a_i : in  std_logic_vector(addr_width_g-1 downto 0);
    data_a_i : in  std_logic_vector(data_width_g-1 downto 0);
    data_a_o : out std_logic_vector(data_width_g-1 downto 0)
  );

end charset_ram;


library ieee;
use ieee.numeric_std.all;

architecture rtl of charset_ram is

  type   ram_t          is array (natural range 2**addr_width_g-1 downto 0) of
    std_logic_vector(data_width_g-1 downto 0);
  signal ram_q          : ram_t
    -- pragma translate_off
    --:= (others => (others => '0'))
    := (
    16#7C#,16#C6#,16#C6#,16#C6#,16#C6#,16#C6#,16#7C#,16#00#,
    16#18#,16#38#,16#18#,16#18#,16#18#,16#18#,16#3C#,16#00#,
    16#3C#,16#66#,16#0C#,16#18#,16#30#,16#60#,16#7E#,16#00#,
    16#7C#,16#C6#,16#06#,16#3C#,16#06#,16#C6#,16#7C#,16#00#,
    16#CC#,16#CC#,16#CC#,16#FE#,16#0C#,16#0C#,16#0C#,16#00#,
    16#FE#,16#C0#,16#C0#,16#7C#,16#06#,16#C6#,16#7C#,16#00#,
    16#7C#,16#C6#,16#C0#,16#FC#,16#C6#,16#C6#,16#7C#,16#00#,
    16#FE#,16#06#,16#0C#,16#18#,16#30#,16#60#,16#C0#,16#00#,
    16#7C#,16#C6#,16#C6#,16#7C#,16#C6#,16#C6#,16#7C#,16#00#,
    16#7C#,16#C6#,16#C6#,16#7E#,16#06#,16#C6#,16#7C#,16#00#,
    16#00#,16#18#,16#18#,16#00#,16#18#,16#18#,16#00#,16#00#,
    16#18#,16#7E#,16#58#,16#7E#,16#1A#,16#7E#,16#18#,16#00#,
    16#00#,16#00#,16#00#,16#00#,16#00#,16#00#,16#00#,16#00#,
    16#3C#,16#66#,16#0C#,16#18#,16#18#,16#00#,16#18#,16#00#,
    16#C0#,16#C0#,16#C0#,16#C0#,16#C0#,16#C0#,16#FE#,16#00#,
    16#FC#,16#C6#,16#C6#,16#FC#,16#C0#,16#C0#,16#C0#,16#00#,
    16#00#,16#18#,16#18#,16#7E#,16#18#,16#18#,16#00#,16#00#,
    16#C6#,16#C6#,16#C6#,16#D6#,16#FE#,16#EE#,16#C6#,16#00#,
    16#FE#,16#C0#,16#C0#,16#F8#,16#C0#,16#C0#,16#FE#,16#00#,
    16#FC#,16#C6#,16#C6#,16#FC#,16#D8#,16#CC#,16#C6#,16#00#,
    16#7E#,16#18#,16#18#,16#18#,16#18#,16#18#,16#18#,16#00#,
    16#C6#,16#C6#,16#C6#,16#C6#,16#C6#,16#C6#,16#7C#,16#00#,
    16#3C#,16#18#,16#18#,16#18#,16#18#,16#18#,16#3C#,16#00#,
    16#7C#,16#C6#,16#C6#,16#C6#,16#C6#,16#C6#,16#7C#,16#00#,
    16#7C#,16#C6#,16#C6#,16#C6#,16#DE#,16#CC#,16#76#,16#00#,
    16#7C#,16#C6#,16#C0#,16#7C#,16#06#,16#C6#,16#7C#,16#00#,
    16#FC#,16#C6#,16#C6#,16#C6#,16#C6#,16#C6#,16#FC#,16#00#,
    16#FE#,16#C0#,16#C0#,16#F8#,16#C0#,16#C0#,16#C0#,16#00#,
    16#7C#,16#C6#,16#C0#,16#C0#,16#CE#,16#C6#,16#7E#,16#00#,
    16#C6#,16#C6#,16#C6#,16#FE#,16#C6#,16#C6#,16#C6#,16#00#,
    16#06#,16#06#,16#06#,16#06#,16#06#,16#C6#,16#7C#,16#00#,
    16#C6#,16#CC#,16#D8#,16#F0#,16#D8#,16#CC#,16#C6#,16#00#,
    16#38#,16#6C#,16#C6#,16#C6#,16#FE#,16#C6#,16#C6#,16#00#,
    16#7E#,16#06#,16#0C#,16#18#,16#30#,16#60#,16#7E#,16#00#,
    16#C6#,16#C6#,16#6C#,16#38#,16#6C#,16#C6#,16#C6#,16#00#,
    16#7C#,16#C6#,16#C0#,16#C0#,16#C0#,16#C6#,16#7C#,16#00#,
    16#C6#,16#C6#,16#C6#,16#C6#,16#C6#,16#6C#,16#38#,16#00#,
    16#FC#,16#C6#,16#C6#,16#FC#,16#C6#,16#C6#,16#FC#,16#00#,
    16#C6#,16#EE#,16#FE#,16#D6#,16#C6#,16#C6#,16#C6#,16#00#,
    16#00#,16#00#,16#00#,16#00#,16#00#,16#38#,16#38#,16#00#,
    16#00#,16#00#,16#00#,16#7E#,16#00#,16#00#,16#00#,16#00#,
    16#00#,16#66#,16#3C#,16#18#,16#3C#,16#66#,16#00#,16#00#,
    16#00#,16#18#,16#00#,16#7E#,16#00#,16#18#,16#00#,16#00#,
    16#00#,16#00#,16#7C#,16#00#,16#7C#,16#00#,16#00#,16#00#,
    16#66#,16#66#,16#66#,16#3C#,16#18#,16#18#,16#18#,16#00#,
    16#C6#,16#E6#,16#F6#,16#FE#,16#DE#,16#CE#,16#C6#,16#00#,
    16#03#,16#06#,16#0C#,16#18#,16#30#,16#60#,16#C0#,16#00#,
    16#FF#,16#FF#,16#FF#,16#FF#,16#FF#,16#FF#,16#FF#,16#00#,
    16#CE#,16#DB#,16#DB#,16#DB#,16#DB#,16#DB#,16#CE#,16#00#,
    16#00#,16#00#,16#3C#,16#7E#,16#7E#,16#7E#,16#3C#,16#00#,
    16#1C#,16#1C#,16#18#,16#1E#,16#18#,16#18#,16#1C#,16#00#,
    16#1C#,16#1C#,16#18#,16#1E#,16#18#,16#34#,16#26#,16#00#,
    16#38#,16#38#,16#18#,16#78#,16#18#,16#2C#,16#64#,16#00#,
    16#38#,16#38#,16#18#,16#78#,16#18#,16#18#,16#38#,16#00#,
    16#00#,16#18#,16#0C#,16#FE#,16#0C#,16#18#,16#00#,16#00#,
    16#18#,16#3C#,16#7E#,16#FF#,16#FF#,16#18#,16#18#,16#00#,
    16#03#,16#07#,16#0F#,16#1F#,16#3F#,16#7F#,16#FF#,16#00#,
    16#C0#,16#E0#,16#F0#,16#F8#,16#FC#,16#FE#,16#FF#,16#00#,
    16#38#,16#38#,16#12#,16#FE#,16#B8#,16#28#,16#6C#,16#00#,
    16#C0#,16#60#,16#30#,16#18#,16#0C#,16#06#,16#03#,16#00#,
    16#00#,16#00#,16#0C#,16#08#,16#08#,16#FF#,16#7E#,16#00#,
    16#00#,16#03#,16#63#,16#FF#,16#FF#,16#18#,16#08#,16#00#,
    16#00#,16#00#,16#00#,16#10#,16#38#,16#FF#,16#7E#,16#00#,
    16#00#,16#00#,16#00#,16#06#,16#6E#,16#FF#,16#7E#,16#00#);
    -- pragma translate_on
    ;
  signal read_addr_a_q : unsigned(addr_width_g-1 downto 0);

begin

  mem_a: process (clk_a_i)
  begin
    if clk_a_i'event and clk_a_i = '1' then
      if we_i = '1' then
        ram_q(to_integer(unsigned(addr_a_i))) <= data_a_i;
      end if;

      read_addr_a_q <= unsigned(addr_a_i);
    end if;
  end process mem_a;

  data_a_o <= ram_q(to_integer(read_addr_a_q));

end rtl;
