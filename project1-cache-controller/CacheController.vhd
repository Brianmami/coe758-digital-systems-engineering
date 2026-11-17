----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    19:29:13 10/09/2025 
-- Design Name: 
-- Module Name:    CacheController - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity CacheController is
    Port ( 
			  clk        : in  STD_LOGIC;
			  rst			 : in  STD_LOGIC;
			  Add_in     : in  STD_LOGIC_VECTOR (15 downto 0);
           Wr_in      : in  STD_LOGIC;
           CS         : in  STD_LOGIC;
           Add_out    : out STD_LOGIC_VECTOR (15 downto 0);
           Wr_out     : out STD_LOGIC;
           MSTRB      : out STD_LOGIC;
			  Din_s	    : out STD_LOGIC;
			  Dout_s	    : out STD_LOGIC;
			  Wen        : out STD_LOGIC;
			  Add_Cache  : out STD_LOGIC_VECTOR (7 downto 0);
			  Next_state : out STD_LOGIC_VECTOR (2 downto 0);
			  RDY        : out STD_LOGIC;
			  dBit		 : out STD_LOGIC
	);
end CacheController;

architecture Behavioral of CacheController is
	signal tag   : STD_LOGIC_VECTOR (7 downto 0);
	signal index : STD_LOGIC_VECTOR (2 downto 0);
	signal offset : STD_LOGIC_VECTOR (4 downto 0);
	
	type   tag_memory_type is Array (7 downto 0) of STD_LOGIC_VECTOR (7 downto 0); 
	type   vd_memory_type  is Array (7 downto 0) of STD_LOGIC;
	
	signal tag_memory : tag_memory_type := (others => (others => '0'));
	signal dirtyBits  : vd_memory_type  := (others => '0');
	signal validBits  : vd_memory_type  := (others => '0');
	
	-- signal state    : STD_LOGIC_VECTOR (2 downto 0) := "000";
	signal cacheHit : STD_LOGIC;
	signal dirtyBit : STD_LOGIC;
	signal validBit : STD_LOGIC;
	
	type   state_type is (IDLE, CHECK_TAG, CACHE_HIT_RD, CACHE_HIT_WR, CACHE_MISS_C, CACHE_MISS_D);
	signal current_state : state_type := IDLE;
	
	signal counter : integer := 0;
	signal i       : integer := 0;
	signal cs_prev : STD_LOGIC := '0';
	
	signal RDY_internal : STD_LOGIC := '0';
	
begin

	RDY <= RDY_internal;

	process(Add_in)
	begin
		tag   <= Add_in(15 downto 8);
		index <= Add_in(7 downto 5);
		offset <= Add_in(4 downto 0);
	end process;
	
	--FSM
	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				 -- Reset all state
				 current_state <= IDLE;
				 RDY_internal <= '0';
				 counter <= 0;
				 i <= 0;
				 cs_prev <= '0';
				 Wr_out <= '0';
				 Wen <= '0';
				 MSTRB <= '0';
				 Din_s <= '0';
				 Dout_s <= '0';
			else
				 cs_prev <= CS;
			
				case current_state is
					when IDLE => -- 0
						RDY_internal <= '1';
						Wr_out 		 <= '0';
						Wen    		 <= '0';
						-- Selecting the Cache Controller to be used (moving to next state)
						if CS = '1' and cs_prev = '0' then
							current_state <= CHECK_TAG;
						end if;
					
					when CHECK_TAG => -- 1
						RDY_internal <= '0';
						-- Checking if v-bit at index in validBits array = 1 (validating)
						if (validBits(to_integer(unsigned(index))) = '1') and
							-- Checking if tag in tag_memory array is the same as CPU bus tag
							(tag_memory(to_integer(unsigned(index))) = tag) then
							cacheHit <= '1';
							dirtyBit <= dirtyBits(to_integer(unsigned(index)));
							validBit <= validBits(to_integer(unsigned(index)));
							dBit <= dirtyBit;
							
							if Wr_in = '1' then
								current_state <= CACHE_HIT_WR;
							else
								current_state <= CACHE_HIT_RD;
							end if;
						else
							cacheHit <= '0';
							dirtyBit <= dirtyBits(to_integer(unsigned(index)));
							dBit <= dirtyBit;
							-- Check to see if block can be replaced or not (clean or dirty)
							if (dirtyBits(to_integer(unsigned(index))) = '0') then
								current_state <= CACHE_MISS_C;
							else
								current_state <= CACHE_MISS_D;
							end if;
						end if;
					
					when CACHE_HIT_RD => -- 2
						RDY_internal <= '0';
						Add_Cache <= index & offset;
						Wr_out <= '0';
						Din_s <= '0';
						Dout_s <= '1';
						WEN <= '0';
						current_state <= IDLE;
					
					when CACHE_HIT_WR => -- 3
						RDY_internal <= '0';
						Add_Cache <= index & offset;
						Wr_out <= '0';
						Wen <= '1';
						dirtyBits(to_integer(unsigned(index))) <= '1';
						validBits(to_integer(unsigned(index))) <= '1';
						Din_s <= '0';
						Dout_s <= '0';
						current_state <= IDLE;
					
					when CACHE_MISS_C => -- 4
						RDY_internal <= '0';
						Din_s  <= '1';
						Dout_s <= '0';

						if (counter = 64) then
							counter <= 0;
							i <= 0;
							tag_memory(to_integer(unsigned(index))) <= tag;
							validBits(to_integer(unsigned(index))) <= '1';
							current_state <= IDLE;
							
						else
							if (counter mod 2 = 0) then
								MSTRB <= '0';
							else
								Add_out <= tag & index & STD_LOGIC_VECTOR(to_unsigned(i, 5));
								Add_cache <= index & STD_LOGIC_VECTOR(to_unsigned(i, 5));
								Wen <= '1';
								Wr_out <= '0';
								MSTRB <= '1';
								i <= i + 1;
							end if;
							counter <= counter + 1;
						end if;
									
					when CACHE_MISS_D => -- 5
						RDY_internal <= '0';
						Din_s <= '0';
						Dout_s <= '1';
									
						if (counter = 64) then
							counter <= 0;
							i <= 0;
							dirtyBits(to_integer(unsigned(index))) <= '0'; -- Reset dirty bit
										
							current_state <= CACHE_MISS_C;

						else
							if (counter mod 2 = 0) then
								MSTRB <= '0';
							else
								Add_out <= tag_memory(to_integer(unsigned(index))) & index & STD_LOGIC_VECTOR(to_unsigned(i, 5));
								Add_cache <= index & STD_LOGIC_VECTOR(to_unsigned(i, 5));
								Wr_out <= '1'; -- write to SDRAM
								Wen <= '0'; -- read SRAM
								MSTRB <= '1';
								i <= i + 1;
							end if;
							counter <= counter + 1;
						end if;		
				end case;
			end if;
		end if;
    end process;
	 
	 process(current_state)
	 begin
		case current_state is
			when IDLE =>
				Next_state <= "000";
			when CHECK_TAG =>
				Next_state <= "001";
			when CACHE_HIT_RD =>
				Next_state <= "010";
			when CACHE_HIT_WR =>
				Next_state <= "011";
			when CACHE_MISS_C =>
				Next_state <= "100";
			when CACHE_MISS_D =>
				Next_state <= "101";
		end case;
	 end process;

    
end Behavioral;

