-- Hi Emacs, this is -*- mode: vhdl -*-
----------------------------------------------------------------------------------
-- TEST BENCH
-- Unidirectional PS2 Interface (device -> host)
-- For connect mouse/keyboard
--
-- Javier Valcarce García, javier.valcarce@gmail.com
-- $Id$
----------------------------------------------------------------------------------

library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.utils.all;

entity interface_ps2_test is
end interface_ps2_test;

-------------------------------------------------------------------------------
architecture behavioral of interface_ps2_test is

  component interface_ps2
    port (
      reset   : in  std_logic;
      clk     : in  std_logic;          -- faster than kbclk
      kbdata  : in  std_logic;
      kbclk   : in  std_logic;
      newdata : out std_logic;          -- one system clock cycle pulse when a new byte has arrived
      do      : out std_logic_vector(7 downto 0)
      );
  end component;

  signal reset   : std_logic;
  signal clk     : std_logic;
  signal kbdata  : std_logic;
  signal kbclk   : std_logic;
  signal newdata : std_logic;
  signal do      : std_logic_vector(7 downto 0);


-- test internal signals
  signal kbclk_en : std_logic;

begin
  
  UUT : interface_ps2 port map (
    reset   => reset,
    clk     => clk,
    kbdata  => kbdata,
    kbclk   => kbclk,
    newdata => newdata,
    do      => do
    );   

  -- System clock: period 2.4 ns (~380MHz) = 10 * keyboard clock 
  process
  begin
    clk <= '0';
    wait for 1 ns;
    clk <= '1';
    wait for 1 ns;
  end process;

  -- Keyboard clock: 4 times slower than system clock
  process (kbclk_en, clk)
    variable c : integer;
  begin
    if kbclk_en = '0' then
      kbclk <= '1';
      c     := 3;
    elsif rising_edge(clk) then
      c := (c + 1) mod 4;
      if c = 0 then
        kbclk <= not kbclk;
      end if;
    end if;
  end process;


  process
  begin
    reset    <= '1';
    kbdata   <= '1';
    kbclk_en <= '0';

    wait for 4 ns;
    reset <= '0';
    wait for 4 ns;

    -- bit start
    kbdata   <= '0'; wait for 6 ns;
    kbclk_en <= '1'; wait for 8 ns;

    -- 8 data bits (LSB first)            
    kbdata <= '1'; wait for 16 ns;
    kbdata <= '1'; wait for 16 ns;
    kbdata <= '1'; wait for 16 ns;
    kbdata <= '1'; wait for 16 ns;
    kbdata <= '0'; wait for 16 ns;
    kbdata <= '0'; wait for 16 ns;
    kbdata <= '0'; wait for 16 ns;
    kbdata <= '0'; wait for 16 ns;
    -- parity bit
    kbdata <= '1'; wait for 16 ns;
    -- stop bit
    kbdata <= '1'; wait for 16 ns;

    kbclk_en <= '0';
    wait for 20 ns;
  end process;


end behavioral;
