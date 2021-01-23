library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity io_ps2_out is
port (
  CLK          : in std_logic;
  OSD_ENA      : in std_logic;
  ps2_int      : in std_logic;
  ps2_code     : in std_logic_vector(7 downto 0);
  ps2_key      : out std_logic_vector(10 downto 0)
);
end io_ps2_out;

architecture ps2_out of io_ps2_out is

signal RELEASED : std_logic;
signal EXTENDED : std_logic;
signal STROBE   : std_logic;
begin 

--de mist_io-- ps2_key <= {~ps2_key[10], pressed, extended, ps2_key_raw[7:0]};
-- 10 = fluctua cada pulsacion, 9 - pulsado, 8 - extendendido, [7:0] codigo ps2

process(Clk)
begin
  if rising_edge(Clk) then
	 ps2_key(10) <= ps2_int;
    if ps2_int = '1' and OSD_ENA = '0' then 
			if    ps2_code = x"f0" then RELEASED <= '1'; 
			elsif	ps2_code = x"e0" then EXTENDED <= '1'; 
			else
			 EXTENDED <= '0';
			 RELEASED <= '0'; 
			 ps2_key(9 downto 0) <= not RELEASED & EXTENDED & ps2_code;
			end if;				
	 end if;
  end if;
end process;

end ps2_out;


