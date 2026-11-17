----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    01:17:54 10/10/2025 
-- Design Name: 
-- Module Name:    SDRAMController - Behavioral 
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

entity SDRAMController is
    Port ( clk   : in  STD_LOGIC;
           Add  : in  STD_LOGIC_VECTOR (15 downto 0);
           Wr  : in  STD_LOGIC; 
           MSTRB : in  STD_LOGIC;  -- Strobe signal for memory access
           Din   : in  STD_LOGIC_VECTOR (7 downto 0);
           Dout  : out  STD_LOGIC_VECTOR (7 downto 0));
end SDRAMController;

architecture Behavioral of SDRAMController is

    -- SDRAM 2D Array of byte-long vectors (8 for index 32 for offset)
    Type SDRAM_Type is Array (7 downto 0, 31 downto 0) of STD_LOGIC_VECTOR (7 downto 0);
    Signal SDRAM : SDRAM_Type;  -- Memory array

    -- Internal signals for block-level operation
	 Signal tag : integer; 
	 Signal index: integer;
	 Signal offset: integer;
	 
	 signal counter: integer := 0;
	 
begin
    -- SDRAM controller process
    process (clk, MSTRB)
    begin
        if rising_edge(clk) then
            if counter = 0 then
					for i in 0 to 7 loop
						for j in 0 to 31 loop
							SDRAM(i,j) <= "00000000";
						end loop;
					end loop;
					counter <= 1;	
				end if;

            if MSTRB = '1' then
					 
                tag <= to_integer(unsigned(Add(15 downto 8)));
					 index <= to_integer(unsigned(Add(7 downto 5)));  
                offset <= to_integer(unsigned(Add(4 downto 0)));  

                if Wr = '1' then
                    -- Write
						  SDRAM(to_integer(unsigned(Add(7 downto 5))), to_integer(unsigned(Add(4 downto 0)))) <= Din;
                else
                    -- Read
                    Dout <= SDRAM(to_integer(unsigned(Add(7 downto 5))), to_integer(unsigned(Add(4 downto 0))));
                end if;
            end if;
        end if;
    end process;

end Behavioral;