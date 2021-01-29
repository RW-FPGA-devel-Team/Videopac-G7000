-- Hi Emacs, this is -*- mode: vhdl -*-
----------------------------------------------------------------------------------
-- Unidirectional PS2 Interface (device -> host)
-- For connect mouse/keyboard
--
-- The PS/2 mouse and keyboard implement a bidirectional synchronous serial 
-- protocol.  The bus is "idle" when both lines are high (open-collector).  
-- THIS A *UNIDIRECTIONAL* INTERFACE (DEVICE -> HOST)
--
-- Javier Valcarce García, javier.valcarce@gmail.com
-- $Id$
----------------------------------------------------------------------------------

library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.utils.all;

entity interface_ps2 is
  port (
    reset   : in  std_logic;
    clk     : in  std_logic;            -- faster than kbclk
    kbdata  : in  std_logic;
    kbclk   : in  std_logic;
    newdata : out std_logic;            -- one clock cycle pulse, notify a new byte has arrived
    do      : out std_logic_vector(7 downto 0)
    );
end interface_ps2;


-------------------------------------------------------------------------------
architecture behavioral of interface_ps2 is
  signal st : std_logic;
  signal sh : std_logic;

  signal s1       : std_logic;
  signal s2       : std_logic;
  signal kbclk_fe : std_logic;

  signal shift9 : std_logic_vector(8 downto 0);
  signal error  : std_logic;
  
begin

-------------------------------------------------------------------------------
-- Edge detector
-------------------------------------------------------------------------------  
  process (reset, clk)
  begin
    if reset = '1' then
      s1 <= '0';
      s2 <= '0';
      
    elsif rising_edge(clk) then
      s2 <= s1;
      s1 <= kbclk;
    end if;
  end process;

  kbclk_fe <= '1' when s1 = '0' and s2 = '1' else '0';

-------------------------------------------------------------------------------
-- 9-bit shift register to store received data 
-- 11-bit frame, LSB first: 1 start bit, 8 data bits, 1 parity bit, 1 stop bit
-------------------------------------------------------------------------------
  process (reset, clk)
  begin
    if reset = '1' then
      shift9 <= "000000000";
    elsif rising_edge(clk) then
      if sh = '1' then
		  shift9(7 downto 0) <= shift9(8 downto 1);
        shift9(8)          <= kbdata;
      end if;
    end if;
    
  end process;

-------------------------------------------------------------------------------
-- Output register
-------------------------------------------------------------------------------
  process (reset, clk)
  begin
  if reset = '1' then
      do <= "00000000";
    elsif rising_edge(clk) then
      if st = '1' then
        do <= shift9(7 downto 0);
      end if;
    end if;

  end process;
  
-------------------------------------------------------------------------------
-- parity error detector (XOR gate) The parity bit is at shift9(8)
------------------------------------------------------------------------------- 
  error <= not (shift9(0) xor shift9(1) xor shift9(2) xor shift9(3) xor shift9(4) xor
           shift9(5) xor shift9(6) xor shift9(7) xor shift9(8));

-------------------------------------------------------------------------------
-- Control Unit
-------------------------------------------------------------------------------
  CTL : block

    type state_type is (idle, start, bit_1a, bit_1b, bit_2a, bit_2b,
                        bit_3a, bit_3b, bit_4a, bit_4b, bit_5a, bit_5b,
                        bit_6a, bit_6b, bit_7a, bit_7b, bit_8a, bit_8b,
                        bit_9a, bit_9b, stop, store, notify);

    signal state : state_type;
    signal op    : std_logic_vector(2 downto 0);
  begin

    -- 2 procesos para separar la parte secuencial de la combinacional, de
    -- esta forma las salidas no son registros ("registered outputs") y por
    -- tanto no hay un ciclo de reloj de espera
    process (reset, clk)
    begin
      if reset = '1' then
        state <= idle;
      elsif rising_edge(clk) then
        case (state) is
          
          when idle =>
            if kbclk_fe = '1' and kbdata = '0' then
              state <= start;  --e0; --DEBUG
            end if;
            
          when start =>
            if kbclk_fe = '1' then
              state <= bit_1a;
            end if;
            
          when bit_1a => state                        <= bit_1b;
          when bit_1b => if kbclk_fe = '1' then state <= bit_2a; end if;
          when bit_2a => state                        <= bit_2b;
          when bit_2b => if kbclk_fe = '1' then state <= bit_3a; end if;
          when bit_3a => state                        <= bit_3b;
          when bit_3b => if kbclk_fe = '1' then state <= bit_4a; end if;
          when bit_4a => state                        <= bit_4b;
          when bit_4b => if kbclk_fe = '1' then state <= bit_5a; end if;
          when bit_5a => state                        <= bit_5b;
          when bit_5b => if kbclk_fe = '1' then state <= bit_6a; end if;
          when bit_6a => state                        <= bit_6b;
          when bit_6b => if kbclk_fe = '1' then state <= bit_7a; end if;
          when bit_7a => state                        <= bit_7b;
          when bit_7b => if kbclk_fe = '1' then state <= bit_8a; end if;
          when bit_8a => state                        <= bit_8b;
          when bit_8b => if kbclk_fe = '1' then state <= bit_9a; end if;
          when bit_9a => state                        <= bit_9b;
          when bit_9b =>
            if kbclk_fe = '1' then
              if kbdata = '1' then
                state <= stop;
              else
                state <= idle;
              end if;
            end if;
          when stop   =>
            if error = '0' then
              state <= store;
            else
              state <= idle;
            end if;
          when store  => state <= notify;
          when notify => state <= idle;
                         
        end case;
      end if;
    end process;

-- 13 uórdenes para la ruta de datos:
-- Agrupamos todas las uórdenes en el vector op para que el código quede más
-- compacto y legible
    sh      <= op(2);
    st      <= op(1);
    newdata <= op(0);                   --out port, actually

    process (state)
    begin
      -- La función TRIM elimina los espacios de la cadena y devuelve un tipo
      -- std_logic_vector con los elementos restantes (definida en work.conf)
      case state is
		                            --SH ST NEW
        when idle   => op <= STRTRIM("0 0 0");
        when start  => op <= STRTRIM("0 0 0");
        when bit_1a => op <= STRTRIM("1 0 0");
        when bit_1b => op <= STRTRIM("0 0 0");
        when bit_2a => op <= STRTRIM("1 0 0");
        when bit_2b => op <= STRTRIM("0 0 0");
        when bit_3a => op <= STRTRIM("1 0 0");
        when bit_3b => op <= STRTRIM("0 0 0");
        when bit_4a => op <= STRTRIM("1 0 0");
        when bit_4b => op <= STRTRIM("0 0 0");
        when bit_5a => op <= STRTRIM("1 0 0");
        when bit_5b => op <= STRTRIM("0 0 0");
        when bit_6a => op <= STRTRIM("1 0 0");
        when bit_6b => op <= STRTRIM("0 0 0");
        when bit_7a => op <= STRTRIM("1 0 0");
        when bit_7b => op <= STRTRIM("0 0 0");
        when bit_8a => op <= STRTRIM("1 0 0");
        when bit_8b => op <= STRTRIM("0 0 0");
        when bit_9a => op <= STRTRIM("1 0 0");
        when bit_9b => op <= STRTRIM("0 0 0");
        when stop   => op <= STRTRIM("0 0 0");
        when store  => op <= STRTRIM("0 1 0");
        when notify => op <= STRTRIM("0 0 1");
                       
      end case;
    end process;
  end block CTL;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
 
end behavioral;

