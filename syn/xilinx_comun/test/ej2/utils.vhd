-- Hi Emacs, this is -*- mode: vhdl; -*-
----------------------------------------------------------------------------------------------------
-- Utilities Package
--
-- Javier Valcarce García, javier.valcarce@gmail.com
-- $Id$
----------------------------------------------------------------------------------------------------
-- The MIT License
--
-- Copyright (c) 2007 Javier Valcarce García
-- 
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
--
----------------------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;

package utils is

  -- Elimina todos los espacios de una cadena y construye un std_logic_vector
  -- con los elementos restantes, que deben ser '0', '1' o bien '-'
  function STRTRIM(s : string) return std_logic_vector;
  
end utils;

package body utils is

  function STRTRIM(s : string) return std_logic_vector is
    alias sv      : string(1 to s'length) is s;
    variable res  : std_logic_vector(1 to sv'length);
    variable i, j : natural;
    
  begin
    
    j := 0;

    for i in 1 to sv'length loop
      case sv(i) is
        when '0' => j := j + 1; res(j) := '0';
        when '1' => j := j + 1; res(j) := '1';
        when '-' => j := j + 1; res(j) := '-';
        when ' ' => null;
        when others =>
          assert (false) report
            "Utils.STRTRIM: Bad Format" severity failure;
      end case;
    end loop;

    return res(1 to j);
  end function STRTRIM;
 
end utils;
