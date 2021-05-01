-------------------------------------------------------------------------------
--
-- FPGA Videopac
--
-- $Id: dpram_testrom.vhd,v 1.3 2007/02/10 16:01:20 arnim Exp $
--
-- Generic dual port RAM.
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
use std.textio.all;

entity dpram_testrom is

  generic (
    addr_width_g : integer := 8;
    data_width_g : integer := 8
  );
  port (
    clk_a_i  : in  std_logic;
    we_i     : in  std_logic;
    addr_a_i : in  std_logic_vector(addr_width_g-1 downto 0);
    data_a_i : in  std_logic_vector(data_width_g-1 downto 0);
    data_a_o : out std_logic_vector(data_width_g-1 downto 0);
    clk_b_i  : in  std_logic;
    addr_b_i : in  std_logic_vector(addr_width_g-1 downto 0);
    data_b_o : out std_logic_vector(data_width_g-1 downto 0)
  );

end dpram_testrom;


library ieee;
use ieee.numeric_std.all;

architecture rtl of dpram_testrom is

  type   ram_t          is array (natural range 2**addr_width_g-1 downto 0) of
    std_logic_vector(data_width_g-1 downto 0);
--  signal ram_q          : ram_t
--    -- pragma translate_off
--    := (others => (others => '0'))
--    -- pragma translate_on
--    ;
  signal read_addr_a_q,
         read_addr_b_q  : unsigned(addr_width_g-1 downto 0);

-- Inicializar fichero en memoria
-- El fichero debe tener los datos en texto binario (p.ej. "11010001")
-- Un dato en cada linea
	impure function init_mem(mif_file_name : in string) return ram_t is
		 file mif_file : text open read_mode is mif_file_name;
		 variable mif_line : line;
		 variable temp_bv : bit_vector(data_width_g-1 downto 0);
		 variable temp_mem : ram_t;
	begin
		 for i in ram_t'range loop
			  if(not endfile(mif_file)) then
				  readline(mif_file, mif_line);
				  read(mif_line, temp_bv);
				  temp_mem(i) := to_stdlogicvector(temp_bv); --signed(to_stdlogicvector(temp_bv));
			  else
				  temp_mem(i) := (others=>'1');
			  end if;
		 end loop;
		 return temp_mem;
	end function;

   signal ram_q          : ram_t := init_mem("test_raster_01.mif");


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

  mem_b: process (clk_b_i)
  begin
    if clk_b_i'event and clk_b_i = '1' then
      read_addr_b_q <= unsigned(addr_b_i);
    end if;
  end process mem_b;

  data_a_o <= ram_q(to_integer(read_addr_a_q));
  data_b_o <= ram_q(to_integer(read_addr_b_q));

end rtl;
