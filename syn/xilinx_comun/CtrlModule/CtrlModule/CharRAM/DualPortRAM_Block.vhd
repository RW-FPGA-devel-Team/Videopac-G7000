Library UNISIM;
use UNISIM.vcomponents.all;

Library UNIMACRO;
use UNIMACRO.vcomponents.all;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
ENTITY DualPortRAM_Block IS
  PORT (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
    clkb : IN STD_LOGIC;
    web : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addrb : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    dinb : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
  );
END DualPortRAM_Block;

ARCHITECTURE DualPortRAM_Block_a OF DualPortRAM_Block IS
  signal addra_s : std_logic_vector(9 downto 0);
  signal addrb_s : std_logic_vector(9 downto 0);
begin

  addra_s <= "0" & addra;
  addrb_s <= "0" & addrb;
  
   -- BRAM_TDP_MACRO: True Dual Port RAM
   --                 Spartan-6
   -- Xilinx HDL Language Template, version 14.7

   -- Note -  This Unimacro model assumes the port directions to be "downto". 
   --         Simulation of this model with "to" in the port directions could lead to erroneous results.
   
   --------------------------------------------------------------------------
   -- DATA_WIDTH_A/B | BRAM_SIZE | RAM Depth | ADDRA/B Width | WEA/B Width --
   -- ===============|===========|===========|===============|=============--
   --     19-36      |  "18Kb"   |     512   |     9-bit     |    4-bit    --
   --     10-18      |  "18Kb"   |    1024   |    10-bit     |    2-bit    --
   --     10-18      |   "9Kb"   |     512   |     9-bit     |    2-bit    --
   --      5-9       |  "18Kb"   |    2048   |    11-bit     |    1-bit    --
   --      5-9       |   "9Kb"   |    1024   |    10-bit     |    1-bit    --
   --      3-4       |  "18Kb"   |    4096   |    12-bit     |    1-bit    --
   --      3-4       |   "9Kb"   |    2048   |    11-bit     |    1-bit    --
   --        2       |  "18Kb"   |    8192   |    13-bit     |    1-bit    --
   --        2       |   "9Kb"   |    4096   |    12-bit     |    1-bit    --
   --        1       |  "18Kb"   |   16384   |    14-bit     |    1-bit    --
   --        1       |   "9Kb"   |    8192   |    12-bit     |    1-bit    --
   --------------------------------------------------------------------------


   BRAM_TDP_MACRO_inst : BRAM_TDP_MACRO
   generic map (
      BRAM_SIZE => "9Kb", -- Target BRAM, "9Kb" or "18Kb" 
      DEVICE => "SPARTAN6", -- Target Device: "VIRTEX5", "VIRTEX6", "SPARTAN6" 
      DOA_REG => 0, -- Optional port A output register (0 or 1)
      DOB_REG => 0, -- Optional port B output register (0 or 1)
      INIT_A => X"000000000", -- Initial values on A output port
      INIT_B => X"000000000", -- Initial values on B output port
      INIT_FILE => "NONE",
      READ_WIDTH_A => 7,   -- Valid values are 1-36 
      READ_WIDTH_B => 7,   -- Valid values are 1-36
      SIM_COLLISION_CHECK => "ALL", -- Collision check enable "ALL", "WARNING_ONLY", 
                                    -- "GENERATE_X_ONLY" or "NONE" 
      SRVAL_A => X"000000000",   -- Set/Reset value for A port output
      SRVAL_B => X"000000000",   -- Set/Reset value for B port output
      WRITE_MODE_A => "WRITE_FIRST", -- "WRITE_FIRST", "READ_FIRST" or "NO_CHANGE" 
      WRITE_MODE_B => "WRITE_FIRST", -- "WRITE_FIRST", "READ_FIRST" or "NO_CHANGE" 
      WRITE_WIDTH_A => 7, -- Valid values are 1-36
      WRITE_WIDTH_B => 7 )  -- Valid values are 1-36
    port map (
      DOA => douta,       -- Output port-A data
      DOB => doutb,       -- Output port-B data
      ADDRA => addra_s,   -- Input port-A address
      ADDRB => addrb_s,   -- Input port-B address
      CLKA => clka,     -- Input port-A clock
      CLKB => clkb,     -- Input port-B clock
      DIA => dina,       -- Input port-A data
      DIB => dinb,       -- Input port-B data
      ENA => '1',       -- Input port-A enable
      ENB => '1',       -- Input port-B enable
      REGCEA => '1', -- Input port-A output register enable
      REGCEB => '1', -- Input port-B output register enable
      RSTA => '0',     -- Input port-A reset
      RSTB => '0',     -- Input port-B reset
      WEA => wea,       -- Input port-A write enable
      WEB => web        -- Input port-B write enable
   );
   
-- End of BRAM_TDP_MACRO_inst instantiation

END DualPortRAM_Block_a;
