library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

-- OnScreenDisplay module, generates a character-based display synced with external
-- H and V sync signals.  (Essentially a simple genlock.)
-- Provides a Window and Pixel output, allowing the host to dim the display around
-- the OSD if need be.
-- Registers provided for the following:
--   0 W XPOS
--   1 W YPOS
--   2 W Pixel clock (firmware will guess this from the framing.)
--   3 R hframe - counting how many clocks HSync remains high
--   4 R vframe - ditto, but low.
--   5 W enable - bit 0: OSD enable, bit 1: HSync polarity, bit 2: VSync polarity

-- Also provided, a 512 byte character buffer with its own req signal.


entity OnScreenDisplay is
port(
	reset_n : in std_logic;
	clk : in std_logic;
	-- Video
	hsync_n : in std_logic;
	vsync_n : in std_logic;
	vblank : out std_logic;
	enabled : out std_logic;
	pixel : out std_logic;
   bkgrnd : out std_logic_vector(2 downto 0);
	window : out std_logic;
	-- Registers
	addr : in std_logic_vector(8 downto 0);
	data_in : in std_logic_vector(15 downto 0);
	data_out : out std_logic_vector(15 downto 0);
	reg_wr : in std_logic;
--	reg_req : in std_logic;
--	reg_ack : out std_logic;
--	char_req : in std_logic;
--	char_ack : out std_logic;
	char_wr : in std_logic;
	char_q : out std_logic_vector(7 downto 0)
--	OSDDoubleHeight: in std_logic
);
end entity;

architecture rtl of OnScreenDisplay is

-- Counted in terms of master clocks.
signal hframe : std_logic_vector(15 downto 0);
signal vframe : std_logic_vector(15 downto 0);
signal hcounter : unsigned(15 downto 0);
signal vcounter: unsigned(15 downto 0);

signal hsync_pol : std_logic; -- Polarity
signal vsync_pol : std_logic; -- Polarity
signal hsync_p : std_logic; -- Previous state
signal vsync_p : std_logic; -- Previous state
signal newline : std_logic;
signal newframe : std_logic;

-- Pixel clock generation

signal pixelclock : unsigned(3 downto 0);
signal pixelcounter : unsigned(3 downto 0);
signal pix : std_logic; -- Triggered momentarily at a pixel boundary

-- Pixel-clock-based signals
signal xpixelpos : unsigned(11 downto 0);
signal ypixelpos : unsigned(11 downto 0);
signal ypixelpostmp: unsigned(11 downto 0);

signal hwindowactive : std_logic;
signal vwindowactive : std_logic;
signal hactive : std_logic;
signal vactive : std_logic;
signal rainbowactive : std_logic;
signal pixelaux: std_logic;

-- Registers 
signal xpos : unsigned(15 downto 0);
signal ypos : unsigned(15 downto 0);
signal charram_wr : std_logic;

signal char : std_logic_vector(6 downto 0);
signal charram_rdaddr : std_logic_vector(8 downto 0);
signal charrom_rdaddr : std_logic_vector(12 downto 0);
signal charpixel : std_logic;

signal osd_enable : std_logic;

begin

enabled<=osd_enable;

-- Monitor hsync and count the pulse widths

process(clk,hsync_n)
begin
	if rising_edge(clk) then
		hsync_p<=hsync_n;
--		if pix='1' then
			hcounter<=hcounter+1;
--		end if;

		newline<='0';
		if hsync_n='1' then
			if hsync_p='0' then -- rising edge?
				if vsync_p=vsync_pol and vsync_n/=vsync_pol then
					hframe(15 downto 8)<=std_logic_vector(hcounter(13 downto 6));
				end if;
				hcounter<=(others => '0'); -- Reset counter
				newline<=hsync_pol; -- New line starts here if polarity is reversed
			end if;
		else
			if hsync_p='1' then -- falling edge?
				if vsync_p=vsync_pol and vsync_n/=vsync_pol then
					hframe(7 downto 0)<=std_logic_vector(hcounter(13 downto 6));
				end if;
				hcounter<=(others => '0'); -- Reset counter
				newline<=not hsync_pol; -- New line starts here if polarity is not reversed 
			end if;		
		end if;
	end if;
end process;


-- Monitor newline and count the vsync pulses

process(clk,hsync_n)
begin
	if rising_edge(clk) then
		newframe<='0';
		vblank<='0';
		if newline='1' then
			vsync_p<=vsync_n;
			vcounter<=vcounter+1;
			if vsync_n='1' then
				if vsync_p='0' then -- rising edge?
					vframe(15 downto 8)<=std_logic_vector(vcounter(10 downto 3));
					vcounter<=(others => '0'); -- Reset counter
					newframe<=vsync_pol;
					vblank<=not vsync_pol;
				end if;
			else
				if vsync_p='1' then -- falling edge?
					vframe(7 downto 0)<=std_logic_vector(vcounter(10 downto 3));
					vcounter<=(others => '0'); -- Reset counter
					newframe<=not vsync_pol;
					vblank<=vsync_pol;
				end if;		
			end if;
		end if;
	end if;
end process;


-- Increment pixel counter and generate pixel pulse.

process(clk)
begin
	if rising_edge(clk) then
		if pixelcounter=pixelclock then
			pixelcounter<="0000";
			pix<='1';
		else
			pixelcounter<=pixelcounter+1;
			pix<='0';
		end if;
	end if;
end process;


process(clk,reset_n,addr,data_in,hframe,vframe)
begin

	if reset_n='0' then
		osd_enable<='0';
	elsif rising_edge(clk) then
--		reg_ack<='0';
--		char_ack<='0';

--		if reg_req='1' then
--			reg_ack<='1';
			if reg_wr='1' then -- write
				case addr(7 downto 0) is
					when X"00" =>
						xpos<=unsigned(data_in);
					when X"04" =>
						ypos<=unsigned(data_in);
					when X"08" =>
						pixelclock<=unsigned(data_in(3 downto 0));
					when X"14" =>
						osd_enable<=data_in(0);
						hsync_pol<=data_in(1);
						vsync_pol<=data_in(2);
					when others =>
						null;
				end case;
			end if;
--		end if;

--		if char_req='1' then
--			char_ack<='1';
--		end if;
	end if;

	case addr(7 downto 0) is
		when X"0C" =>
			data_out<=hframe;
		when X"10" =>
			data_out<=vframe;
		when others =>
			data_out<=(others=>'X');
			null;
	end case;

end process;



-- Generate window signal

--ypixelpos <= ypixelpostmp when (OSDDoubleHeight='0') else '0'&ypixelpostmp(11 downto 1);
ypixelpos <= ypixelpostmp;

-- Enable vactive for ypixel positions between 0 and 127, inclusive.
vactive<='1' when ypixelpos(11 downto 7)="00000" else '0';
-- Enable hactive for xpixel positions between 0 and 255, inclusive.
hactive<='1' when xpixelpos(11 downto 8)="0000" else '0';
-- Enable rainbow background for xpixel positions between 192 and 255, inclusive.
rainbowactive <='1' when xpixelpos(11 downto 5)="0000111" else '0';

process(clk,osd_enable,hwindowactive,vwindowactive)
begin

	window<=osd_enable and hwindowactive and vwindowactive;

	if rising_edge(clk) then

		if pix='1' then
			if xpixelpos(11 downto 0)=X"FFB" then -- 4 pixel border
				hwindowactive<='1';
			end if;
			if xpixelpos(11 downto 0)=X"103" then -- 4 pixel border
				hwindowactive<='0';
			end if;
			xpixelpos<=xpixelpos+1;
		end if;
	
		if newline='1' then	-- Reset horizontal counter
			--if ypixelpos(11 downto 0)=X"FFB" then -- 4 pixel border
			if ypixelpostmp(11 downto 0)=X"FFB" then -- 4 pixel border
				vwindowactive<='1';
			end if;
			if ypixelpos(11 downto 0)=X"083" then -- 4 pixel border
				vwindowactive<='0';
			end if;
			
			--Señal VGA exacta
			xpixelpos<=xpos(11 downto 0);
			--Corregir pequeños desalineamientos si la señal VGA no es exacta
			--que se producen cuando la señal original del scandoubler no es compatible
			--completamente con la frecuencia de VGA
--			if ypixelpostmp(0)='1' then
--				xpixelpos<=xpos(11 downto 0) + 1;
--			else
--				xpixelpos<=xpos(11 downto 0) - 1;
--			end if;
			--ypixelpos<=ypixelpos+1;
			ypixelpostmp <= ypixelpostmp+1;
			
		end if;

		if newframe='1' then	-- Reset vertical counter
			--ypixelpos<=ypos(11 downto 0);
			ypixelpostmp<=ypos(11 downto 0);
		end if;

	end if;
end process;



-- Character RAM

charram_rdaddr <= std_logic_vector(ypixelpos(6 downto 3))&std_logic_vector(xpixelpos(7 downto 3));

--charram : entity Work.DualPortRAM_Block
--	port map (
--		clka => clk,
--		clkb => clk,
--		dina => (others => 'X'),
--		dinb => data_in(6 downto 0),
--		addra => charram_rdaddr,
--		addrb => addr(8 downto 0),
--		wea(0) => '0',
--		web(0) => char_wr,
--		douta => char,
--		doutb => char_q(6 downto 0)
--	);
charram : entity Work.DualPortRAM
	port map (
		clock => clk,
		data_a => (others => 'X'),
		data_b => data_in(6 downto 0),
		address_a => charram_rdaddr,
		address_b => addr(8 downto 0),
		wren_a => '0',
		wren_b => char_wr,
		q_a => char,
		q_b => char_q(6 downto 0)
	);



char_q(7)<='0';
	
charrom: entity Work.CharROM_ROM
	generic map
	(
		addrbits => 13
	)
	port map (
	clock => clk,
	address => char(6 downto 0)&std_logic_vector(ypixelpos(2 downto 0))&std_logic_vector(xpixelpos(2 downto 0)),
	q => charpixel
);

--pixel <=charpixel and hactive and vactive;
pixelaux <=charpixel and hactive and vactive;
pixel <= pixelaux;
--bkgrnd(2) <= not pixelaux and ( xpixelpos(5) or not rainbowactive );
--bkgrnd(1) <= not pixelaux and ( xpixelpos(4) or not rainbowactive ) ;
--bkgrnd(0) <= not pixelaux and ( xpixelpos(3) or not rainbowactive ) ;

process(rainbowactive,pixelaux,xpixelpos)
begin
	if rainbowactive='0' then	-- white background
		if pixelaux='1' then
			bkgrnd <= "000"; -- black if pixel
		else
			bkgrnd <= "111"; -- white
		end if;
	else
		if xpixelpos(4 downto 3)= "00" then --red
			bkgrnd <= "100"; -- 
		elsif xpixelpos(4 downto 3)= "01" then --yellow
			bkgrnd <= "110"; -- 		
		elsif xpixelpos(4 downto 3)= "10" then --green
			bkgrnd <= "010"; -- 		
		else --cyan
			bkgrnd <= "011"; -- 				
		end if;
	end if;
end process;


end architecture;
